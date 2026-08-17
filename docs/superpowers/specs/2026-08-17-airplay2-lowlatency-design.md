# HomeWave Stable AirPlay 2 Add-on Design

## Goal

Build a standalone Home Assistant OS add-on that receives AirPlay 2 audio from iPhone, iPad, Mac, and Apple TV, and plays it through Home Assistant's native PulseAudio service with low, predictable latency.

## Scope of 0.1.0

- Architectures: `amd64`, `aarch64`, and `armv7`.
- Default receiver name: `HomeWave`.
- The JohannVR Airplay2 add-on is the structural and image reference. Its unsafe `eval`-based startup script and service deletion are not reused.
- Shairport Sync uses AirPlay 2, `nqptp`, and only `output_backend = "pa"`.
- MQTT metadata and remote control are explicitly out of scope. They may be implemented only after real-device audio acceptance succeeds.

## Audio Path

Shairport Sync connects directly to the standard Home Assistant PulseAudio socket. No second PulseAudio server, ALSA bridge, or ALSA output configuration is created.

The add-on relies on Home Assistant's built-in audio-device selector shown when `audio: true` is declared. The selector uses the system default by default and can select another Home Assistant audio device; no duplicate PulseAudio sink selector is required in the add-on configuration.

Startup verifies that the PulseAudio Unix socket exists. If it is unavailable, the add-on stops with a clear message and never falls back to ALSA.

## Latency Profiles

| Profile | Buffer | Intended use |
| --- | ---: | --- |
| `minimal` | 0.10 s | Stable wired network, lowest practical latency. |
| `standard` | 0.15 s | Default profile. |
| `stable` | 0.30 s | Wi-Fi or occasional clicks. |
| `custom` | 0.08–0.50 s | Safe manual adjustment. |

Offset and interpolation remain advanced correction settings. All values are validated before Shairport Sync starts.

## Volume and Session Handling

Shairport Sync is the sole per-stream volume controller. It uses `volume_control_profile = "flat"`, `volume_range_db = 30`, and `volume_max_db = 0.0`. Loudness, convolution, normalization, and gain above source level stay disabled.

The default AirPlay volume is `-24.0 dB`; the maximum is `0.0 dB`. The add-on never changes the Home Assistant device's global sink volume.

`allow_session_interruption = "yes"` lets a new source immediately take over an active source session.

## Files

- `repository.yaml`: Home Assistant repository metadata.
- `airplay2_lowlatency/`: add-on manifest, container, startup script, template, translations, and documentation.
- `tests/`: Bats configuration tests, startup tests, container smoke test, and manual acceptance checklist.
- `.github/workflows/`: validation and multi-architecture build workflows.

## Acceptance

Automated validation covers YAML, ShellCheck, Bats, and a container smoke test. Real acceptance on Home Assistant OS requires a single visible receiver, successful playback from iPhone, Mac, and Apple TV, source takeover, ten-minute playback per profile, monotonic volume steps from `-30 dB` to `0 dB` and back, no clicks/overruns/underruns, and audio stopping within 0.5 seconds on the standard profile.
