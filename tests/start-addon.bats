#!/usr/bin/env bats

setup() {
  export CONFIG_PATH="$BATS_TEST_TMPDIR/options.json"
  export OUTPUT_CONFIG="$BATS_TEST_TMPDIR/shairport-sync.conf"
  export SHAIRPORT_SYNC_BIN=true
  export WAIT_FOR_AVAHI=false
  export START_REQUIRED_SERVICES=false
}

write_options() {
  cat >"$CONFIG_PATH" <<EOF
{
  "airplay_name": "Kitchen \"Speaker\"",
  "audio_profile": "$1",
  "custom_buffer_seconds": $2,
  "offset_seconds": 0.0,
  "interpolation": "auto",
  "default_airplay_volume": -24.0,
  "diagnostics": $3,
  "volume_curve": "$4"
}
EOF
}

@test "renders each built-in latency profile with its intended buffer" {
  local profile buffer
  for profile in minimal standard stable; do
    case "$profile" in
      minimal) buffer=0.10 ;;
      standard) buffer=0.15 ;;
      stable) buffer=0.30 ;;
    esac
    write_options "$profile" 0.12 false balanced

    run bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/start-addon.sh"

    [ "$status" -eq 0 ]
    grep -F "audio_backend_buffer_desired_length_in_seconds = $buffer;" "$OUTPUT_CONFIG"
  done
}

@test "uses a bounded custom buffer" {
  write_options custom 0.08 false balanced

  run bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/start-addon.sh"

  [ "$status" -eq 0 ]
  grep -F 'audio_backend_buffer_desired_length_in_seconds = 0.08;' "$OUTPUT_CONFIG"
}

@test "rejects invalid custom buffers" {
  local value
  for value in 0 0.07 0.51 '"abc"'; do
    write_options custom "$value" false balanced

    run bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/start-addon.sh"

    [ "$status" -ne 0 ]
    [[ "$output" == *"custom_buffer_seconds must be between 0.08 and 0.50"* ]]
  done
}

@test "renders the Shairport Sync 5 PulseAudio backend and flat volume controls" {
  write_options standard 0.15 false balanced

  run bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/start-addon.sh"

  [ "$status" -eq 0 ]
  grep -F 'output_backend = "pulseaudio";' "$OUTPUT_CONFIG"
  grep -F 'pulseaudio =' "$OUTPUT_CONFIG"
  grep -F 'server = "unix:///run/audio/pulse.sock";' "$OUTPUT_CONFIG"
  grep -F 'volume_control_profile = "flat";' "$OUTPUT_CONFIG"
  grep -F 'volume_range_db = 60;' "$OUTPUT_CONFIG"
  grep -F 'volume_max_db = 0.0;' "$OUTPUT_CONFIG"
  grep -F 'default_airplay_volume = -24.0;' "$OUTPUT_CONFIG"
  grep -F 'allow_session_interruption = "yes";' "$OUTPUT_CONFIG"
}

@test "adds diagnostics only when enabled" {
  write_options standard 0.15 true balanced

  run bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/start-addon.sh"

  [ "$status" -eq 0 ]
  run grep -F 'log_output_to = "stdout";' "$OUTPUT_CONFIG"
  [ "$status" -ne 0 ]
  grep -F 'statistics = "yes";' "$OUTPUT_CONFIG"
  grep -F 'log_verbosity = 2;' "$OUTPUT_CONFIG"

  write_options standard 0.15 false balanced
  run bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/start-addon.sh"

  [ "$status" -eq 0 ]
  run grep -F 'log_output_to = "stdout";' "$OUTPUT_CONFIG"
  [ "$status" -ne 0 ]
  grep -F 'statistics = "no";' "$OUTPUT_CONFIG"
  grep -F 'log_verbosity = 1;' "$OUTPUT_CONFIG"
}

@test "renders the selected volume curve and rejects invalid values" {
  write_options standard 0.15 false balanced
  run bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/start-addon.sh"
  [ "$status" -eq 0 ]
  grep -F 'volume_control_profile = "flat";' "$OUTPUT_CONFIG"
  grep -F 'volume_range_db = 60;' "$OUTPUT_CONFIG"

  write_options standard 0.15 false quiet_start
  run bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/start-addon.sh"
  [ "$status" -eq 0 ]
  grep -F 'volume_range_db = 90;' "$OUTPUT_CONFIG"

  write_options standard 0.15 false invalid
  run bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/start-addon.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"volume_curve must be balanced or quiet_start"* ]]
}

@test "audio check reports socket readiness" {
  socket_path="$BATS_TEST_TMPDIR/pulse.sock"
  ruby -rsocket -e 'UNIXServer.new(ARGV.fetch(0)); sleep 1' "$socket_path" &
  server_pid=$!
  for _ in {1..20}; do
    [[ -S "$socket_path" ]] && break
    sleep 0.05
  done
  [[ -S "$socket_path" ]]

  run env PULSE_SOCKET_PATH="$socket_path" bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/rootfs/etc/cont-init.d/10-audio-check.sh"
  kill "$server_pid"

  [ "$status" -eq 0 ]
  [[ "$output" == *"HomeWave: PulseAudio socket is ready"* ]]
}

@test "reports readiness after required services start" {
  local stub_dir="$BATS_TEST_TMPDIR/services"
  local avahi_pid_path="$BATS_TEST_TMPDIR/avahi/pid"
  mkdir -p "$stub_dir"

  printf '#!/usr/bin/env bash\nexit 0\n' >"$stub_dir/dbus-daemon"
  printf '#!/usr/bin/env bash\nmkdir -p "$(dirname "$AVAHI_PID_PATH")"\ntouch "$AVAHI_PID_PATH"\n' >"$stub_dir/avahi-daemon"
  printf '#!/usr/bin/env bash\nsleep 2\n' >"$stub_dir/nqptp"
  chmod +x "$stub_dir/dbus-daemon" "$stub_dir/avahi-daemon" "$stub_dir/nqptp"

  write_options standard 0.15 false balanced
  run env PATH="$stub_dir:$PATH" START_REQUIRED_SERVICES=true AVAHI_PID_PATH="$avahi_pid_path" \
    bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/start-addon.sh"

  [ "$status" -eq 0 ]
  [[ "$output" == *"HomeWave: D-Bus is ready"* ]]
  [[ "$output" == *"HomeWave: Avahi is ready"* ]]
  [[ "$output" == *"HomeWave: nqptp is ready"* ]]
}

@test "reports D-Bus startup failure" {
  local stub_dir="$BATS_TEST_TMPDIR/services"
  mkdir -p "$stub_dir"

  printf '#!/usr/bin/env bash\nexit 1\n' >"$stub_dir/dbus-daemon"
  chmod +x "$stub_dir/dbus-daemon"

  write_options standard 0.15 false balanced
  run env PATH="$stub_dir:$PATH" START_REQUIRED_SERVICES=true \
    bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/start-addon.sh"

  [ "$status" -ne 0 ]
  [[ "$output" == *"HomeWave: D-Bus failed to start"* ]]
}

@test "reports nqptp readiness failure" {
  local stub_dir="$BATS_TEST_TMPDIR/services"
  local avahi_pid_path="$BATS_TEST_TMPDIR/avahi/pid"
  mkdir -p "$stub_dir"

  printf '#!/usr/bin/env bash\nexit 0\n' >"$stub_dir/dbus-daemon"
  printf '#!/usr/bin/env bash\nmkdir -p "$(dirname "$AVAHI_PID_PATH")"\ntouch "$AVAHI_PID_PATH"\n' >"$stub_dir/avahi-daemon"
  printf '#!/usr/bin/env bash\nexit 0\n' >"$stub_dir/nqptp"
  chmod +x "$stub_dir/dbus-daemon" "$stub_dir/avahi-daemon" "$stub_dir/nqptp"

  write_options standard 0.15 false balanced
  run env PATH="$stub_dir:$PATH" START_REQUIRED_SERVICES=true AVAHI_PID_PATH="$avahi_pid_path" \
    bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/start-addon.sh"

  [ "$status" -ne 0 ]
  [[ "$output" == *"HomeWave: nqptp failed to stay running"* ]]
}
