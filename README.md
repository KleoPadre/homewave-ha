# HomeWave

HomeWave is a Home Assistant OS add-on that turns a Home Assistant host into a
low-latency AirPlay 2 receiver. Audio is sent directly to Home Assistant's
native PulseAudio service, so the platform's built-in audio-device selector
remains the single place to choose the physical output.

## Highlights

- AirPlay 2 receiver powered by Shairport Sync and nqptp.
- Native PulseAudio output with no ALSA fallback or duplicate sink selector.
- Stable, low-latency defaults for `amd64`, `aarch64`, and `armv7`.
- Selectable per-stream volume curve: the balanced 60 dB default or the
  quieter-starting 90 dB option.
- Compact normal logs and optional diagnostics for troubleshooting.

## Install

In Home Assistant, open **Settings → Add-ons → Add-on Store → Repositories**
and add:

```text
https://github.com/KleoPadre/homewave-ha
```

Install **HomeWave AirPlay 2**, select the output device in Home Assistant's
audio-device selector, and start the add-on. Stop any other AirPlay receiver on
the host before using HomeWave.

## Settings

| Setting | Default | Description |
| --- | --- | --- |
| `airplay_name` | `HomeWave` | Name displayed in the AirPlay receiver list. |
| `audio_profile` | `stable` | Latency profile: minimal (0.10 s), standard (0.15 s), stable (0.30 s), or custom. |
| `custom_buffer_seconds` | `0.15` | Buffer length for the custom profile, from 0.08 to 0.50 seconds. |
| `offset_seconds` | `0.0` | Advanced timing correction from -2 to 2 seconds. Leave unchanged unless measured playback requires it. |
| `interpolation` | `auto` | Resampling mode: auto, basic, or soxr. |
| `default_airplay_volume` | `-24.0 dB` | Suggested initial source volume. AirPlay's range is mapped to a 60 dB per-stream curve. |
| `volume_curve` | `balanced` | Per-stream volume response: `balanced` is the 60 dB default; `quiet_start` is an optional 90 dB curve that makes the bottom of the AirPlay slider quieter. |
| `diagnostics` | `false` | Enables detailed Shairport Sync statistics and debug logs. Keep disabled during normal use. |

## Troubleshooting

| Symptom | Recovery action |
| --- | --- |
| Receiver is absent | Stop every other AirPlay receiver so only HomeWave remains, then check the add-on log for `HomeWave: Avahi is ready`. |
| Receiver is visible but silent | Select the required output with Home Assistant's audio-device selector, then check for `HomeWave: PulseAudio socket is ready`. |
| Clicks or dropouts | Return `audio_profile` to `stable`, enable diagnostics temporarily, and review the add-on log. |
| Minimum source volume is too loud | Set `volume_curve` to `quiet_start`; it uses a 90 dB per-stream curve. `balanced` remains the 60 dB default. |
| Investigating an issue | Sanitize logs before sharing them and turn `diagnostics` off after the investigation. |

Normal startup reports `HomeWave: PulseAudio socket is ready`, `HomeWave: D-Bus
is ready`, `HomeWave: Avahi is ready`, and `HomeWave: nqptp is ready` when its
prerequisites are available. Use the `stable` profile first; try `standard` or
`minimal` only after reliable playback on a wired network.

Shairport Sync automatically negotiates stereo or multichannel output. With a
two-channel Home Assistant sink, multichannel content is mixed down to stereo;
5.1 or 7.1 playback requires a sink that accepts that layout.

The add-on does not provide MQTT metadata or remote control in the 0.1 release
series.
