#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

CONFIG_PATH="${CONFIG_PATH:-/data/options.json}"
OUTPUT_CONFIG="${OUTPUT_CONFIG:-/run/shairport-sync.conf}"
SHAIRPORT_SYNC_BIN="${SHAIRPORT_SYNC_BIN:-shairport-sync}"
AVAHI_PID_PATH="${AVAHI_PID_PATH:-/var/run/avahi-daemon/pid}"
AUDIO_CHECK_PATH="${AUDIO_CHECK_PATH:-/etc/cont-init.d/10-audio-check.sh}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_PATH="${TEMPLATE_PATH:-${SCRIPT_DIR}/shairport-sync.conf.tpl}"

fail() {
  echo "HomeWave: $*" >&2
  exit 1
}

read_option() {
  local query="$1"
  local value
  value="$(jq -er "$query | if . == false then \"false\" else . end" "$CONFIG_PATH" 2>/dev/null)" || fail "cannot read option $query"
  [[ -n "$value" && "$value" != null ]] || fail "cannot read option $query"
  printf '%s' "$value"
}

is_number_in_range() {
  local value="$1"
  local lower="$2"
  local upper="$3"
  awk -v value="$value" -v lower="$lower" -v upper="$upper" \
    'BEGIN { exit !(value ~ /^-?([0-9]+)(\.[0-9]+)?$/ && value >= lower && value <= upper) }'
}

escape_for_sed() {
  sed 's/[\\/&]/\\&/g'
}

buffer_for_profile() {
  local profile="$1"
  local custom_value="$2"

  case "$profile" in
    minimal) printf '0.10' ;;
    standard) printf '0.15' ;;
    stable) printf '0.30' ;;
    custom)
      is_number_in_range "$custom_value" 0.08 0.50 || \
        fail "custom_buffer_seconds must be between 0.08 and 0.50"
      printf '%s' "$custom_value"
      ;;
    *) fail "audio_profile must be minimal, standard, stable, or custom" ;;
  esac
}

start_required_services() {
  dbus-daemon --system --fork
  avahi-daemon --no-chroot --daemonize
  nqptp &
}

main() {
  [[ -r "$CONFIG_PATH" ]] || fail "options file is unavailable"
  [[ -r "$TEMPLATE_PATH" ]] || fail "configuration template is unavailable"
  if [[ -x "$AUDIO_CHECK_PATH" ]]; then
    "$AUDIO_CHECK_PATH"
  fi

  local airplay_name profile custom_buffer offset interpolation volume diagnostics buffer
  airplay_name="$(read_option '.airplay_name')"
  profile="$(read_option '.audio_profile')"
  custom_buffer="$(read_option '.custom_buffer_seconds')"
  offset="$(read_option '.offset_seconds')"
  interpolation="$(read_option '.interpolation')"
  volume="$(read_option '.default_airplay_volume')"
  diagnostics="$(read_option '.diagnostics')"

  [[ -n "$airplay_name" ]] || fail "airplay_name must not be empty"
  [[ "$interpolation" =~ ^(auto|basic|soxr)$ ]] || fail "interpolation is invalid"
  is_number_in_range "$offset" -2 2 || fail "offset_seconds must be between -2 and 2"
  is_number_in_range "$volume" -30 0 || fail "default_airplay_volume must be between -30 and 0"
  [[ "$diagnostics" == true || "$diagnostics" == false ]] || fail "diagnostics must be a boolean"
  buffer="$(buffer_for_profile "$profile" "$custom_buffer")"

  local diagnostics_file rendered_file
  diagnostics_file="$(mktemp)"
  rendered_file="$(mktemp)"
  trap 'rm -f "$diagnostics_file" "$rendered_file"' EXIT

  if [[ "$diagnostics" == true ]]; then
    printf '  log_output_to = "stdout";\n  statistics = "yes";\n  log_verbosity = 2;\n' >"$diagnostics_file"
  else
    printf '  log_output_to = "stdout";\n  statistics = "no";\n  log_verbosity = 1;\n' >"$diagnostics_file"
  fi

  sed '/@@DIAGNOSTICS@@/r '"$diagnostics_file"$'\n/@@DIAGNOSTICS@@/d' "$TEMPLATE_PATH" |
    sed \
      -e 's/@@AIRPLAY_NAME@@/'"$(printf '%s' "$airplay_name" | escape_for_sed)"'/g' \
      -e 's/@@INTERPOLATION@@/'"$(printf '%s' "$interpolation" | escape_for_sed)"'/g' \
      -e 's/@@DEFAULT_AIRPLAY_VOLUME@@/'"$(printf '%s' "$volume" | escape_for_sed)"'/g' \
      -e 's/@@BUFFER_SECONDS@@/'"$(printf '%s' "$buffer" | escape_for_sed)"'/g' \
      -e 's/@@OFFSET_SECONDS@@/'"$(printf '%s' "$offset" | escape_for_sed)"'/g' >"$rendered_file"

  install -Dm644 "$rendered_file" "$OUTPUT_CONFIG"
  if [[ "${START_REQUIRED_SERVICES:-true}" == true ]]; then
    start_required_services
    until [[ -f "$AVAHI_PID_PATH" ]]; do
      echo "HomeWave: waiting for Avahi"
      sleep 1
    done
  fi
  exec "$SHAIRPORT_SYNC_BIN" -c "$OUTPUT_CONFIG"
}

main "$@"
