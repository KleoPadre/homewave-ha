#!/usr/bin/env bash

set -euo pipefail

PULSE_SOCKET_PATH="${PULSE_SOCKET_PATH:-/run/audio/pulse.sock}"

if [[ ! -S "$PULSE_SOCKET_PATH" ]]; then
  echo "HomeWave: Home Assistant PulseAudio socket is unavailable." >&2
  exit 1
fi

echo "HomeWave: PulseAudio socket is ready"
