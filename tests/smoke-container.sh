#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT_DIR
readonly IMAGE_TAG="homewave-airplay2-smoke:local"

docker build --tag "$IMAGE_TAG" "$ROOT_DIR/airplay2_lowlatency"

version="$(docker run --rm --entrypoint shairport-sync "$IMAGE_TAG" -V)"
[[ "$version" == *AirPlay2* ]]
[[ "$version" == *PA* ]]
[[ "$version" == *nqptp* ]]
[[ "$version" == *soxr* ]]

set +e
startup_output="$(docker run --rm "$IMAGE_TAG" 2>&1)"
startup_status=$?
set -e

[[ $startup_status -ne 0 ]]
[[ "$startup_output" == *"Home Assistant PulseAudio socket is unavailable."* ]]
