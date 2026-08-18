general =
{
  name = "@@AIRPLAY_NAME@@";
  output_backend = "pulseaudio";
  interpolation = "@@INTERPOLATION@@";
  default_airplay_volume = @@DEFAULT_AIRPLAY_VOLUME@@;
  volume_control_profile = "@@VOLUME_CONTROL_PROFILE@@";
  volume_range_db = @@VOLUME_RANGE_DB@@;
  volume_max_db = 0.0;
  audio_backend_buffer_desired_length_in_seconds = @@BUFFER_SECONDS@@;
  audio_backend_latency_offset_in_seconds = @@OFFSET_SECONDS@@;
};

diagnostics =
{
@@DIAGNOSTICS@@
};

sessioncontrol =
{
  allow_session_interruption = "yes";
};

pulseaudio =
{
  server = "unix:///run/audio/pulse.sock";
};
