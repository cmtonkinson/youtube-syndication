#!/usr/bin/env bash

set -u
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib/logging.sh
source "${ROOT_DIR}/lib/logging.sh"
# shellcheck source=lib/config.sh
source "${ROOT_DIR}/lib/config.sh"
# shellcheck source=lib/state_store.sh
source "${ROOT_DIR}/lib/state_store.sh"

# Load yts.sh functions without running main or sourcing other files.
source <(sed \
  -e '/^set -u$/d' \
  -e '/^SCRIPT_DIR=/d' \
  -e '/^# shellcheck source=/d' \
  -e '/^source "/d' \
  -e '/^main "\$@"/,$d' \
  "${ROOT_DIR}/yts.sh")

# Override awk-dependent helpers for test portability.
state_store_read_records() {
  local file="$1"

  if [[ ! -s "${file}" ]]; then
    return 0
  fi

  python3 - "${file}" <<'PY'
import json, sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as fh:
    payload = json.load(fh)

for record in payload.get("records", []):
    fields = [
        record.get("id", ""),
        record.get("published_at", ""),
        record.get("status", ""),
        record.get("video_path", ""),
        record.get("thumbnail_path", ""),
    ]
    print("\t".join(fields))
PY
}

state_store_get_status() {
  local file="$1"
  local lookup_id="$2"

  local status
  status="$(python3 - "${file}" "${lookup_id}" <<'PY'
import json, sys

path = sys.argv[1]
lookup = sys.argv[2]
try:
    with open(path, "r", encoding="utf-8") as fh:
        payload = json.load(fh)
except FileNotFoundError:
    sys.exit(1)

for record in payload.get("records", []):
    if record.get("id") == lookup:
        print(record.get("status", ""))
        sys.exit(0)
sys.exit(1)
PY
)" || return 1

  printf '%s' "${status}"
}

failures=0
TEMP_DIRS=()

cleanup_temp_dirs() {
  local dir
  for dir in "${TEMP_DIRS[@]}"; do
    rm -rf "${dir}"
  done
}

trap cleanup_temp_dirs EXIT

fail() {
  local msg="$1"
  printf 'not ok - %s\n' "${msg}"
  return 1
}

pass() {
  local msg="$1"
  printf 'ok - %s\n' "${msg}"
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local msg="$3"
  if [[ "${expected}" != "${actual}" ]]; then
    printf 'not ok - %s (expected=%s actual=%s)\n' "${msg}" "${expected}" "${actual}"
    return 1
  fi
}

assert_file_exists() {
  local path="$1"
  local msg="$2"
  if [[ ! -f "${path}" ]]; then
    fail "${msg}"
    return 1
  fi
}

run_test() {
  local name="$1"
  local fn="$2"
  if "${fn}"; then
    pass "${name}"
  else
    failures=$((failures + 1))
  fi
}

make_temp_dir() {
  local dir
  dir="$(mktemp -d "${ROOT_DIR}/tests/tmp.XXXXXX")"
  TEMP_DIRS+=("${dir}")
  printf '%s' "${dir}"
}

make_stub_yt_dlp() {
  local dir="$1"
  cat > "${dir}/yt-dlp" <<'EOF'
#!/usr/bin/env bash
set -u
if [[ -n "${YTS_TEST_YTDLP_OUTPUT_FILE:-}" ]]; then
  cat "${YTS_TEST_YTDLP_OUTPUT_FILE}"
  exit 0
fi
exit 0
EOF
  chmod +x "${dir}/yt-dlp"
}

test_subscriptions_and_defaults() {
  local temp_dir
  temp_dir="$(make_temp_dir)"

  SUBSCRIPTIONS_PATH="${temp_dir}/subscriptions.txt"
  cat > "${SUBSCRIPTIONS_PATH}" <<'EOF'

  # Comment line
  https://www.youtube.com/@ExampleOne
  https://www.youtube.com/playlist?list=PL123

EOF

  load_subscriptions || return 1
  assert_eq "2" "${#SUBSCRIPTIONS[@]}" "subscriptions count" || return 1
  assert_eq "https://www.youtube.com/@ExampleOne" "${SUBSCRIPTIONS[0]}" "subscription[0]" || return 1
  assert_eq "https://www.youtube.com/playlist?list=PL123" "${SUBSCRIPTIONS[1]}" "subscription[1]" || return 1

  CONFIG_PATH="${temp_dir}/yts.conf"
  load_config || return 1
  assert_eq "true" "${SKIP_SHORTS}" "default skip shorts" || return 1
  assert_eq "true" "${SKIP_LIVESTREAMS}" "default skip livestreams" || return 1
  assert_eq "0" "${MAX_SIZE_MB}" "default max size" || return 1
  assert_eq "0" "${MAX_DURATION_MIN}" "default max duration" || return 1
  assert_eq "" "${TITLE_SKIP_REGEX}" "default title regex" || return 1
}

test_filtering_rules() {
  local temp_dir
  temp_dir="$(make_temp_dir)"

  local stub_dir="${temp_dir}/stub"
  mkdir -p "${stub_dir}"
  make_stub_yt_dlp "${stub_dir}"

  local listing="${temp_dir}/listing.txt"
  local sep=$'\x1f'
  cat > "${listing}" <<EOF
vid_short${sep}Short Video${sep}20240101${sep}NA${sep}30${sep}1000${sep}not_live${sep}false${sep}false
vid_live${sep}Live Stream${sep}20240101${sep}NA${sep}120${sep}1000${sep}live${sep}true${sep}false
vid_big${sep}Big Video${sep}20240101${sep}NA${sep}120${sep}3000000${sep}not_live${sep}false${sep}false
vid_long${sep}Long Video${sep}20240101${sep}NA${sep}400${sep}1000${sep}not_live${sep}false${sep}false
vid_skip${sep}Skip This${sep}20240101${sep}NA${sep}120${sep}1000${sep}not_live${sep}false${sep}false
vid_ok${sep}Normal Video${sep}20240102${sep}NA${sep}120${sep}1000${sep}not_live${sep}false${sep}false
EOF

  PATH="${stub_dir}:${PATH}"
  export YTS_TEST_YTDLP_OUTPUT_FILE="${listing}"

  init_run_logging "filtering"
  SUBSCRIPTIONS=("https://example.com/channel")
  STATE_DIR="${temp_dir}/state"
  SKIP_SHORTS="true"
  SKIP_LIVESTREAMS="true"
  MAX_SIZE_MB="1"
  MAX_DURATION_MIN="5"
  TITLE_SKIP_REGEX="Skip"

  sync_stage || return 1

  local state_file="${STATE_DIR}/https___example.com_channel.json"
  local ids
  ids="$(python3 - "${state_file}" <<'PY'
import json, sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as fh:
    payload = json.load(fh)

for record in payload.get("records", []):
    print(record.get("id", ""))
PY
)"
  if ! printf '%s\n' "${ids}" | grep -q "^vid_ok$"; then
    fail "expected vid_ok to remain after filtering"
    return 1
  fi
  if printf '%s\n' "${ids}" | grep -q "^vid_short$"; then
    fail "expected shorts to be filtered"
    return 1
  fi
  if printf '%s\n' "${ids}" | grep -q "^vid_live$"; then
    fail "expected livestreams to be filtered"
    return 1
  fi
  if printf '%s\n' "${ids}" | grep -q "^vid_big$"; then
    fail "expected size-limited videos to be filtered"
    return 1
  fi
  if printf '%s\n' "${ids}" | grep -q "^vid_long$"; then
    fail "expected duration-limited videos to be filtered"
    return 1
  fi
  if printf '%s\n' "${ids}" | grep -q "^vid_skip$"; then
    fail "expected title pattern matches to be filtered"
    return 1
  fi
}

test_publish_order_and_episode_numbers() {
  local temp_dir
  temp_dir="$(make_temp_dir)"

  local stub_dir="${temp_dir}/stub"
  mkdir -p "${stub_dir}"
  make_stub_yt_dlp "${stub_dir}"

  local listing="${temp_dir}/listing.txt"
  local sep=$'\x1f'
  cat > "${listing}" <<EOF
vid_c${sep}Third Video${sep}20240103${sep}NA${sep}120${sep}1000${sep}not_live${sep}false${sep}false
vid_a${sep}First Video${sep}20240101${sep}NA${sep}120${sep}1000${sep}not_live${sep}false${sep}false
vid_b${sep}Second Video${sep}20240102${sep}NA${sep}120${sep}1000${sep}not_live${sep}false${sep}false
EOF

  PATH="${stub_dir}:${PATH}"
  export YTS_TEST_YTDLP_OUTPUT_FILE="${listing}"

  init_run_logging "ordering"
  SUBSCRIPTIONS=("https://example.com/playlist")
  STATE_DIR="${temp_dir}/state"
  SKIP_SHORTS="false"
  SKIP_LIVESTREAMS="false"
  MAX_SIZE_MB="0"
  MAX_DURATION_MIN="0"
  TITLE_SKIP_REGEX=""

  sync_stage || return 1

  local metadata_file="${STATE_DIR}/https___example.com_playlist.metadata.json"
  assert_file_exists "${metadata_file}" "metadata file exists" || return 1

  local episode_map
  episode_map="$(python3 - "${metadata_file}" <<'PY'
import json, sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as fh:
    payload = json.load(fh)

for record in payload.get("records", []):
    print(f"{record.get('id','')}\t{record.get('episode','')}")
PY
)"

  local ep_a
  ep_a="$(printf '%s\n' "${episode_map}" | sed -n 's/^vid_a\t//p')"
  local ep_b
  ep_b="$(printf '%s\n' "${episode_map}" | sed -n 's/^vid_b\t//p')"
  local ep_c
  ep_c="$(printf '%s\n' "${episode_map}" | sed -n 's/^vid_c\t//p')"

  assert_eq "1" "${ep_a}" "episode number for earliest publish date" || return 1
  assert_eq "2" "${ep_b}" "episode number for middle publish date" || return 1
  assert_eq "3" "${ep_c}" "episode number for latest publish date" || return 1
}

test_filename_sanitization_and_import_naming() {
  local temp_dir
  temp_dir="$(make_temp_dir)"

  local sanitized
  sanitized="$(sanitize_component "  Weird/Name:Here  ")"
  assert_eq "Weird-Name-Here" "${sanitized}" "sanitize_component replaces separators" || return 1

  local base_name
  base_name="$(sanitize_component "My Channel - S01E01 - Title/With:Chars")"
  assert_eq "My Channel - S01E01 - Title-With-Chars" "${base_name}" "naming convention sanitation" || return 1

  local dest_dir="${temp_dir}/library"
  mkdir -p "${dest_dir}"
  touch "${dest_dir}/${base_name}.mp4"

  local resolved
  resolved="$(resolve_unique_basename "${dest_dir}" "${base_name}" "vid123" "mp4")"
  assert_eq "${base_name} (vid123)" "${resolved}" "collision naming fallback" || return 1
}

test_state_store_read_write() {
  local temp_dir
  temp_dir="$(make_temp_dir)"

  local store="${temp_dir}/state.json"
  state_store_init_file "${store}" || return 1

  state_store_upsert_record "${store}" "vid1" "20240101" "pending" "" "" || return 1
  state_store_upsert_record "${store}" "vid2" "20240102" "processed" "/tmp/video.mp4" "/tmp/video.jpg" || return 1
  state_store_upsert_record "${store}" "vid1" "20240101" "downloaded" "" "" || return 1

  local status_vid1
  status_vid1="$(python3 - "${store}" <<'PY'
import json, sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as fh:
    payload = json.load(fh)

records = {rec.get("id"): rec for rec in payload.get("records", [])}
print(records.get("vid1", {}).get("status", ""))
PY
)"
  assert_eq "downloaded" "${status_vid1}" "state store update overwrites status" || return 1

  local status_vid2
  status_vid2="$(python3 - "${store}" <<'PY'
import json, sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as fh:
    payload = json.load(fh)

records = {rec.get("id"): rec for rec in payload.get("records", [])}
print(records.get("vid2", {}).get("status", ""))
PY
)"
  assert_eq "processed" "${status_vid2}" "state store read for processed status" || return 1
}

run_test "subscriptions parsing and config defaults" test_subscriptions_and_defaults
run_test "filtering rules" test_filtering_rules
run_test "publish order and episode numbering" test_publish_order_and_episode_numbers
run_test "filename sanitization and import naming" test_filename_sanitization_and_import_naming
run_test "state store read/write" test_state_store_read_write

if [[ "${failures}" -gt 0 ]]; then
  printf '\n%d test(s) failed.\n' "${failures}"
  exit 1
fi

printf '\nAll tests passed.\n'
