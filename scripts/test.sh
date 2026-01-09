#!/usr/bin/env bash
set -u
test_fail=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"
# shellcheck source=../lib/config.sh
source "${SCRIPT_DIR}/../lib/config.sh"

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"
  if [[ "${expected}" != "${actual}" ]]; then
    echo "not ok - ${message}: expected '${expected}', got '${actual}'" >&2
    return 1
  fi
}

run_test() {
  local name="$1"
  shift
  if "$@"; then
    echo "ok - ${name}"
  else
    test_fail=1
  fi
}

test_trim_whitespace() {
  local out
  out="$(trim_whitespace "  hello  ")"
  assert_eq "hello" "${out}" "trim_whitespace"
}

test_normalize_bool_true() {
  local out
  out="$(normalize_bool "yes" "SKIP_SHORTS")"
  assert_eq "true" "${out}" "normalize_bool yes"
}

test_normalize_bool_false() {
  local out
  out="$(normalize_bool "0" "SKIP_SHORTS")"
  assert_eq "false" "${out}" "normalize_bool 0"
}

test_normalize_bool_invalid() {
  if normalize_bool "maybe" "SKIP_SHORTS" >/dev/null 2>&1; then
    echo "not ok - normalize_bool invalid: expected failure" >&2
    return 1
  fi
}

test_resolve_path_absolute() {
  local out
  out="$(resolve_path "/tmp" "/var/lib")"
  assert_eq "/var/lib" "${out}" "resolve_path absolute"
}

test_resolve_path_relative() {
  local out
  out="$(resolve_path "/tmp" "foo")"
  assert_eq "/tmp/foo" "${out}" "resolve_path relative"
}

test_ensure_dir() {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  ensure_dir "${tmp_dir}" "TEST_DIR"
  local status=$?
  rm -rf "${tmp_dir}"
  return ${status}
}

run_test "trim_whitespace" test_trim_whitespace
run_test "normalize_bool_true" test_normalize_bool_true
run_test "normalize_bool_false" test_normalize_bool_false
run_test "normalize_bool_invalid" test_normalize_bool_invalid
run_test "resolve_path_absolute" test_resolve_path_absolute
run_test "resolve_path_relative" test_resolve_path_relative
run_test "ensure_dir" test_ensure_dir

if [[ ${test_fail} -ne 0 ]]; then
  exit 1
fi
