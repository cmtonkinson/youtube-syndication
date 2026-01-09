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

normalize_yt_value() {
  local value="$1"
  if [[ "${value}" == "NA" ]]; then
    printf ''
    return 0
  fi
  printf '%s' "${value}"
}

slugify_subscription() {
  local value="$1"
  local slug
  slug="$(printf '%s' "${value}" | sed 's/[^A-Za-z0-9._-]/_/g')"
  if [[ -z "${slug}" ]]; then
    slug="subscription"
  fi
  printf '%s' "${slug}"
}

write_sync_metadata() {
  local file="$1"
  local records_file="$2"
  local tmp
  local first=1

  tmp="$(state_store_tmp_path "${file}")"

  {
    printf '{\n  "version": 1,\n  "records": [\n'
    while IFS=$'\t' read -r order_key video_id title published_at duration size episode; do
      if [[ -z "${video_id}" ]]; then
        continue
      fi

      if [[ ${first} -eq 0 ]]; then
        printf ',\n'
      fi
      first=0

      local duration_json="null"
      local size_json="null"
      if [[ "${duration}" =~ ^[0-9]+$ ]]; then
        duration_json="${duration}"
      fi
      if [[ "${size}" =~ ^[0-9]+$ ]]; then
        size_json="${size}"
      fi

      printf '    {"id":"%s","title":"%s","published_at":"%s","duration_s":%s,"size_bytes":%s,"episode":%s}' \
        "$(state_store_json_escape "${video_id}")" \
        "$(state_store_json_escape "${title}")" \
        "$(state_store_json_escape "${published_at}")" \
        "${duration_json}" "${size_json}" "${episode}"
    done < "${records_file}"
    printf '\n  ]\n}\n'
  } > "${tmp}" || return 1

  mv -f "${tmp}" "${file}"
}

sync_stage() {
  local state_dir="${STATE_DIR:-./state}"
  local sep=$'\x1f'
  local yt_format
  yt_format="%(id)s${sep}%(title)s${sep}%(upload_date)s${sep}%(timestamp)s${sep}%(duration)s${sep}%(filesize,filesize_approx)s${sep}%(live_status)s${sep}%(is_live)s${sep}%(was_live)s"
  local had_error=0

  if ! mkdir -p "${state_dir}"; then
    log_error_event "sync_failed" "sync" "failed to create state directory" \
      "state_dir=${state_dir}"
    return 1
  fi

  local subscription
  for subscription in "${SUBSCRIPTIONS[@]}"; do
    local slug
    slug="$(slugify_subscription "${subscription}")"
    local state_file="${state_dir}/${slug}.json"
    local metadata_file="${state_dir}/${slug}.metadata.json"

    if ! state_store_init_file "${state_file}"; then
      log_error_event "sync_failed" "sync" "failed to init state file" \
        "subscription=${slug}" "state_file=${state_file}"
      had_error=1
      continue
    fi

    local listing_file
    listing_file="$(mktemp "${state_dir}/.${slug}.listing.XXXXXX")" || {
      log_error_event "sync_failed" "sync" "failed to create listing file" \
        "subscription=${slug}" "state_dir=${state_dir}"
      had_error=1
      continue
    }

    if ! yt-dlp --skip-download --no-warnings --ignore-errors \
      --print "${yt_format}" "${subscription}" > "${listing_file}"; then
      log_error_event "sync_failed" "sync" "yt-dlp listing failed" \
        "subscription=${slug}" "target=${subscription}"
      rm -f "${listing_file}"
      had_error=1
      continue
    fi

    local items_file
    items_file="$(mktemp "${state_dir}/.${slug}.items.XXXXXX")" || {
      log_error_event "sync_failed" "sync" "failed to create items file" \
        "subscription=${slug}" "state_dir=${state_dir}"
      rm -f "${listing_file}"
      had_error=1
      continue
    }

    while IFS=${sep} read -r video_id title upload_date timestamp duration size live_status is_live was_live; do
      video_id="$(normalize_yt_value "${video_id}")"
      title="$(normalize_yt_value "${title}")"
      upload_date="$(normalize_yt_value "${upload_date}")"
      timestamp="$(normalize_yt_value "${timestamp}")"
      duration="$(normalize_yt_value "${duration}")"
      size="$(normalize_yt_value "${size}")"
      live_status="$(normalize_yt_value "${live_status}")"
      is_live="$(normalize_yt_value "${is_live}")"
      was_live="$(normalize_yt_value "${was_live}")"

      if [[ -z "${video_id}" ]]; then
        continue
      fi

      title="${title//$'\t'/ }"
      title="${title//$'\r'/ }"
      title="${title//$'\n'/ }"

      local published_at=""
      local order_key=""
      if [[ "${upload_date}" =~ ^[0-9]{8}$ ]]; then
        published_at="${upload_date}"
        order_key="${upload_date}"
      elif [[ "${timestamp}" =~ ^[0-9]+$ ]]; then
        published_at="${timestamp}"
        order_key="${timestamp}"
      fi

      if [[ -z "${order_key}" ]]; then
        log_video_outcome "sync" "skipped" "${video_id}" "${title}" \
          "subscription=${slug}" "reason=missing_publish_date"
        continue
      fi

      if [[ -n "${TITLE_SKIP_REGEX}" ]]; then
        if printf '%s' "${title}" | grep -E -- "${TITLE_SKIP_REGEX}" >/dev/null; then
          log_video_outcome "sync" "skipped" "${video_id}" "${title}" \
            "subscription=${slug}" "reason=title_pattern"
          continue
        fi
      fi

      local is_short=0
      if [[ "${duration}" =~ ^[0-9]+$ ]] && [[ "${duration}" -le 60 ]]; then
        is_short=1
      fi
      if [[ "${SKIP_SHORTS}" == "true" && ${is_short} -eq 1 ]]; then
        log_video_outcome "sync" "skipped" "${video_id}" "${title}" \
          "subscription=${slug}" "reason=shorts"
        continue
      fi

      local is_live_flag=0
      local live_status_norm="${live_status,,}"
      if [[ -n "${live_status_norm}" && "${live_status_norm}" != "not_live" ]]; then
        is_live_flag=1
      fi
      if [[ "${is_live,,}" == "true" || "${was_live,,}" == "true" ]]; then
        is_live_flag=1
      fi
      if [[ "${SKIP_LIVESTREAMS}" == "true" && ${is_live_flag} -eq 1 ]]; then
        log_video_outcome "sync" "skipped" "${video_id}" "${title}" \
          "subscription=${slug}" "reason=livestream"
        continue
      fi

      if [[ "${MAX_DURATION_MIN}" -gt 0 ]] && [[ "${duration}" =~ ^[0-9]+$ ]]; then
        local max_seconds=$((MAX_DURATION_MIN * 60))
        if [[ "${duration}" -gt "${max_seconds}" ]]; then
          log_video_outcome "sync" "skipped" "${video_id}" "${title}" \
            "subscription=${slug}" "reason=duration_limit"
          continue
        fi
      fi

      if [[ "${MAX_SIZE_MB}" -gt 0 ]] && [[ "${size}" =~ ^[0-9]+$ ]]; then
        local max_bytes=$((MAX_SIZE_MB * 1024 * 1024))
        if [[ "${size}" -gt "${max_bytes}" ]]; then
          log_video_outcome "sync" "skipped" "${video_id}" "${title}" \
            "subscription=${slug}" "reason=size_limit"
          continue
        fi
      fi

      printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "${order_key}" "${video_id}" "${title}" "${published_at}" "${duration}" "${size}" \
        >> "${items_file}"
    done < "${listing_file}"

    rm -f "${listing_file}"

    local sorted_file
    sorted_file="$(mktemp "${state_dir}/.${slug}.sorted.XXXXXX")" || {
      log_error_event "sync_failed" "sync" "failed to create sorted file" \
        "subscription=${slug}" "state_dir=${state_dir}"
      rm -f "${items_file}"
      had_error=1
      continue
    }

    sort -t $'\t' -k1,1 -k2,2 "${items_file}" > "${sorted_file}"
    rm -f "${items_file}"

    local episode=1
    local metadata_records
    metadata_records="$(mktemp "${state_dir}/.${slug}.records.XXXXXX")" || {
      log_error_event "sync_failed" "sync" "failed to create records file" \
        "subscription=${slug}" "state_dir=${state_dir}"
      rm -f "${sorted_file}"
      had_error=1
      continue
    }

    while IFS=$'\t' read -r order_key video_id title published_at duration size; do
      if [[ -z "${video_id}" ]]; then
        continue
      fi

      local status=""
      if status="$(state_store_get_status "${state_file}" "${video_id}")"; then
        :
      else
        status=""
      fi

      case "${status}" in
        processed|downloaded)
          log_video_outcome "sync" "skipped" "${video_id}" "${title}" \
            "subscription=${slug}" "reason=already_${status}"
          ;;
        *)
          status="pending"
          log_video_outcome "sync" "success" "${video_id}" "${title}" \
            "subscription=${slug}" "episode=${episode}"
          ;;
      esac

      if ! state_store_upsert_record "${state_file}" "${video_id}" "${published_at}" "${status}" "" ""; then
        log_error_event "sync_failed" "sync" "failed to update state" \
          "subscription=${slug}" "video_id=${video_id}"
        had_error=1
        continue
      fi

      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "${order_key}" "${video_id}" "${title}" "${published_at}" "${duration}" "${size}" "${episode}" \
        >> "${metadata_records}"

      episode=$((episode + 1))
    done < "${sorted_file}"

    if ! write_sync_metadata "${metadata_file}" "${metadata_records}"; then
      log_error_event "sync_failed" "sync" "failed to write metadata cache" \
        "subscription=${slug}" "metadata_file=${metadata_file}"
      had_error=1
    fi

    rm -f "${sorted_file}" "${metadata_records}"
  done

  if [[ ${had_error} -ne 0 ]]; then
    return 1
  fi

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

process_stage() {
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
