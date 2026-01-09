#!/usr/bin/env bash
set -euo pipefail

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck is required for linting." >&2
  echo "Install with: brew install shellcheck or apt-get install shellcheck" >&2
  exit 1
fi

shellcheck yts.sh lib/*.sh scripts/*.sh
