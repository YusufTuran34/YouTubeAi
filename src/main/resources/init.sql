INSERT INTO job (name, script_path, script_params, channel, cron_expression, next_script1, next_script2, active, last_log, last_exit_code, sequence) VALUES
  ('Daily 12h Stream', 'sh_scripts/run_pipeline_and_stream.sh', '12 --tag lofi --post-twitter --post-instagram', 'default', '0 0 0 * * *', NULL, NULL, true, NULL, NULL, 1),
  ('Daily 6h Upload', 'sh_scripts/run_pipeline_and_upload.sh', '6 --tag lofi --post-twitter', 'default', '0 0 15 * * *', NULL, NULL, true, NULL, NULL, 2),
   ('Daily 1h Upload', 'sh_scripts/run_pipeline_and_upload.sh', '1 ', 'default', '0 30 3 * * *', NULL, NULL, true, NULL, NULL, 3),
  ('Daily Tweet', 'sh_scripts/post_to_twitter.sh', '--tag lofi', 'default', '0 30 12 * * *', NULL, NULL, true, NULL, NULL, 4),
  ('Daily Instagram Story', 'sh_scripts/post_instagram_story.sh', '', 'default', '0 0 11 * * *', NULL, NULL, true, NULL, NULL, 5),
  ('Example 5m Upload', 'sh_scripts/run_pipeline_and_upload.sh', '0.083 --post-twitter', 'default', NULL, NULL, NULL, true, NULL, NULL, 6),
  ('Example 10m Stream', 'sh_scripts/run_pipeline_and_stream.sh', '0.167 --post-twitter', 'default', NULL, NULL, NULL, true, NULL, NULL, 7);
