#!/bin/bash
# run_video_and_stream.sh - set duration then generate video and stream

DURATION_HOURS="${1:-12}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="${2:-$SCRIPT_DIR/config.conf}"

bash "$SCRIPT_DIR/update_config.sh" VIDEO_DURATION_HOURS "$DURATION_HOURS" "$CONFIG_FILE"

bash "$SCRIPT_DIR/cleanup_outputs.sh" "$CONFIG_FILE"
bash "$SCRIPT_DIR/generate_video.sh" "$CONFIG_FILE"
bash "$SCRIPT_DIR/upload_and_stream.sh" "$CONFIG_FILE"
