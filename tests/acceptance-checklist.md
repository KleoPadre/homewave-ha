# HomeWave 0.1.0 Real-device Acceptance Checklist

Complete this checklist on Home Assistant OS before calling the add-on stable.

- [ ] Stop `907c2594_shairport_sync` and any other AirPlay receiver.
- [ ] Start HomeWave and confirm that exactly one `HomeWave` receiver is visible.
- [ ] Play audio from iPhone for ten minutes on `standard`; record clicks,
      underruns, overruns, and stop time.
- [ ] Play audio from Mac for ten minutes on `standard`; record the same results.
- [ ] Play audio from Apple TV for ten minutes on `standard`; record the same results.
- [ ] Confirm a new source immediately takes over an active source session.
- [ ] Step the source volume from `-30` to `0` dB and back; confirm monotonic
      stream-volume changes without changing the Home Assistant device volume.
- [ ] Confirm playback stops in under 0.5 seconds on `standard`.
- [ ] If standard clicks, enable diagnostics, repeat with `stable`, preserve a
      sanitized log excerpt, and record stable as the recommendation.
- [ ] Record profile, source, duration, click/crackle result, stop time,
      takeover result, and diagnostics result in the release notes.
