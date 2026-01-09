#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/logging.sh
source "${SCRIPT_DIR}/lib/logging.sh"
# shellcheck source=lib/config.sh
source "${SCRIPT_DIR}/lib/config.sh"
# shellcheck source=lib/preflight.sh
source "${SCRIPT_DIR}/lib/preflight.sh"
# shellcheck source=lib/state_store.sh
source "${SCRIPT_DIR}/lib/state_store.sh"

usage() {
  cat <<'EOF'
Usage: yts.sh [--help]

Runs the full YouTube syndication pipeline in this order:
  1) sync
  2) download
  3) process
  4) import

Required inputs:
  - subscriptions.txt at the repository root

Stages are placeholders and will be implemented in later tasks.
EOF
}

sync_stage() {
  return 0
}

download_stage() {
  local state_dir="${STATE_DIR:-./state}"
  local staging_dir="${STAGING_DIR:-./staging}"

  if [[ ! -d "${state_dir}" ]]; then
    log_info_event "download_skipped" "download" "state directory missing" \
      "state_dir=${state_dir}"
    return 0
  fi

  local state_files=()
  mapfile -t state_files < <(find "${state_dir}" -maxdepth 1 -type f -name '*.json' -print | sort)

  if [[ "${#state_files[@]}" -eq 0 ]]; then
    log_info_event "download_skipped" "download" "no state files found" \
      "state_dir=${state_dir}"
    return 0
  fi

  local state_file
  for state_file in "${state_files[@]}"; do
    local subscription
    subscription="$(basename "${state_file}" .json)"
    if [[ -z "${subscription}" ]]; then
      subscription="unknown"
    fi

    while IFS=$'\t' read -r video_id published_at status video_path thumbnail_path; do
      if [[ -z "${video_id}" ]]; then
        continue
      fi

      case "${status}" in
        downloaded|processed)
          log_video_outcome "download" "skipped" "${video_id}" "" \
            "subscription=${subscription}" "reason=already_${status}"
          continue
          ;;
        pending)
          ;;
        *)
          continue
          ;;
      esac

      local download_dir="${staging_dir}/${subscription}"
      if ! mkdir -p "${download_dir}"; then
        state_store_upsert_record "${state_file}" "${video_id}" "${published_at}" \
          "download_failed" "" ""
        log_video_outcome "download" "failed" "${video_id}" "" \
          "subscription=${subscription}" "error=staging_dir_create_failed"
        continue
      fi

      local output_template="${download_dir}/${video_id}.%(ext)s"
      local download_target="${video_id}"
      if [[ "${video_id}" != http* ]]; then
        download_target="https://www.youtube.com/watch?v=${video_id}"
      fi

      if yt-dlp --no-playlist --merge-output-format mp4 \
        --write-thumbnail --convert-thumbnails jpg \
        -o "${output_template}" "${download_target}"; then
        local video_file="${download_dir}/${video_id}.mp4"
        local thumb_file="${download_dir}/${video_id}.jpg"
        if [[ -f "${video_file}" && -f "${thumb_file}" ]]; then
          state_store_upsert_record "${state_file}" "${video_id}" "${published_at}" \
            "downloaded" "${video_file}" "${thumb_file}"
          log_video_outcome "download" "success" "${video_id}" "" \
            "subscription=${subscription}" "video_path=${video_file}" \
            "thumbnail_path=${thumb_file}"
        else
          state_store_upsert_record "${state_file}" "${video_id}" "${published_at}" \
            "download_failed" "${video_file}" "${thumb_file}"
          log_video_outcome "download" "failed" "${video_id}" "" \
            "subscription=${subscription}" "error=missing_output_files"
        fi
      else
        state_store_upsert_record "${state_file}" "${video_id}" "${published_at}" \
          "download_failed" "" ""
        log_video_outcome "download" "failed" "${video_id}" "" \
          "subscription=${subscription}" "error=yt_dlp_failed"
      fi
    done < <(state_store_read_records "${state_file}")
  done

  return 0
}

normalize_metadata_text() {
  local raw="$1"
  if [[ -z "${raw}" ]]; then
    printf ''
    return 0
  fi
  printf '%s' "${raw}" | tr '\r\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//'
}

read_info_field() {
  local info_file="$1"
  local field="$2"

  yt-dlp --load-info-json "${info_file}" --print "%(${field})s" 2>/dev/null
}

ensure_info_json() {
  local video_id="$1"
  local info_file="$2"
  local output_template="$3"
  local download_target="$4"

  if [[ -f "${info_file}" ]]; then
    return 0
  fi

  if yt-dlp --no-playlist --skip-download --write-info-json \
    -o "${output_template}" "${download_target}"; then
    return 0
  fi

  return 1
}

process_stage() {
  local state_dir="${STATE_DIR:-./state}"
  local staging_dir="${STAGING_DIR:-./staging}"

  if [[ ! -d "${state_dir}" ]]; then
    log_info_event "process_skipped" "process" "state directory missing" \
      "state_dir=${state_dir}"
    return 0
  fi

  local state_files=()
  mapfile -t state_files < <(find "${state_dir}" -maxdepth 1 -type f -name '*.json' -print | sort)

  if [[ "${#state_files[@]}" -eq 0 ]]; then
    log_info_event "process_skipped" "process" "no state files found" \
      "state_dir=${state_dir}"
    return 0
  fi

  local state_file
  for state_file in "${state_files[@]}"; do
    local subscription
    subscription="$(basename "${state_file}" .json)"
    if [[ -z "${subscription}" ]]; then
      subscription="unknown"
    fi

    while IFS=$'\t' read -r video_id published_at status video_path thumbnail_path; do
      if [[ -z "${video_id}" ]]; then
        continue
      fi

      case "${status}" in
        processed)
          log_video_outcome "process" "skipped" "${video_id}" "" \
            "subscription=${subscription}" "reason=already_processed"
          continue
          ;;
        downloaded)
          ;;
        *)
          continue
          ;;
      esac

      if [[ -z "${video_path}" || -z "${thumbnail_path}" ]]; then
        state_store_upsert_record "${state_file}" "${video_id}" "${published_at}" \
          "process_failed" "${video_path}" "${thumbnail_path}"
        log_video_outcome "process" "failed" "${video_id}" "" \
          "subscription=${subscription}" "error=missing_paths"
        continue
      fi

      if [[ ! -f "${video_path}" || ! -f "${thumbnail_path}" ]]; then
        state_store_upsert_record "${state_file}" "${video_id}" "${published_at}" \
          "process_failed" "${video_path}" "${thumbnail_path}"
        log_video_outcome "process" "failed" "${video_id}" "" \
          "subscription=${subscription}" "error=missing_files"
        continue
      fi

      local download_dir
      download_dir="$(dirname "${video_path}")"
      local output_template="${download_dir}/${video_id}.%(ext)s"
      local info_file="${video_path%.mp4}.info.json"
      local download_target="${video_id}"
      if [[ "${video_id}" != http* ]]; then
        download_target="https://www.youtube.com/watch?v=${video_id}"
      fi

      if ! ensure_info_json "${video_id}" "${info_file}" "${output_template}" "${download_target}"; then
        state_store_upsert_record "${state_file}" "${video_id}" "${published_at}" \
          "process_failed" "${video_path}" "${thumbnail_path}"
        log_video_outcome "process" "failed" "${video_id}" "" \
          "subscription=${subscription}" "error=metadata_fetch_failed"
        continue
      fi

      local raw_title
      local raw_description
      local raw_channel
      raw_title="$(read_info_field "${info_file}" "title")"
      raw_description="$(read_info_field "${info_file}" "description")"
      raw_channel="$(read_info_field "${info_file}" "channel")"
      if [[ -z "${raw_channel}" ]]; then
        raw_channel="$(read_info_field "${info_file}" "uploader")"
      fi
      if [[ -z "${raw_channel}" ]]; then
        raw_channel="${subscription}"
      fi

      local title
      local description
      local channel
      title="$(normalize_metadata_text "${raw_title}")"
      description="$(normalize_metadata_text "${raw_description}")"
      channel="$(normalize_metadata_text "${raw_channel}")"

      if [[ -z "${title}" ]]; then
        state_store_upsert_record "${state_file}" "${video_id}" "${published_at}" \
          "process_failed" "${video_path}" "${thumbnail_path}"
        log_video_outcome "process" "failed" "${video_id}" "" \
          "subscription=${subscription}" "error=missing_title"
        continue
      fi

      if AtomicParsley "${video_path}" \
        --title "${title}" \
        --artist "${channel}" \
        --description "${description}" \
        --artwork "${thumbnail_path}" \
        --overWrite >/dev/null 2>&1; then
        state_store_upsert_record "${state_file}" "${video_id}" "${published_at}" \
          "processed" "${video_path}" "${thumbnail_path}"
        log_video_outcome "process" "success" "${video_id}" "${title}" \
          "subscription=${subscription}" "video_path=${video_path}"
      else
        state_store_upsert_record "${state_file}" "${video_id}" "${published_at}" \
          "process_failed" "${video_path}" "${thumbnail_path}"
        log_video_outcome "process" "failed" "${video_id}" "${title}" \
          "subscription=${subscription}" "error=atomicparsley_failed"
      fi
    done < <(state_store_read_records "${state_file}")
  done

  return 0
}

sanitize_component() {
  local raw="$1"
  local cleaned

  cleaned="$(printf '%s' "${raw}" | tr '\000' ' ' | sed \
    -e 's/[\/\\:]/-/g' \
    -e 's/[[:cntrl:]]//g' \
    -e 's/[[:space:]]\+/ /g' \
    -e 's/^ *//; s/ *$//')"

  if [[ -z "${cleaned}" ]]; then
    cleaned="unknown"
  fi

  printf '%s' "${cleaned}"
}

json_extract_string() {
  local file="$1"
  local key="$2"

  if [[ ! -f "${file}" ]]; then
    return 1
  fi

  local blob
  blob="$(tr -d '\n' < "${file}")"

  local value
  value="$(printf '%s' "${blob}" | sed -n "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" \
    | head -n 1)"

  if [[ -z "${value}" ]]; then
    return 1
  fi

  value="${value//\\\"/\"}"
  value="${value//\\\\/\\}"
  value="${value//\\\//\/}"
  value="${value//\\n/ }"
  value="${value//\\r/ }"
  value="${value//\\t/ }"
  printf '%s' "${value}"
}

resolve_metadata_value() {
  local info_path="$1"
  shift
  local key
  for key in "$@"; do
    local value
    if value="$(json_extract_string "${info_path}" "${key}")"; then
      if [[ -n "${value}" ]]; then
        printf '%s' "${value}"
        return 0
      fi
    fi
  done
  return 1
}

find_info_json() {
  local video_path="$1"
  local thumbnail_path="$2"
  local staging_dir="$3"
  local subscription="$4"
  local video_id="$5"

  if [[ -n "${video_path}" ]]; then
    local base="${video_path%.*}"
    if [[ -f "${base}.info.json" ]]; then
      printf '%s' "${base}.info.json"
      return 0
    fi
  fi

  if [[ -n "${thumbnail_path}" ]]; then
    local base="${thumbnail_path%.*}"
    if [[ -f "${base}.info.json" ]]; then
      printf '%s' "${base}.info.json"
      return 0
    fi
  fi

  if [[ -n "${staging_dir}" && -n "${subscription}" && -n "${video_id}" ]]; then
    local candidate="${staging_dir}/${subscription}/${video_id}.info.json"
    if [[ -f "${candidate}" ]]; then
      printf '%s' "${candidate}"
      return 0
    fi
  fi

  return 1
}

resolve_unique_basename() {
  local dest_dir="$1"
  local base="$2"
  local video_id="$3"
  local ext="$4"

  local candidate="${dest_dir}/${base}.${ext}"
  if [[ ! -e "${candidate}" ]]; then
    printf '%s' "${base}"
    return 0
  fi

  local sanitized_id
  sanitized_id="$(sanitize_component "${video_id}")"
  local alt_base="${base} (${sanitized_id})"
  local alt_candidate="${dest_dir}/${alt_base}.${ext}"
  if [[ ! -e "${alt_candidate}" ]]; then
    printf '%s' "${alt_base}"
    return 0
  fi

  local idx=1
  while [[ -e "${dest_dir}/${alt_base}-${idx}.${ext}" ]]; do
    idx=$((idx + 1))
  done

  printf '%s' "${alt_base}-${idx}"
}

import_stage() {
  local state_dir="${STATE_DIR:-./state}"
  local library_dir="${LIBRARY_DIR:-./youtube}"
  local staging_dir="${STAGING_DIR:-./staging}"

  if [[ ! -d "${state_dir}" ]]; then
    log_info_event "import_skipped" "import" "state directory missing" \
      "state_dir=${state_dir}"
    return 0
  fi

  local state_files=()
  mapfile -t state_files < <(find "${state_dir}" -maxdepth 1 -type f -name '*.json' -print | sort)

  if [[ "${#state_files[@]}" -eq 0 ]]; then
    log_info_event "import_skipped" "import" "no state files found" \
      "state_dir=${state_dir}"
    return 0
  fi

  local state_file
  for state_file in "${state_files[@]}"; do
    local subscription
    subscription="$(basename "${state_file}" .json)"
    if [[ -z "${subscription}" ]]; then
      subscription="unknown"
    fi

    local episode_map=()
    declare -A episode_map
    local sort_input=()
    while IFS=$'\t' read -r video_id published_at status video_path thumbnail_path; do
      if [[ -z "${video_id}" ]]; then
        continue
      fi
      local published_key="${published_at}"
      if [[ -z "${published_key}" ]]; then
        published_key="9999-12-31T23:59:59Z"
      fi
      sort_input+=("${published_key}"$'\t'"${video_id}")
    done < <(state_store_read_records "${state_file}")

    if [[ "${#sort_input[@]}" -gt 0 ]]; then
      local sorted_lines=()
      mapfile -t sorted_lines < <(printf '%s\n' "${sort_input[@]}" | sort)
      local idx=1
      local line
      for line in "${sorted_lines[@]}"; do
        local map_id="${line#*$'\t'}"
        episode_map["${map_id}"]="${idx}"
        idx=$((idx + 1))
      done
    fi

    local subscription_name=""
    while IFS=$'\t' read -r video_id published_at status video_path thumbnail_path; do
      if [[ -n "${subscription_name}" ]]; then
        break
      fi
      local info_path=""
      if info_path="$(find_info_json "${video_path}" "${thumbnail_path}" "${staging_dir}" "${subscription}" "${video_id}")"; then
        if subscription_name="$(resolve_metadata_value "${info_path}" "playlist_title" "playlist" "channel" "uploader" "creator")"; then
          subscription_name="$(sanitize_component "${subscription_name}")"
        fi
      fi
    done < <(state_store_read_records "${state_file}")

    if [[ -z "${subscription_name}" ]]; then
      subscription_name="$(sanitize_component "${subscription}")"
    fi

    local dest_dir="${library_dir}/${subscription_name}"
    if ! mkdir -p "${dest_dir}"; then
      log_error_event "import_failed" "import" "failed to create destination directory" \
        "subscription=${subscription}" "dest_dir=${dest_dir}"
      continue
    fi

    while IFS=$'\t' read -r video_id published_at status video_path thumbnail_path; do
      if [[ -z "${video_id}" ]]; then
        continue
      fi

      case "${status}" in
        imported)
          log_video_outcome "import" "skipped" "${video_id}" "" \
            "subscription=${subscription}" "reason=already_imported"
          continue
          ;;
        processed)
          ;;
        *)
          continue
          ;;
      esac

      if [[ -z "${video_path}" || -z "${thumbnail_path}" ]]; then
        state_store_upsert_record "${state_file}" "${video_id}" "${published_at}" \
          "import_failed" "${video_path}" "${thumbnail_path}"
        log_video_outcome "import" "failed" "${video_id}" "" \
          "subscription=${subscription}" "error=missing_paths"
        continue
      fi

      if [[ ! -f "${video_path}" || ! -f "${thumbnail_path}" ]]; then
        state_store_upsert_record "${state_file}" "${video_id}" "${published_at}" \
          "import_failed" "${video_path}" "${thumbnail_path}"
        log_video_outcome "import" "failed" "${video_id}" "" \
          "subscription=${subscription}" "error=staging_files_missing"
        continue
      fi

      if [[ "${video_path##*.}" != "mp4" || "${thumbnail_path##*.}" != "jpg" ]]; then
        state_store_upsert_record "${state_file}" "${video_id}" "${published_at}" \
          "import_failed" "${video_path}" "${thumbnail_path}"
        log_video_outcome "import" "failed" "${video_id}" "" \
          "subscription=${subscription}" "error=invalid_media_extensions"
        continue
      fi

      local info_path=""
      info_path="$(find_info_json "${video_path}" "${thumbnail_path}" "${staging_dir}" "${subscription}" "${video_id}")"

      local title=""
      if [[ -n "${info_path}" ]]; then
        if title="$(resolve_metadata_value "${info_path}" "title")"; then
          title="$(sanitize_component "${title}")"
        fi
      fi
      if [[ -z "${title}" ]]; then
        title="$(sanitize_component "${video_id}")"
      fi

      local episode_num="${episode_map[${video_id}]:-}"
      if [[ -z "${episode_num}" ]]; then
        episode_num=1
        log_warn_event "import_episode_missing" "import" "episode number missing" \
          "subscription=${subscription}" "video_id=${video_id}"
      fi

      local episode_label
      episode_label="$(printf '%02d' "${episode_num}")"

      local base_name="${subscription_name} - S01E${episode_label} - ${title}"
      base_name="$(sanitize_component "${base_name}")"

      local resolved_base
      resolved_base="$(resolve_unique_basename "${dest_dir}" "${base_name}" "${video_id}" "mp4")"
      if [[ "${resolved_base}" != "${base_name}" ]]; then
        log_warn_event "import_collision" "import" "resolved naming collision" \
          "subscription=${subscription}" "video_id=${video_id}" \
          "base=${base_name}" "resolved=${resolved_base}"
      fi

      local dest_video="${dest_dir}/${resolved_base}.mp4"
      local dest_thumb="${dest_dir}/${resolved_base}.jpg"

      if ! mv -f "${video_path}" "${dest_video}"; then
        state_store_upsert_record "${state_file}" "${video_id}" "${published_at}" \
          "import_failed" "${video_path}" "${thumbnail_path}"
        log_video_outcome "import" "failed" "${video_id}" "${title}" \
          "subscription=${subscription}" "error=move_video_failed"
        continue
      fi

      if ! mv -f "${thumbnail_path}" "${dest_thumb}"; then
        state_store_upsert_record "${state_file}" "${video_id}" "${published_at}" \
          "import_failed" "${dest_video}" "${thumbnail_path}"
        log_video_outcome "import" "failed" "${video_id}" "${title}" \
          "subscription=${subscription}" "error=move_thumbnail_failed"
        continue
      fi

      if [[ -n "${info_path}" && -f "${info_path}" ]]; then
        rm -f "${info_path}"
      fi

      local staging_parent
      staging_parent="$(dirname "${video_path}")"
      if [[ -d "${staging_parent}" ]]; then
        rmdir "${staging_parent}" >/dev/null 2>&1 || true
      fi

      state_store_upsert_record "${state_file}" "${video_id}" "${published_at}" \
        "imported" "${dest_video}" "${dest_thumb}"
      log_video_outcome "import" "success" "${video_id}" "${title}" \
        "subscription=${subscription}" "video_path=${dest_video}" \
        "thumbnail_path=${dest_thumb}"
    done < <(state_store_read_records "${state_file}")
  done

  return 0
}

run_stage() {
  local stage_label="$1"
  local stage_fn="$2"

  if ! "${stage_fn}"; then
    YTS_ABORTED=1
    log_error_event "stage_failed" "${stage_label}" "stage failed" \
      "stage=${stage_label}"
    return 1
  fi
}

on_exit() {
  local exit_code="$1"
  if [[ -z "${YTS_RUN_ID:-}" ]]; then
    return 0
  fi
  if [[ "${YTS_SUMMARY_EMITTED:-0}" -eq 1 ]]; then
    return 0
  fi
  emit_run_summary "${exit_code}"
}

main() {
  case "${1:-}" in
    --help|-h)
      usage
      return 0
      ;;
    "" )
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      return 2
      ;;
  esac

  init_run_logging
  trap 'on_exit $?' EXIT

  resolve_input_paths
  log_run_start "config_path=${CONFIG_PATH}"

  load_inputs || return 1

  preflight_check || return 1

  run_stage sync sync_stage || return 1
  run_stage download download_stage || return 1
  run_stage process process_stage || return 1
  run_stage import import_stage || return 1

  local exit_code
  exit_code="$(compute_exit_code)"
  return "${exit_code}"
}

main "$@"
