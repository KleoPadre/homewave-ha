#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT_DIR
readonly IMAGE_TAG="homewave-airplay2-smoke:local"

docker build --tag "$IMAGE_TAG" "$ROOT_DIR/airplay2_lowlatency"

entrypoint="$(docker image inspect "$IMAGE_TAG" --format '{{json .Config.Entrypoint}}')"
[[ "$entrypoint" == '["/run.sh"]' ]]

version="$(docker run --rm --entrypoint shairport-sync "$IMAGE_TAG" -V)"
[[ "$version" == *4.3.7* ]]
[[ "$version" == *AirPlay2* ]]
[[ "$version" == *PA* ]]
[[ "$version" == *soxr* ]]

[[ "$version" == *nqptp* ]]

set +e
startup_output="$(docker run --rm "$IMAGE_TAG" 2>&1)"
startup_status=$?
set -e

[[ $startup_status -ne 0 ]]
[[ "$startup_output" == *"HomeWave: Home Assistant PulseAudio socket is unavailable."* ]]
[[ "$startup_output" != *"s6-rc:"* ]]
[[ "$startup_output" != *"s6-socklog:"* ]]
[[ "$startup_output" != *"ssh.service"* ]]
