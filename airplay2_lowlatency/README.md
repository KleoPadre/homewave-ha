# HomeWave AirPlay 2

HomeWave is a Home Assistant OS add-on that receives AirPlay 2 audio and sends
it to the native Home Assistant PulseAudio service. It supports `amd64`,
`aarch64`, and `armv7`.

## Installation

1. Add this repository in **Settings → Add-ons → Add-on store → Repositories**.
2. Install **HomeWave AirPlay 2** and start it.
3. Select the required output device with Home Assistant's built-in audio-device
   selector. HomeWave does not provide a duplicate sink selector.
4. Choose `HomeWave` from the AirPlay list on an iPhone, iPad, Mac, or Apple TV.

Run only one AirPlay receiver on the Home Assistant host. Stop a previous
JohannVR, v3rm0n, or other Shairport Sync add-on before starting HomeWave.

## Configuration

| Option | Allowed values | Default | Effect and safe correction |
| --- | --- | --- | --- |
| `airplay_name` | Non-empty text | `HomeWave` | Receiver name shown by AirPlay. |
| `audio_profile` | `minimal`, `standard`, `stable`, `custom` | `stable` | Selects the buffer profile. Stable is recommended. |
| `custom_buffer_seconds` | `0.08` to `0.50` | `0.15` | Used only by custom. Increase it when diagnostics show dropouts. |
| `offset_seconds` | `-2` to `2` | `0.0` | Advanced playback synchronisation correction; change only after measurement. |
| `interpolation` | `auto`, `basic`, `soxr` | `auto` | Advanced resampling. Keep auto unless diagnosing a device-specific issue. |
| `default_airplay_volume` | `-30` to `0` dB | `-24.0` | Initial stream volume; never changes the global Home Assistant sink volume. |
| `diagnostics` | `true`, `false` | `false` | Writes Shairport Sync statistics to the add-on log. Enable while investigating audio faults. |

Latency profiles are `minimal` (0.10 seconds), `standard` (0.15 seconds),
`stable` (0.30 seconds), and `custom` (0.08–0.50 seconds). Stable is the
recommended default. Minimal is suitable for a stable wired network but may
click on an unstable network.

AirPlay's `-30` to `0` dB control range is mapped to a 60 dB Shairport Sync
attenuation range. This makes the lowest source setting practically silent and
the highest setting full output, while retaining a flat, per-stream curve.

## Behaviour and troubleshooting

HomeWave uses only the Home Assistant PulseAudio socket. It never falls back to
ALSA. If the socket is unavailable, startup stops with a clear error. MQTT
metadata and remote control are deliberately not included in version 0.1.0.

For migration, stop and uninstall the prior receiver, install HomeWave, select
the output device in Home Assistant, then start HomeWave. To roll back, stop
HomeWave before re-enabling the former receiver. Do not run both at once.

Normal operation writes concise connection and error information to the add-on
log. Enable diagnostics only for troubleshooting; it adds detailed statistics
and debug-level messages. Do not share logs containing private device names.
