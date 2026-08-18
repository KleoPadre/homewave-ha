# HomeWave Reliability and Volume Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add concise startup health status, an optional quiet-start volume curve, and actionable troubleshooting documentation to HomeWave.

**Architecture:** Synchronise `dev` with the released 0.1.3 code first. The Bash renderer remains the sole translator from add-on options to Shairport Sync configuration and retains direct ownership of D-Bus, Avahi, and `nqptp`; the audio-socket guard remains a separate focused script.

**Tech Stack:** Home Assistant add-on YAML, Bash, Shairport Sync 4.3.7, PulseAudio, Avahi, D-Bus, `nqptp`, Bats, ShellCheck, yamllint, Docker.

## Global Constraints

- Work on `dev` until real-device acceptance is complete; then promote only release files to `main`.
- Support `amd64`, `aarch64`, and `armv7`.
- Keep `mikebrady/shairport-sync:4.3.7`; an image upgrade is out of scope.
- Use only `output_backend = "pa"`; never add an ALSA fallback or option.
- Keep `audio_profile: stable` and `diagnostics: false` as defaults.
- Add `volume_curve: balanced|quiet_start`, default `balanced`.
- Render `balanced` as `flat` / 60 dB and `quiet_start` as `flat` / 90 dB, retaining a 0.0 dB ceiling.
- Keep normal logs at verbosity 1, with statistics disabled.
- Do not commit secrets, real network addresses, or `/data/options.json`.
- English is primary; Russian text is restricted to `README.ru.md` and `translations/ru.yaml`.

---

### Task 1: Synchronise the released baseline into `dev`

**Files:**

- Modify: released product files imported from `main`.
- Preserve: `docs/superpowers/specs/` and `docs/superpowers/plans/`.
- Test: `tests/config-schema.bats`, `tests/start-addon.bats`, `tests/smoke-container.sh`.

**Interfaces:**

- Consumes: the 0.1.3 release on `main`.
- Produces: a `dev` branch with 0.1.3 runtime code and all existing planning files.

- [ ] **Step 1: Inspect divergence**

```bash
git switch dev
git status --short --branch
git log --oneline --left-right dev...main
```

Expected: a clean working tree and the 0.1.1–0.1.3 production commits present only on `main`.

- [ ] **Step 2: Merge `main`**

```bash
git merge main --no-edit
```

If a conflict occurs, take the released version of product files and retain only the planning paths from `dev`:

```bash
git checkout --theirs -- README.md airplay2_lowlatency tests .github
git add README.md airplay2_lowlatency tests .github docs/superpowers
git commit
```

- [ ] **Step 3: Verify and push the baseline**

```bash
yamllint .
shellcheck airplay2_lowlatency/start-addon.sh airplay2_lowlatency/rootfs/etc/cont-init.d/10-audio-check.sh
bats tests/config-schema.bats tests/start-addon.bats
tests/smoke-container.sh
git push origin dev
```

Expected: all checks pass; `config.yaml` has version `0.1.3`, stable audio, and compact diagnostics.

### Task 2: Add the volume-curve contract

**Files:**

- Modify: `airplay2_lowlatency/config.yaml`.
- Modify: `airplay2_lowlatency/translations/en.yaml`.
- Modify: `airplay2_lowlatency/translations/ru.yaml`.
- Modify: `airplay2_lowlatency/shairport-sync.conf.tpl`.
- Modify: `airplay2_lowlatency/start-addon.sh`.
- Modify: `tests/config-schema.bats`.
- Modify: `tests/start-addon.bats`.

**Interfaces:**

- Consumes: JSON option `.volume_curve` set to `balanced` or `quiet_start`.
- Produces: `volume_settings_for_curve(curve)`, printing exactly `flat 60` or `flat 90`, and template placeholders `@@VOLUME_CONTROL_PROFILE@@` / `@@VOLUME_RANGE_DB@@`.

- [ ] **Step 1: Write the failing manifest test**

Add this Bats test to `tests/config-schema.bats`:

```bash
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
```

- [ ] **Step 2: Write failing rendered-config tests**

Extend `write_options` in `tests/start-addon.bats` with a fourth `volume_curve` argument and JSON property. Add:

```bash
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
```

- [ ] **Step 3: Confirm red**

```bash
bats tests/config-schema.bats tests/start-addon.bats
```

Expected: new tests fail because neither the option nor the dynamic template values exist.

- [ ] **Step 4: Declare and localise the option**

Set the release version to `0.1.4` and add:

```yaml
options:
  volume_curve: balanced
schema:
  volume_curve: list(balanced|quiet_start)
```

Add translations stating that `balanced` preserves the existing 60 dB response and `quiet_start` uses 90 dB to make the bottom of the AirPlay slider quieter.

- [ ] **Step 5: Implement curve validation and rendering**

Add this function after `buffer_for_profile`:

```bash
volume_settings_for_curve() {
  case "$1" in
    balanced) printf 'flat 60' ;;
    quiet_start) printf 'flat 90' ;;
    *) fail "volume_curve must be balanced or quiet_start" ;;
  esac
}
```

Read `.volume_curve` through `read_option`; split the pair into `volume_profile` and `volume_range`. Replace hard-coded template values with:

```conf
  volume_control_profile = "@@VOLUME_CONTROL_PROFILE@@";
  volume_range_db = @@VOLUME_RANGE_DB@@;
```

Add matching substitutions to the existing `sed` renderer:

```bash
-e 's/@@VOLUME_CONTROL_PROFILE@@/'"$(printf '%s' "$volume_profile" | escape_for_sed)"'/g' \
-e 's/@@VOLUME_RANGE_DB@@/'"$(printf '%s' "$volume_range" | escape_for_sed)"'/g' \
```

- [ ] **Step 6: Verify green and commit**

```bash
shellcheck airplay2_lowlatency/start-addon.sh
bats tests/config-schema.bats tests/start-addon.bats
git add airplay2_lowlatency/config.yaml airplay2_lowlatency/translations airplay2_lowlatency/shairport-sync.conf.tpl airplay2_lowlatency/start-addon.sh tests/config-schema.bats tests/start-addon.bats
git commit -m "feat: add selectable volume curve"
```

Expected: both curve configurations render, and invalid input is rejected.

### Task 3: Add concise startup health checks

**Files:**

- Modify: `airplay2_lowlatency/rootfs/etc/cont-init.d/10-audio-check.sh`.
- Modify: `airplay2_lowlatency/start-addon.sh`.
- Modify: `tests/start-addon.bats`.
- Modify: `tests/smoke-container.sh`.

**Interfaces:**

- Consumes: the PulseAudio Unix socket, `AVAHI_PID_PATH`, and the `dbus-daemon`, `avahi-daemon`, and `nqptp` executables.
- Produces: one `HomeWave: … is ready` line per prerequisite and a specific nonzero error for PulseAudio, D-Bus, Avahi, or `nqptp`.

- [ ] **Step 1: Write failing audio-socket readiness test**

Add to `tests/start-addon.bats`:

```bash
@test "audio check reports socket readiness" {
  socket_path="$BATS_TEST_TMPDIR/pulse.sock"
  ruby -rsocket -e 'UNIXServer.new(ARGV.fetch(0)); sleep 1' "$socket_path" &
  server_pid=$!

  run PULSE_SOCKET_PATH="$socket_path" bash "$BATS_TEST_DIRNAME/../airplay2_lowlatency/rootfs/etc/cont-init.d/10-audio-check.sh"
  kill "$server_pid"

  [ "$status" -eq 0 ]
  [[ "$output" == *"HomeWave: PulseAudio socket is ready"* ]]
}
```

- [ ] **Step 2: Write failing direct-service tests**

Create temporary executable stubs for `dbus-daemon`, `avahi-daemon`, and `nqptp`; prepend their directory to `PATH`. Test that a successful startup emits:

```text
HomeWave: D-Bus is ready
HomeWave: Avahi is ready
HomeWave: nqptp is ready
```

Create one D-Bus stub that exits 1 and one `nqptp` stub that exits immediately. Assert exact errors `HomeWave: D-Bus failed to start` and `HomeWave: nqptp failed to stay running`.

- [ ] **Step 3: Confirm red**

```bash
bats tests/start-addon.bats
```

Expected: the new tests fail because current scripts do not report readiness or validate the `nqptp` child.

- [ ] **Step 4: Implement the socket message**

Replace the hard-coded socket check with:

```bash
PULSE_SOCKET_PATH="${PULSE_SOCKET_PATH:-/run/audio/pulse.sock}"

if [[ ! -S "$PULSE_SOCKET_PATH" ]]; then
  echo "HomeWave: Home Assistant PulseAudio socket is unavailable." >&2
  exit 1
fi

echo "HomeWave: PulseAudio socket is ready"
```

No ALSA fallback may be added.

- [ ] **Step 5: Implement direct-service checks**

Replace `start_required_services` with helpers:

```bash
start_dbus() {
  dbus-daemon --system --fork || fail "D-Bus failed to start"
  echo "HomeWave: D-Bus is ready"
}

start_avahi() {
  avahi-daemon --no-chroot --daemonize || fail "Avahi failed to start"
  local attempts=0
  until [[ -f "$AVAHI_PID_PATH" ]]; do
    ((attempts += 1))
    ((attempts <= 20)) || fail "Avahi did not become ready"
    sleep 1
  done
  echo "HomeWave: Avahi is ready"
}

start_nqptp() {
  nqptp &
  local nqptp_pid=$!
  sleep 1
  kill -0 "$nqptp_pid" 2>/dev/null || fail "nqptp failed to stay running"
  echo "HomeWave: nqptp is ready"
}
```

Call these in order D-Bus, Avahi, `nqptp`. Keep `START_REQUIRED_SERVICES=false` as the existing test bypass.

- [ ] **Step 6: Verify green and commit**

```bash
shellcheck airplay2_lowlatency/start-addon.sh airplay2_lowlatency/rootfs/etc/cont-init.d/10-audio-check.sh
bats tests/start-addon.bats
tests/smoke-container.sh
git add airplay2_lowlatency/rootfs/etc/cont-init.d/10-audio-check.sh airplay2_lowlatency/start-addon.sh tests/start-addon.bats tests/smoke-container.sh
git commit -m "feat: report startup health status"
```

Expected: readiness is concise, errors name the component, and no inherited s6, syslog, SSH, or SFTP service returns.

### Task 4: Publish troubleshooting and acceptance guidance

**Files:**

- Modify: `README.md`.
- Modify: `airplay2_lowlatency/README.md`.
- Modify: `airplay2_lowlatency/README.ru.md`.
- Modify: `airplay2_lowlatency/CHANGELOG.md`.
- Modify: `tests/acceptance-checklist.md`.
- Modify: `tests/config-schema.bats`.

**Interfaces:**

- Consumes: `volume_curve` and the readiness messages from Task 3.
- Produces: safe symptom-to-action guidance without private data.

- [ ] **Step 1: Write the failing documentation test**

```bash
@test "English add-on documentation covers curves and health checks" {
  readme="$BATS_TEST_DIRNAME/../airplay2_lowlatency/README.md"
  run rg -F 'quiet_start' "$readme"
  [ "$status" -eq 0 ]
  run rg -F 'PulseAudio socket is ready' "$readme"
  [ "$status" -eq 0 ]
  run rg -F 'Avahi is ready' "$readme"
  [ "$status" -eq 0 ]
}
```

- [ ] **Step 2: Confirm red**

```bash
bats tests/config-schema.bats
```

Expected: the test fails before the README is updated.

- [ ] **Step 3: Document exact recovery actions**

Add a troubleshooting table to the root and add-on READMEs. It must cover: absent receiver → one receiver only plus Avahi readiness; visible but silent → HA audio-device selector plus PulseAudio readiness; dropouts → stable profile and temporary diagnostics; loud minimum → `quiet_start`; investigation → sanitise logs and turn diagnostics off afterwards.

Document `balanced` as 60 dB default and `quiet_start` as optional 90 dB. Update the Russian add-on README with equivalent text. Extend the acceptance checklist to test both curves at low, middle, and maximum source volume, confirm monotonicity, and confirm that Home Assistant sink volume does not move. Add a 0.1.4 changelog entry without calling playback stable before the checklist is complete.

- [ ] **Step 4: Verify green and commit**

```bash
bats tests/config-schema.bats
rg -n '192\\.168\\.|password|/data/options\\.json' README.md airplay2_lowlatency/README.md airplay2_lowlatency/README.ru.md tests/acceptance-checklist.md
git add README.md airplay2_lowlatency/README.md airplay2_lowlatency/README.ru.md airplay2_lowlatency/CHANGELOG.md tests/acceptance-checklist.md tests/config-schema.bats
git commit -m "docs: add troubleshooting guidance"
```

Expected: Bats passes and the `rg` command prints no sensitive material.

### Task 5: Verify and promote release 0.1.4

**Files:**

- Promote: Task 2–4 implementation commits from `dev` to `main`.
- Exclude: `docs/superpowers/` and all agent working material from `main`.

**Interfaces:**

- Consumes: automated green suite and real-device acceptance results.
- Produces: HomeWave 0.1.4 in `main`.

- [ ] **Step 1: Run complete automated verification**

```bash
yamllint .
shellcheck airplay2_lowlatency/start-addon.sh airplay2_lowlatency/rootfs/etc/cont-init.d/10-audio-check.sh
bats tests/config-schema.bats tests/start-addon.bats
tests/smoke-container.sh
```

Expected: every command exits 0.

- [ ] **Step 2: Complete real-device acceptance**

On Home Assistant OS: confirm one receiver is visible; confirm the three readiness lines; play from iPhone, Mac, and Apple TV with stable audio; test both curves at low/middle/max source volume; confirm `quiet_start` is quieter at the low end, steps are monotonic, and HA sink volume does not change; test takeover and ten-minute playback; disable diagnostics after any investigation. Do not copy private logs into Git.

- [ ] **Step 3: Review promotion scope**

```bash
git diff --name-only main..dev
git ls-tree -r --name-only dev | rg '^docs/superpowers/'
```

Expected: planning files remain on `dev` and are excluded from release.

- [ ] **Step 4: Promote only implementation commits**

```bash
git switch main
git pull --ff-only origin main
git switch -c release/homewave-0.1.4
git diff --binary main..dev -- . ':(exclude)docs/superpowers/**' | git apply --index
git commit -m "feat: improve reliability and volume controls"
git ls-tree -r --name-only HEAD | rg '^docs/superpowers/' && exit 1 || true
yamllint .
shellcheck airplay2_lowlatency/start-addon.sh airplay2_lowlatency/rootfs/etc/cont-init.d/10-audio-check.sh
bats tests/config-schema.bats tests/start-addon.bats
tests/smoke-container.sh
git switch main
git merge --ff-only release/homewave-0.1.4
```

- [ ] **Step 5: Inspect and push `main`**

```bash
git ls-tree -r --name-only main
git log main --format='%s'
git push origin main
```

Expected: `main` contains only distribution, test, CI, and documentation files, with concise English Conventional Commit subjects.

## Plan Review

Every approved requirement maps to a task: baseline synchronisation, explicit 60/90 dB curves, startup health status, troubleshooting, automated checks, and real-device acceptance. The Shairport Sync version upgrade is deliberately excluded.
