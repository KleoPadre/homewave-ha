# Changelog

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
