# HomeWave AirPlay 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` task-by-task. Track work with the checkboxes below.

**Goal:** Deliver a multi-architecture Home Assistant AirPlay 2 add-on with native PulseAudio output, safe configuration, and reproducible audio acceptance tests.

**Architecture:** Keep JohannVR's add-on/image foundation while replacing its startup path with a validated shell renderer. Shairport Sync outputs only through Home Assistant PulseAudio; Home Assistant's native audio-device selector chooses the output device.

**Tech stack:** Home Assistant Add-on, Docker/Alpine, Shairport Sync 4.3.7, `nqptp`, PulseAudio, POSIX shell, `jq`, `envsubst`, Bats, ShellCheck, yamllint, GitHub Actions.

## Global Constraints

- Support `amd64`, `aarch64`, and `armv7`.
- Use only `output_backend = "pa"`; never expose ALSA output settings.
- Defaults: receiver `HomeWave`, profile `standard`, buffer `0.15`, AirPlay volume `-24.0 dB`.
- Profiles: `minimal=0.10`, `standard=0.15`, `stable=0.30`, and `custom=0.08…0.50` seconds.
- Use the flat 30 dB Shairport volume curve with a `0.0 dB` ceiling and no loudness, convolution, normalization, or gain.
- Set `allow_session_interruption = "yes"`.
- Exclude MQTT from 0.1.0.
- Keep the primary README and all source/configuration/CI text in English; provide Russian UI translations and `README.ru.md`.

---

### Task 1: Add-on manifest and translations

**Files:** Create `repository.yaml`, `airplay2_lowlatency/config.yaml`, `airplay2_lowlatency/translations/en.yaml`, `airplay2_lowlatency/translations/ru.yaml`, `tests/config-schema.bats`.

- [ ] Write the failing Bats tests asserting `audio: true`, `host_network: true`, architectures `[aarch64, amd64, armv7]`, and no MQTT or ALSA options.
- [ ] Run `bats tests/config-schema.bats`; expect failure because the manifest does not exist.
- [ ] Create `config.yaml` with slug `airplay2_lowlatency`, version `0.1.0`, and options `airplay_name`, `audio_profile`, `custom_buffer_seconds`, `offset_seconds`, `interpolation`, `default_airplay_volume`, and `diagnostics`.
- [ ] Use schema restrictions: `audio_profile: list(minimal|standard|stable|custom)`, `custom_buffer_seconds: float(0.08,0.50)`, `default_airplay_volume: float(-30,0)`, `diagnostics: bool`.
- [ ] Add English and Russian descriptions of each option, especially the click risk for `minimal` and the higher latency of `stable`.
- [ ] Run `bats tests/config-schema.bats`; expect PASS.
- [ ] Commit: `feat: add HomeWave add-on manifest`.

### Task 2: Safe configuration renderer

**Files:** Create `airplay2_lowlatency/start-addon.sh`, `airplay2_lowlatency/shairport-sync.conf.tpl`, `tests/start-addon.bats`.

- [ ] Write failing tests for all four profiles, invalid custom values `0`, `0.07`, `0.51`, and `abc`, a PA backend, a flat volume profile, and diagnostics on/off.
- [ ] Run `bats tests/start-addon.bats`; expect failure because the script does not exist.
- [ ] Implement `buffer_for_profile(profile, custom_value)` returning exactly `0.10`, `0.15`, `0.30`, or a number within `0.08…0.50`.
- [ ] Read each field using `jq -er`; use neither `eval` nor bulk environment export. Escape backslashes and double quotes before inserting the receiver name into the template.
- [ ] Render `output_backend = "pa"`, `pulseaudio.server = "unix:///run/audio/pulse.sock"`, `volume_control_profile = "flat"`, `volume_range_db = 30`, `volume_max_db = 0.0`, `default_airplay_volume`, and `allow_session_interruption = "yes"`.
- [ ] Render `log_output_to = "stdout"`, `statistics = "yes"`, and `log_verbosity = 2` only when diagnostics is enabled.
- [ ] Run `shellcheck airplay2_lowlatency/start-addon.sh && bats tests/start-addon.bats`; expect PASS.
- [ ] Commit: `feat: add safe AirPlay configuration renderer`.

### Task 3: Container and audio-socket validation

**Files:** Create `airplay2_lowlatency/Dockerfile`, `airplay2_lowlatency/rootfs/etc/cont-init.d/10-audio-check.sh`, `tests/smoke-container.sh`.

- [ ] Write a failing smoke test that builds the image, checks `shairport-sync -V` for AirPlay2, PulseAudio, `nqptp`, and `soxr`, and confirms startup fails without `/run/audio/pulse.sock`.
- [ ] Base the Dockerfile on `mikebrady/shairport-sync:4.3.7`; install only `jq` and `gettext`; copy the renderer, template, and init check.
- [ ] Make `10-audio-check.sh` exit nonzero with `Home Assistant PulseAudio socket is unavailable.` when the path is not a Unix socket.
- [ ] Keep the image s6 services and syslog configuration intact; do not copy JohannVR's service removal.
- [ ] Run `tests/smoke-container.sh` on amd64; expect PASS.
- [ ] Commit: `feat: add native PulseAudio container output`.

### Task 4: Documentation and manual acceptance

**Files:** Create `airplay2_lowlatency/README.md`, `airplay2_lowlatency/README.ru.md`, `airplay2_lowlatency/CHANGELOG.md`, `tests/acceptance-checklist.md`.

- [ ] In both READMEs, document every active setting with its allowed values, default, effect, and safe correction path.
- [ ] Document the built-in Home Assistant audio-device selector, migration from JohannVR/v3rm0n, diagnostics, rollback, the absence of MQTT in 0.1.0, and the prohibition on running two AirPlay receivers at once.
- [ ] Create a checklist for ten-minute playback from iPhone, Mac, and Apple TV; immediate source takeover; `-30…0 dB` volume stepping; no clicks; no underrun/overrun; and under-0.5-second stopping on `standard`.
- [ ] Run `rg -n '192\\.168\\.|password' airplay2_lowlatency/README.md airplay2_lowlatency/README.ru.md`; remove any real address or credential.
- [ ] Commit: `docs: add setup and acceptance documentation`.

### Task 5: CI and multi-architecture builds

**Files:** Create `.github/workflows/validate.yml`, `.github/workflows/build.yml`.

- [ ] Add `validate.yml` to install and run yamllint, ShellCheck, and Bats for every push and pull request.
- [ ] Add `build.yml` to run only after validation succeeds, initialise QEMU/Buildx, and build `linux/amd64`, `linux/arm64`, and `linux/arm/v7` images.
- [ ] Run `yamllint .github/workflows/validate.yml .github/workflows/build.yml`; expect PASS.
- [ ] Commit: `ci: add validation and multi-architecture builds`.

### Task 6: Real-device release acceptance

**Files:** Modify `tests/acceptance-checklist.md`, `airplay2_lowlatency/CHANGELOG.md`.

- [ ] Run `yamllint`, ShellCheck, Bats, and `tests/smoke-container.sh`; all commands must return zero.
- [ ] On Home Assistant OS, stop `907c2594_shairport_sync` before starting HomeWave and verify that `HomeWave` is the only visible receiver.
- [ ] Complete the checklist with the exact profile, source, duration, click/crackle result, stop time, takeover result, and diagnostics outcome.
- [ ] If `standard` clicks, repeat with `stable`, preserve a sanitized diagnostic excerpt, and record `stable` as the recommendation; do not reduce the buffer without diagnostic evidence.
- [ ] Update CHANGELOG with the accepted profile and results, then commit: `test: record AirPlay 2 acceptance results`.

## Plan Review

Tasks 1–6 cover all specified architecture, output, latency, volume, takeover, safety, documentation, CI, and real-audio requirements. Configuration names are consistent across the manifest, renderer, tests, and documentation.
