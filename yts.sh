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

import_stage() {
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
