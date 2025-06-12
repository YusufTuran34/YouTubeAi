INSERT INTO job (name, script_path, cron_expression, next_script1, next_script2, active) VALUES
  ('Upload Video', 'sh_scripts/upload_video.sh', '0 0 10 * * *', 'sh_scripts/generate_description.sh', 'sh_scripts/upload_and_stream.sh', true),
  ('Stream Video', 'sh_scripts/remote_stream.sh', '0 0 20 * * *', NULL, NULL, true);

