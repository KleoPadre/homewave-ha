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

@test "manifest defaults to the stable profile with compact diagnostics" {
  run ruby -e '
    require "yaml"
    config = YAML.load_file(ARGV.fetch(0))
    options = config.fetch("options")
    abort "stable profile must be the default" unless options.fetch("audio_profile") == "stable"
    abort "diagnostics must be disabled by default" unless options.fetch("diagnostics") == false
  ' "$BATS_TEST_DIRNAME/../airplay2_lowlatency/config.yaml"

  [ "$status" -eq 0 ]
}

@test "manifest defaults to a balanced volume curve" {
  run ruby -e '
    require "yaml"
    config = YAML.load_file(ARGV.fetch(0))
    options = config.fetch("options")
    abort "missing volume_curve" unless options.fetch("volume_curve") == "balanced"
    abort "invalid volume_curve schema" unless config.fetch("schema").fetch("volume_curve") == "list(balanced|quiet_start)"
  ' "$BATS_TEST_DIRNAME/../airplay2_lowlatency/config.yaml"

  [ "$status" -eq 0 ]
}

@test "English add-on documentation covers curves and health checks" {
  readme="$BATS_TEST_DIRNAME/../airplay2_lowlatency/README.md"
  run rg -F 'quiet_start' "$readme"
  [ "$status" -eq 0 ]
  run rg -F 'PulseAudio socket is ready' "$readme"
  [ "$status" -eq 0 ]
  run rg -F 'Avahi is ready' "$readme"
  [ "$status" -eq 0 ]
}

@test "repository documentation is English-only outside Home Assistant localisations" {
  [ ! -f "$BATS_TEST_DIRNAME/../airplay2_lowlatency/README.ru.md" ]
}
