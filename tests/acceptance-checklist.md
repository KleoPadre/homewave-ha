# HomeWave 0.1.4 Real-device Acceptance Checklist

Complete this checklist on Home Assistant OS before calling the add-on stable.

- [ ] Stop `907c2594_shairport_sync` and any other AirPlay receiver.
- [ ] Start HomeWave and confirm that exactly one `HomeWave` receiver is visible.
- [ ] Confirm the add-on log reports `HomeWave: PulseAudio socket is ready`,
      `HomeWave: D-Bus is ready`, `HomeWave: Avahi is ready`, and
      `HomeWave: nqptp is ready`.
- [ ] Play audio from iPhone for ten minutes on `standard`; record clicks,
      underruns, overruns, and stop time.
- [ ] Play audio from Mac for ten minutes on `standard`; record the same results.
- [ ] Play audio from Apple TV for ten minutes on `standard`; record the same results.
- [ ] Confirm a new source immediately takes over an active source session.
- [ ] With `volume_curve: balanced`, test low, middle, and maximum source volume;
      confirm monotonic stream-volume changes and that the Home Assistant sink
      volume does not move.
- [ ] With `volume_curve: quiet_start`, test low, middle, and maximum source
      volume; confirm that the low setting is quieter than `balanced`, changes
      remain monotonic, and the Home Assistant sink volume does not move.
- [ ] Confirm playback stops in under 0.5 seconds on `standard`.
- [ ] If standard clicks, enable diagnostics, repeat with `stable`, preserve a
      sanitized log excerpt, and record stable as the recommendation.
- [ ] Record profile, source, duration, click/crackle result, stop time,
      takeover result, and diagnostics result in the release notes.
