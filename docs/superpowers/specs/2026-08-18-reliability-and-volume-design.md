# HomeWave Reliability and Volume Design

## Goal

Improve the released HomeWave add-on with actionable startup health status, an
optional quieter AirPlay volume curve, and focused troubleshooting guidance.
Keep the Shairport Sync image version unchanged in this release.

## Scope

This work is developed on `dev`. Before implementation, `dev` is synchronised
with the released `main` branch so that it contains HomeWave 0.1.3, including
the direct service startup, stable default audio profile, 60 dB volume range,
and compact default logs.

The release contains the following changes:

- Add a `volume_curve` option with `balanced` as the default and `quiet_start`
  as the opt-in alternative.
- Make startup emit short, actionable readiness or failure messages for the
  PulseAudio socket, D-Bus, Avahi, and `nqptp`.
- Expand the English and Russian add-on documentation with troubleshooting for
  discovery, output, dropouts, volume, and diagnostics.
- Bump the add-on version, test the changes automatically, and run the existing
  real-device acceptance checklist before releasing to `main`.

Updating the Shairport Sync base image is explicitly out of scope. It is a
separate future project because it changes AirPlay and audio runtime behaviour
across all supported architectures.

## Volume Curves

`balanced` preserves the existing Shairport Sync settings:

- `volume_control_profile = "flat"`
- `volume_range_db = 60`
- `volume_max_db = 0.0`

`quiet_start` retains the 0 dB ceiling and per-stream-only volume ownership,
but uses a 90 dB attenuation range instead of 60 dB. Its purpose is to make
the lowest AirPlay slider positions perceptibly quieter without changing the
Home Assistant sink volume. Shairport Sync documents an allowed range of 30 to
150 dB, so both curves remain within its supported configuration.

The setting is validated before Shairport Sync is started. Invalid values fail
with an explicit `volume_curve` error. Existing installations that do not yet
contain the field use `balanced`; Home Assistant UI installations receive this
as the manifest default.

## Startup Health Status

The existing audio-socket check remains the authoritative guard: HomeWave must
not fall back to ALSA or start without Home Assistant PulseAudio. It will emit
a concise message that distinguishes an unavailable socket from a usable one.

The main startup script owns the remaining checks. It starts D-Bus, Avahi, and
`nqptp` in the established direct-start model and confirms each prerequisite
before executing Shairport Sync. Each success emits one compact `HomeWave:`
status line; each failure exits nonzero with the component name and an action
the user can take. The normal path must not enable Shairport diagnostics or
periodic statistics.

Health status is startup-only. It does not add a background supervisor, expose
a network endpoint, or change Home Assistant audio routing.

## Documentation

The add-on READMEs gain a troubleshooting section with these symptom-to-action
mappings:

| Symptom | Primary action |
| --- | --- |
| Receiver is absent from the AirPlay list | Ensure only one receiver is running, then restart HomeWave and check the Avahi readiness line. |
| Receiver is visible but silent | Verify the Home Assistant audio-device selector and the PulseAudio readiness line. |
| Playback clicks or drops out | Use `stable`; enable diagnostics only while collecting evidence. |
| Lowest volume is too loud | Select `quiet_start`; retain `balanced` when the present response is preferred. |
| Support investigation | Enable diagnostics temporarily, remove private device names from shared logs, then disable it again. |

English remains the primary documentation. The intentionally localised
`README.ru.md` and `translations/ru.yaml` retain equivalent Russian wording.

## Testing and Acceptance

Automated Bats tests cover the manifest defaults and allowed curves, rendered
Shairport configuration for both curves, unknown-curve rejection, socket
success/failure messaging, service readiness/failure behaviour, and compact
normal diagnostics. The container smoke test verifies the image still uses the
explicit `/run.sh` entrypoint and does not start inherited SSH, SFTP, syslog,
or s6 services.

Before release, run yamllint, ShellCheck, all Bats tests, and the container
smoke test. Real-device acceptance checks stable playback with both volume
curves, confirms quiet low-end control, and records whether discovery, audio,
and diagnostics work as described. A release cannot claim playback stability
until the automated checks and this real-device checklist pass.
