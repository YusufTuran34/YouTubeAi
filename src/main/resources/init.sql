INSERT INTO job (name, script_path, cron_expression, next_script1, next_script2, active) VALUES
  ('Example 6h Upload', 'sh_scripts/run_pipeline_and_upload_6h.sh', '0 0 6 * * *', NULL, NULL, true),
  ('Example 12h Stream', 'sh_scripts/run_video_and_stream_12h.sh', '0 0 18 * * *', NULL, NULL, true);
