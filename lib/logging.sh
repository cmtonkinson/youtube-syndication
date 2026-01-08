#!/usr/bin/env bash

timestamp_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

generate_run_id() {
  date -u +"%Y%m%dT%H%M%SZ"
}

log_escape_value() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/ }"
  value="${value//$'\r'/ }"
  printf '%s' "$value"
}

log_kv() {
  local key="$1"
  local value="${2-}"
  if [[ -z "${value}" || "${value}" == *[[:space:]]* ]]; then
    printf '%s="%s"' "${key}" "$(log_escape_value "${value}")"
  else
    printf '%s=%s' "${key}" "${value}"
  fi
}

format_log_line() {
  local level="$1"
  local event="$2"
  local stage="$3"
  local msg="$4"
  shift 4

  local ts
  ts="$(timestamp_utc)"
  local run_id="${YTS_RUN_ID:-unknown}"
  local line
  line="ts=${ts} level=${level} event=${event} run_id=${run_id} stage=${stage} msg=\"$(log_escape_value "${msg}")\""
  local kv
  local key
  local value
  for kv in "$@"; do
    key="${kv%%=*}"
    value="${kv#*=}"
    line+=" $(log_kv "${key}" "${value}")"
  done
  printf '%s' "${line}"
}

log_line() {
  local level="$1"
  local event="$2"
  local stage="$3"
  local msg="$4"
  shift 4

  local line
  line="$(format_log_line "${level}" "${event}" "${stage}" "${msg}" "$@")"
  case "${level}" in
    WARN|ERROR)
      printf '%s\n' "${line}" >&2
      ;;
    *)
      printf '%s\n' "${line}"
      ;;
  esac
}

init_run_logging() {
  local run_id="${1:-}"
  if [[ -n "${run_id}" ]]; then
    YTS_RUN_ID="${run_id}"
  else
    YTS_RUN_ID="$(generate_run_id)"
  fi
  YTS_RUN_START_EPOCH="$(date -u +%s)"
  YTS_TOTAL_COUNT=0
  YTS_SUCCESS_COUNT=0
  YTS_SKIPPED_COUNT=0
  YTS_FAILED_COUNT=0
  YTS_WARNING_COUNT=0
  YTS_ABORTED=0
  YTS_SUMMARY_EMITTED=0
}

log_run_start() {
  log_line "INFO" "run_start" "init" "run start" "$@"
}

log_info_event() {
  local event="$1"
  local stage="$2"
  local msg="$3"
  shift 3
  log_line "INFO" "${event}" "${stage}" "${msg}" "$@"
}

log_warn_event() {
  local event="$1"
  local stage="$2"
  local msg="$3"
  shift 3
  YTS_WARNING_COUNT=$((YTS_WARNING_COUNT + 1))
  log_line "WARN" "${event}" "${stage}" "${msg}" "$@"
}

log_error_event() {
  local event="$1"
  local stage="$2"
  local msg="$3"
  shift 3
  log_line "ERROR" "${event}" "${stage}" "${msg}" "$@"
}

log_video_outcome() {
  local stage="$1"
  local outcome="$2"
  local video_id="$3"
  local title="$4"
  shift 4

  YTS_TOTAL_COUNT=$((YTS_TOTAL_COUNT + 1))
  case "${outcome}" in
    success)
      YTS_SUCCESS_COUNT=$((YTS_SUCCESS_COUNT + 1))
      log_info_event "video_outcome" "${stage}" "video ${outcome}" \
        "outcome=${outcome}" "video_id=${video_id}" "title=${title}" "$@"
      ;;
    skipped)
      YTS_SKIPPED_COUNT=$((YTS_SKIPPED_COUNT + 1))
      log_warn_event "video_outcome" "${stage}" "video ${outcome}" \
        "outcome=${outcome}" "video_id=${video_id}" "title=${title}" "$@"
      ;;
    failed)
      YTS_FAILED_COUNT=$((YTS_FAILED_COUNT + 1))
      log_error_event "video_outcome" "${stage}" "video ${outcome}" \
        "outcome=${outcome}" "video_id=${video_id}" "title=${title}" "$@"
      ;;
    *)
      log_info_event "video_outcome" "${stage}" "video ${outcome}" \
        "outcome=${outcome}" "video_id=${video_id}" "title=${title}" "$@"
      ;;
  esac
}

run_duration_seconds() {
  if [[ -z "${YTS_RUN_START_EPOCH:-}" ]]; then
    printf '0'
    return 0
  fi
  local now
  now="$(date -u +%s)"
  printf '%s' "$((now - YTS_RUN_START_EPOCH))"
}

compute_exit_code() {
  if [[ "${YTS_ABORTED:-0}" -eq 1 ]]; then
    printf '1'
  elif [[ "${YTS_FAILED_COUNT:-0}" -gt 0 ]]; then
    printf '2'
  else
    printf '0'
  fi
}

emit_run_summary() {
  local exit_code="$1"
  if [[ "${YTS_SUMMARY_EMITTED:-0}" -eq 1 ]]; then
    return 0
  fi

  local duration
  duration="$(run_duration_seconds)"
  local fields=(
    "duration_s=${duration}"
    "total=${YTS_TOTAL_COUNT:-0}"
    "success=${YTS_SUCCESS_COUNT:-0}"
    "skipped=${YTS_SKIPPED_COUNT:-0}"
    "failed=${YTS_FAILED_COUNT:-0}"
    "exit_code=${exit_code}"
  )
  if [[ "${YTS_WARNING_COUNT:-0}" -gt 0 ]]; then
    fields+=("warnings=${YTS_WARNING_COUNT}")
  fi

  local line
  line="$(format_log_line "INFO" "run_summary" "finalize" "run summary" "${fields[@]}")"
  printf '%s\n' "${line}"
  printf '%s\n' "${line}" > "./run-summary.logfmt"
  YTS_SUMMARY_EMITTED=1
}
