INSERT INTO job (name, script_path, script_params, channel, cron_expression, next_script1, next_script2, active, last_log, last_exit_code, sequence) VALUES
  ('Daily 12h Stream', 'sh_scripts/run_video_and_stream.sh', '12 --tag lofi --post-twitter', 'default', '0 0 0 * * *', NULL, NULL, true, NULL, NULL, 1),
  ('Daily 6h Upload', 'sh_scripts/run_pipeline_and_upload.sh', '6 --tag lofi --post-twitter', 'default', '0 0 15 * * *', NULL, NULL, true, NULL, NULL, 2),
  ('Daily Tweet', 'sh_scripts/post_to_twitter.sh', '--tag lofi', 'default', '0 30 12 * * *', NULL, NULL, true, NULL, NULL, 3);
