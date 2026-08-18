#!/usr/bin/env bash

set -euo pipefail

if [[ ! -S /run/audio/pulse.sock ]]; then
  echo "Home Assistant PulseAudio socket is unavailable." >&2
  exit 1
fi
