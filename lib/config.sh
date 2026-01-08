#!/usr/bin/env bash

trim_whitespace() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "${value}"
}

config_error() {
  local msg="$1"
  shift
  YTS_ABORTED=1
  log_error_event "config_invalid" "init" "${msg}" "$@"
  return 1
}

subscriptions_error() {
  local msg="$1"
  shift
  YTS_ABORTED=1
  log_error_event "subscriptions_invalid" "init" "${msg}" "$@"
  return 1
}

normalize_bool() {
  local raw="$1"
  local field="$2"
  if [[ -z "${raw}" ]]; then
    printf ''
    return 0
  fi
  case "${raw,,}" in
    true|1|yes)
      printf 'true'
      ;;
    false|0|no)
      printf 'false'
      ;;
    *)
      config_error "invalid boolean value" "field=${field}" "value=${raw}"
      return 1
      ;;
  esac
}

ensure_dir() {
  local path="$1"
  local field="$2"
  if ! mkdir -p "${path}"; then
    config_error "failed to create directory" "field=${field}" "path=${path}"
    return 1
  fi
  if [[ ! -d "${path}" ]]; then
    config_error "path is not a directory" "field=${field}" "path=${path}"
    return 1
  fi
  if [[ ! -w "${path}" ]]; then
    config_error "directory is not writable" "field=${field}" "path=${path}"
    return 1
  fi
}

resolve_path() {
  local base_dir="$1"
  local path="$2"
  if [[ "${path}" == /* ]]; then
    printf '%s' "${path}"
  else
    printf '%s/%s' "${base_dir}" "${path}"
  fi
}

resolve_input_paths() {
  SUBSCRIPTIONS_PATH="./subscriptions.txt"
  local config_path="${YTS_CONFIG:-}"
  if [[ -n "${config_path}" ]]; then
    CONFIG_PATH="${config_path}"
  else
    CONFIG_PATH="$(dirname "${SUBSCRIPTIONS_PATH}")/yts.conf"
  fi
}

load_subscriptions() {
  if [[ ! -f "${SUBSCRIPTIONS_PATH}" ]]; then
    subscriptions_error "subscriptions file missing" "path=${SUBSCRIPTIONS_PATH}"
    return 1
  fi

  SUBSCRIPTIONS=()
  local line
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line%%$'\r'}"
    local trimmed
    trimmed="$(trim_whitespace "${line}")"
    if [[ -z "${trimmed}" ]]; then
      continue
    fi
    if [[ "${trimmed}" == \#* ]]; then
      continue
    fi
    SUBSCRIPTIONS+=("${trimmed}")
  done < "${SUBSCRIPTIONS_PATH}"

  if [[ "${#SUBSCRIPTIONS[@]}" -eq 0 ]]; then
    subscriptions_error "subscriptions file is empty" "path=${SUBSCRIPTIONS_PATH}"
    return 1
  fi

  SUBSCRIPTIONS_COUNT="${#SUBSCRIPTIONS[@]}"
}

load_config() {
  local config_dir
  config_dir="$(dirname "${CONFIG_PATH}")"
  if [[ ! -d "${config_dir}" ]]; then
    config_error "config directory missing" "path=${config_dir}"
    return 1
  fi
  config_dir="$(cd "${config_dir}" && pwd -P)"

  SKIP_SHORTS="true"
  SKIP_LIVESTREAMS="true"
  MAX_SIZE_MB="0"
  MAX_DURATION_MIN="0"
  TITLE_SKIP_REGEX=""
  LIBRARY_DIR="./youtube"
  STAGING_DIR="./staging"
  STATE_DIR="./state"

  if [[ -f "${CONFIG_PATH}" ]]; then
    local line
    local line_num=0
    while IFS= read -r line || [[ -n "${line}" ]]; do
      line_num=$((line_num + 1))
      line="${line%%$'\r'}"
      local trimmed
      trimmed="$(trim_whitespace "${line}")"
      if [[ -z "${trimmed}" ]]; then
        continue
      fi
      if [[ "${trimmed}" == \#* ]]; then
        continue
      fi
      if [[ "${trimmed}" != *=* ]]; then
        config_error "invalid config line" "line=${line_num}" "content=${trimmed}"
        return 1
      fi

      local key="${trimmed%%=*}"
      local value="${trimmed#*=}"
      key="$(trim_whitespace "${key}")"
      value="$(trim_whitespace "${value}")"

      if [[ -z "${key}" ]]; then
        config_error "empty config key" "line=${line_num}"
        return 1
      fi
      if ! [[ "${key}" =~ ^[A-Z0-9_]+$ ]]; then
        config_error "invalid config key" "line=${line_num}" "key=${key}"
        return 1
      fi

      if [[ "${value}" == \"*\" || "${value}" == *\" ]]; then
        if [[ "${value}" == \"*\" && "${value}" == *\" && "${#value}" -ge 2 ]]; then
          value="${value:1:${#value}-2}"
        else
          config_error "invalid quoted value" "line=${line_num}" "key=${key}"
          return 1
        fi
      fi

      case "${key}" in
        SKIP_SHORTS)
          if [[ -n "${value}" ]]; then
            local normalized
            normalized="$(normalize_bool "${value}" "SKIP_SHORTS")" || return 1
            SKIP_SHORTS="${normalized}"
          fi
          ;;
        SKIP_LIVESTREAMS)
          if [[ -n "${value}" ]]; then
            local normalized
            normalized="$(normalize_bool "${value}" "SKIP_LIVESTREAMS")" || return 1
            SKIP_LIVESTREAMS="${normalized}"
          fi
          ;;
        MAX_SIZE_MB)
          if [[ -n "${value}" ]]; then
            if ! [[ "${value}" =~ ^[0-9]+$ ]]; then
              config_error "invalid max size" "line=${line_num}" "value=${value}"
              return 1
            fi
            MAX_SIZE_MB="${value}"
          fi
          ;;
        MAX_DURATION_MIN)
          if [[ -n "${value}" ]]; then
            if ! [[ "${value}" =~ ^[0-9]+$ ]]; then
              config_error "invalid max duration" "line=${line_num}" "value=${value}"
              return 1
            fi
            MAX_DURATION_MIN="${value}"
          fi
          ;;
        TITLE_SKIP_REGEX)
          if [[ -n "${value}" ]]; then
            if ! printf '' | grep -E -- "${value}" >/dev/null 2>&1; then
              local status=$?
              if [[ "${status}" -eq 2 ]]; then
                config_error "invalid title regex" "line=${line_num}" "value=${value}"
                return 1
              fi
            fi
            TITLE_SKIP_REGEX="${value}"
          fi
          ;;
        LIBRARY_DIR)
          if [[ -n "${value}" ]]; then
            LIBRARY_DIR="${value}"
          fi
          ;;
        STAGING_DIR)
          if [[ -n "${value}" ]]; then
            STAGING_DIR="${value}"
          fi
          ;;
        STATE_DIR)
          if [[ -n "${value}" ]]; then
            STATE_DIR="${value}"
          fi
          ;;
        *)
          config_error "unknown config key" "line=${line_num}" "key=${key}"
          return 1
          ;;
      esac
    done < "${CONFIG_PATH}"
  fi

  LIBRARY_DIR="$(resolve_path "${config_dir}" "${LIBRARY_DIR}")"
  STAGING_DIR="$(resolve_path "${config_dir}" "${STAGING_DIR}")"
  STATE_DIR="$(resolve_path "${config_dir}" "${STATE_DIR}")"

  ensure_dir "${LIBRARY_DIR}" "LIBRARY_DIR" || return 1
  ensure_dir "${STAGING_DIR}" "STAGING_DIR" || return 1
  ensure_dir "${STATE_DIR}" "STATE_DIR" || return 1

  LIBRARY_DIR="$(cd "${LIBRARY_DIR}" && pwd -P)"
  STAGING_DIR="$(cd "${STAGING_DIR}" && pwd -P)"
  STATE_DIR="$(cd "${STATE_DIR}" && pwd -P)"

  if [[ "${LIBRARY_DIR}" == "${STAGING_DIR}" || "${LIBRARY_DIR}" == "${STATE_DIR}" || "${STAGING_DIR}" == "${STATE_DIR}" ]]; then
    config_error "configured paths must be distinct" \
      "library_dir=${LIBRARY_DIR}" "staging_dir=${STAGING_DIR}" "state_dir=${STATE_DIR}"
    return 1
  fi
}

load_inputs() {
  load_subscriptions || return 1
  load_config || return 1
}
