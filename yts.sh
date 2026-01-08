#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/logging.sh
source "${SCRIPT_DIR}/lib/logging.sh"
# shellcheck source=lib/preflight.sh
source "${SCRIPT_DIR}/lib/preflight.sh"

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

  log_run_start

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
