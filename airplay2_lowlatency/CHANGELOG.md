# Changelog

## 0.1.4

- Add selectable balanced (60 dB) and quiet-start (90 dB) per-stream volume curves.
- Report concise readiness status for PulseAudio, D-Bus, Avahi, and nqptp at startup.
- Add troubleshooting guidance and expand the real-device acceptance checklist.

## 0.1.3

- Use the stable latency profile by default.
- Keep normal logging concise and reserve detailed statistics for diagnostics.

## 0.1.2

- Map the AirPlay volume control to a 60 dB per-stream attenuation range for a
  practical silent minimum and full-output maximum.

## 0.1.1

- Replace inherited s6, SSH/SFTP, and syslog services with the minimal runtime
  required by HomeWave.
- Start only D-Bus, Avahi, nqptp, and Shairport Sync.

## 0.1.0

- Initial HomeWave AirPlay 2 receiver release.
- Native Home Assistant PulseAudio output with safe configuration validation.
- Real-device acceptance is pending before this release can be called stable.
