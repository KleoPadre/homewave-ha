#!/usr/bin/env bats

setup() {
  export CONFIG_PATH="$BATS_TEST_TMPDIR/options.json"
  export OUTPUT_CONFIG="$BATS_TEST_TMPDIR/shairport-sync.conf"
  export SHAIRPORT_SYNC_BIN=true
  export WAIT_FOR_AVAHI=false
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
  "diagnostics": $3
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
    write_options "$profile" 0.12 false

    run bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/start-addon.sh"

    [ "$status" -eq 0 ]
    grep -F "audio_backend_buffer_desired_length_in_seconds = $buffer;" "$OUTPUT_CONFIG"
  done
}

@test "uses a bounded custom buffer" {
  write_options custom 0.08 false

  run bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/start-addon.sh"

  [ "$status" -eq 0 ]
  grep -F 'audio_backend_buffer_desired_length_in_seconds = 0.08;' "$OUTPUT_CONFIG"
}

@test "rejects invalid custom buffers" {
  local value
  for value in 0 0.07 0.51 '"abc"'; do
    write_options custom "$value" false

    run bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/start-addon.sh"

    [ "$status" -ne 0 ]
    [[ "$output" == *"custom_buffer_seconds must be between 0.08 and 0.50"* ]]
  done
}

@test "renders native PulseAudio and flat volume controls" {
  write_options standard 0.15 false

  run bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/start-addon.sh"

  [ "$status" -eq 0 ]
  grep -F 'output_backend = "pa";' "$OUTPUT_CONFIG"
  grep -F 'server = "unix:///run/audio/pulse.sock";' "$OUTPUT_CONFIG"
  grep -F 'volume_control_profile = "flat";' "$OUTPUT_CONFIG"
  grep -F 'volume_range_db = 30;' "$OUTPUT_CONFIG"
  grep -F 'volume_max_db = 0.0;' "$OUTPUT_CONFIG"
  grep -F 'default_airplay_volume = -24.0;' "$OUTPUT_CONFIG"
  grep -F 'allow_session_interruption = "yes";' "$OUTPUT_CONFIG"
}

@test "adds diagnostics only when enabled" {
  write_options standard 0.15 true

  run bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/start-addon.sh"

  [ "$status" -eq 0 ]
  grep -F 'log_output_to = "stdout";' "$OUTPUT_CONFIG"
  grep -F 'statistics = "yes";' "$OUTPUT_CONFIG"
  grep -F 'log_verbosity = 2;' "$OUTPUT_CONFIG"

  write_options standard 0.15 false
  run bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/start-addon.sh"

  [ "$status" -eq 0 ]
  ! grep -q 'statistics' "$OUTPUT_CONFIG"
}
