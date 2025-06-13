INSERT INTO job (name, script_path, script_params, cron_expression, next_script1, next_script2, active) VALUES
  ('Daily 12h Stream', 'sh_scripts/run_video_and_stream.sh', '12 --tag lofi --post-twitter', '0 0 0 * * *', NULL, NULL, true),
  ('Daily 6h Upload', 'sh_scripts/run_pipeline_and_upload.sh', '6 --tag lofi --post-twitter', '0 0 15 * * *', NULL, NULL, true),
  ('Daily Tweet', 'sh_scripts/post_to_twitter.sh', '--tag lofi', '30 12 * * *', NULL, NULL, true);
