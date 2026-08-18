# HomeWave

HomeWave is a Home Assistant OS add-on that turns a Home Assistant host into a
low-latency AirPlay 2 receiver. Audio is sent directly to Home Assistant's
native PulseAudio service, so the platform's built-in audio-device selector
remains the single place to choose the physical output.

## Highlights

- AirPlay 2 receiver powered by Shairport Sync and nqptp.
- Native PulseAudio output with no ALSA fallback or duplicate sink selector.
- Stable, low-latency defaults for `amd64`, `aarch64`, and `armv7`.
- Per-stream 60 dB volume range: a practical silent minimum and full output at
  the top of the AirPlay control.
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
| `diagnostics` | `false` | Enables detailed Shairport Sync statistics and debug logs. Keep disabled during normal use. |

## Support and testing

Use the `stable` profile first. If playback is reliable on a wired network, try
`standard` or `minimal` for lower latency. If you encounter clicks or dropouts,
return to `stable`, enable diagnostics, and review the add-on log.

The add-on does not provide MQTT metadata or remote control in the 0.1 release
series.
