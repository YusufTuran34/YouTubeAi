#!/bin/bash
# run_pipeline_and_upload.sh - optionally set duration then run generation pipeline and upload video

DURATION_HOURS="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="${2:-$SCRIPT_DIR/config.conf}"

if [ -n "$DURATION_HOURS" ]; then
    bash "$SCRIPT_DIR/update_config.sh" VIDEO_DURATION_HOURS "$DURATION_HOURS" "$CONFIG_FILE"
fi

bash "$SCRIPT_DIR/cleanup_outputs.sh" "$CONFIG_FILE"
bash "$SCRIPT_DIR/run_generation_pipeline.sh" "$CONFIG_FILE"
bash "$SCRIPT_DIR/upload_video.sh" "$CONFIG_FILE"
