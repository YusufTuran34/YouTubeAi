# YouTube AI Bot

This project includes shell scripts for generating and uploading YouTube videos automatically. The title and description generation scripts now support using OpenAI for smarter, SEO friendly content.

## Configuration
Create `sh_scripts/config.conf` and fill in your paths and API keys:

```bash
VIDEO_FILE="sample.mp4"        # Input video
OPENAI_API_KEY="sk-..."        # Your OpenAI token
OPENAI_MODEL="gpt-3.5-turbo"   # Optional
KEYWORDS="lofi, study music"
```

Run the generator scripts pointing to this config file:

```bash
sh sh_scripts/generate_title.sh
sh sh_scripts/generate_description.sh
```

If `OPENAI_API_KEY` is not set or the API call fails, the scripts fall back to basic templates.
Use helper scripts for common tasks:

- `sh sh_scripts/run_generation_pipeline.sh` - generate video, description, thumbnail and title sequentially.
- `sh sh_scripts/run_pipeline_and_upload.sh <hours>` - optional duration parameter then upload the result.
- `sh sh_scripts/run_video_and_stream.sh <hours>` - generate a long video and start streaming.

When scheduling jobs via the web UI you can also specify optional parameters that
will be passed to the script. For example a job with `scriptPath` set to
`sh_scripts/run_video_and_stream.sh` and `scriptParams` of `12` will start a
12 hour stream.
