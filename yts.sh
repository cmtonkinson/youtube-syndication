#!/usr/bin/env bash

set -u

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
  local stage_name="$1"

  if ! "$stage_name"; then
    printf 'Stage failed: %s\n' "$stage_name" >&2
    return 1
  fi
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

  run_stage sync_stage || return 1
  run_stage download_stage || return 1
  run_stage process_stage || return 1
  run_stage import_stage || return 1
}

main "$@"
