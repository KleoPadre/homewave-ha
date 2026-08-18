#!/usr/bin/env bats

@test "manifest enables Home Assistant audio and host networking" {
  run ruby -e '
    require "yaml"
    config = YAML.load_file(ARGV.fetch(0))
    abort "audio must be true" unless config["audio"] == true
    abort "host_network must be true" unless config["host_network"] == true
  ' "$BATS_TEST_DIRNAME/../airplay2_lowlatency/config.yaml"

  [ "$status" -eq 0 ]
}

@test "manifest declares all supported architectures" {
  run ruby -e '
    require "yaml"
    config = YAML.load_file(ARGV.fetch(0))
    expected = %w[aarch64 amd64 armv7]
    abort "unexpected architectures" unless config.fetch("arch").sort == expected
  ' "$BATS_TEST_DIRNAME/../airplay2_lowlatency/config.yaml"

  [ "$status" -eq 0 ]
}

@test "manifest exposes only native PulseAudio audio controls" {
  run ruby -e '
    require "yaml"
    config = YAML.load_file(ARGV.fetch(0))
    keys = config.fetch("options").keys
    forbidden = keys.grep(/alsa|mqtt/i)
    abort "forbidden options: #{forbidden.join(", ")}" unless forbidden.empty?
  ' "$BATS_TEST_DIRNAME/../airplay2_lowlatency/config.yaml"

  [ "$status" -eq 0 ]
}
