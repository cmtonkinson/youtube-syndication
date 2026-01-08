#!/usr/bin/env bash

# JSON state store for per-video status tracking.
# Format:
# {
#   "version": 1,
#   "records": [
#     {"id":"...","published_at":"...","status":"..."}
#   ]
# }

state_store_json_escape() {
  local value="$1"

  printf '%s' "$value" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

state_store_tmp_path() {
  local file="$1"
  local dir
  local base

  dir="$(dirname "$file")"
  base="$(basename "$file")"

  printf '%s/.%s.tmp.%s' "$dir" "$base" "$$"
}

state_store_read_records() {
  local file="$1"

  if [[ ! -s "$file" ]]; then
    return 0
  fi

  awk '
    match($0, /"id"[[:space:]]*:[[:space:]]*"([^"]*)"/, id_match) {
      id = id_match[1]
      published = ""
      status = ""
      if (match($0, /"published_at"[[:space:]]*:[[:space:]]*"([^"]*)"/, pub_match)) {
        published = pub_match[1]
      }
      if (match($0, /"status"[[:space:]]*:[[:space:]]*"([^"]*)"/, status_match)) {
        status = status_match[1]
      }
      if (id != "") {
        print id "\t" published "\t" status
      }
    }
  ' "$file"
}

state_store_emit_record() {
  local id="$1"
  local published_at="$2"
  local status="$3"
  local safe_id
  local safe_published
  local safe_status

  safe_id="$(state_store_json_escape "$id")"
  safe_published="$(state_store_json_escape "$published_at")"
  safe_status="$(state_store_json_escape "$status")"

  printf '    {"id":"%s","published_at":"%s","status":"%s"}' \
    "$safe_id" "$safe_published" "$safe_status"
}

state_store_init_file() {
  local file="$1"
  local dir
  local tmp

  dir="$(dirname "$file")"
  mkdir -p "$dir" || return 1

  if [[ -s "$file" ]]; then
    return 0
  fi

  tmp="$(state_store_tmp_path "$file")"
  printf '{\n  "version": 1,\n  "records": []\n}\n' > "$tmp" || return 1
  mv -f "$tmp" "$file"
}

state_store_get_status() {
  local file="$1"
  local lookup_id="$2"

  state_store_read_records "$file" | awk -F'\t' -v id="$lookup_id" '
    $1 == id { print $3; found = 1; exit }
    END { if (!found) exit 1 }
  '
}

state_store_has_record() {
  local file="$1"
  local lookup_id="$2"

  state_store_get_status "$file" "$lookup_id" >/dev/null
}

state_store_is_processed() {
  local file="$1"
  local lookup_id="$2"
  local status

  if ! status="$(state_store_get_status "$file" "$lookup_id")"; then
    return 1
  fi

  [[ "$status" == "processed" ]]
}

state_store_upsert_record() {
  local file="$1"
  local video_id="$2"
  local published_at="$3"
  local status="$4"
  local dir
  local tmp
  local found=0
  local first=1

  dir="$(dirname "$file")"
  mkdir -p "$dir" || return 1
  tmp="$(state_store_tmp_path "$file")"

  {
    printf '{\n  "version": 1,\n  "records": [\n'
    while IFS=$'\t' read -r existing_id existing_published existing_status; do
      if [[ "$existing_id" == "$video_id" ]]; then
        existing_published="$published_at"
        existing_status="$status"
        found=1
      fi

      if [[ $first -eq 0 ]]; then
        printf ',\n'
      fi

      first=0
      state_store_emit_record "$existing_id" "$existing_published" "$existing_status"
    done < <(state_store_read_records "$file")

    if [[ $found -eq 0 ]]; then
      if [[ $first -eq 0 ]]; then
        printf ',\n'
      fi
      state_store_emit_record "$video_id" "$published_at" "$status"
    fi

    printf '\n  ]\n}\n'
  } > "$tmp" || return 1

  mv -f "$tmp" "$file"
}
