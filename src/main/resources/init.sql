INSERT INTO job (name, script_path, script_params, channel, cron_expression, next_script1, next_script2, active, last_log, last_exit_code, sequence) VALUES
  ('Daily 12h Stream', 'sh_scripts/run_pipeline_and_stream.sh', '12 --tag lofi --post-twitter --post-instagram', 'default', '0 0 0 * * *', NULL, NULL, true, NULL, NULL, 1),
  ('Daily 6h Upload', 'sh_scripts/run_pipeline_and_upload.sh', '6 --tag lofi --post-twitter', 'default', '0 0 15 * * *', NULL, NULL, true, NULL, NULL, 2),
  ('Daily 1h Upload', 'sh_scripts/run_pipeline_and_upload.sh', '1 --tag lofi --post-twitter', 'default', '0 30 3 * * *', NULL, NULL, true, NULL, NULL, 3),
  ('Daily Tweet - LoFi', 'sh_scripts/post_to_twitter_simple.py', 'lofi', 'default', '0 30 12 * * *', NULL, NULL, true, NULL, NULL, 4),
  ('Daily Tweet - Horoscope Aries', 'sh_scripts/post_to_twitter_simple.py', 'horoscope aries', 'default', '0 0 9 * * *', NULL, NULL, true, NULL, NULL, 5),
  ('Daily Tweet - Horoscope Taurus', 'sh_scripts/post_to_twitter_simple.py', 'horoscope taurus', 'default', '0 15 9 * * *', NULL, NULL, true, NULL, NULL, 6),
  ('Daily Tweet - Horoscope Gemini', 'sh_scripts/post_to_twitter_simple.py', 'horoscope gemini', 'default', '0 30 9 * * *', NULL, NULL, true, NULL, NULL, 7),
  ('Daily Tweet - Horoscope Cancer', 'sh_scripts/post_to_twitter_simple.py', 'horoscope cancer', 'default', '0 45 9 * * *', NULL, NULL, true, NULL, NULL, 8),
  ('Daily Tweet - Horoscope Leo', 'sh_scripts/post_to_twitter_simple.py', 'horoscope leo', 'default', '0 0 10 * * *', NULL, NULL, true, NULL, NULL, 9),
  ('Daily Tweet - Horoscope Virgo', 'sh_scripts/post_to_twitter_simple.py', 'horoscope virgo', 'default', '0 15 10 * * *', NULL, NULL, true, NULL, NULL, 10),
  ('Daily Tweet - Horoscope Libra', 'sh_scripts/post_to_twitter_simple.py', 'horoscope libra', 'default', '0 30 10 * * *', NULL, NULL, true, NULL, NULL, 11),
  ('Daily Tweet - Horoscope Scorpio', 'sh_scripts/post_to_twitter_simple.py', 'horoscope scorpio', 'default', '0 45 10 * * *', NULL, NULL, true, NULL, NULL, 12),
  ('Daily Tweet - Horoscope Sagittarius', 'sh_scripts/post_to_twitter_simple.py', 'horoscope sagittarius', 'default', '0 0 11 * * *', NULL, NULL, true, NULL, NULL, 13),
  ('Daily Tweet - Horoscope Capricorn', 'sh_scripts/post_to_twitter_simple.py', 'horoscope capricorn', 'default', '0 15 11 * * *', NULL, NULL, true, NULL, NULL, 14),
  ('Daily Tweet - Horoscope Aquarius', 'sh_scripts/post_to_twitter_simple.py', 'horoscope aquarius', 'default', '0 30 11 * * *', NULL, NULL, true, NULL, NULL, 15),
  ('Daily Tweet - Horoscope Pisces', 'sh_scripts/post_to_twitter_simple.py', 'horoscope pisces', 'default', '0 45 11 * * *', NULL, NULL, true, NULL, NULL, 16),
  ('Daily Tweet - Meditation', 'sh_scripts/post_to_twitter_simple.py', 'meditation', 'default', '0 15 7 * * *', NULL, NULL, true, NULL, NULL, 17),
  ('Daily Instagram Story', 'sh_scripts/post_instagram_story.sh', '', 'default', '0 0 11 * * *', NULL, NULL, true, NULL, NULL, 18),
  ('Example 5m Upload', 'sh_scripts/run_pipeline_and_upload.sh', '0.083 --tag lofi --post-twitter', 'default', '0 0 */6 * * *', NULL, NULL, true, NULL, NULL, 19),
  ('Example 10m Stream', 'sh_scripts/run_pipeline_and_stream.sh', '0.167 --tag lofi --post-twitter', 'default', '0 0 */4 * * *', NULL, NULL, true, NULL, NULL, 20);
