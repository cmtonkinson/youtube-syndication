#!/usr/bin/env bash

preflight_check() {
  local missing=()
  local tool
  for tool in "yt-dlp" "AtomicParsley"; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
      missing+=("${tool}")
    fi
  done

  if [[ "${#missing[@]}" -gt 0 ]]; then
    YTS_ABORTED=1
    local missing_list
    missing_list="$(IFS=,; printf '%s' "${missing[*]}")"
    log_error_event "preflight_failed" "init" "missing required tools" \
      "tools=${missing_list}"
    return 1
  fi

  return 0
}
