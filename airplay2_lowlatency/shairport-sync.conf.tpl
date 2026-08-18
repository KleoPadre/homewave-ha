general =
{
  name = "@@AIRPLAY_NAME@@";
  output_backend = "pa";
  interpolation = "@@INTERPOLATION@@";
  default_airplay_volume = @@DEFAULT_AIRPLAY_VOLUME@@;
  volume_control_profile = "flat";
  volume_range_db = 60;
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

pa =
{
  server = "unix:///run/audio/pulse.sock";
};
