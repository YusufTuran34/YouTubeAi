#!/bin/bash
# run_generation_pipeline.sh - generates video, description, thumbnail and title sequentially.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="${1:-$SCRIPT_DIR/config.conf}"

set -e
bash "$SCRIPT_DIR/cleanup_outputs.sh" "$CONFIG_FILE"

bash "$SCRIPT_DIR/generate_video.sh" "$CONFIG_FILE"
bash "$SCRIPT_DIR/generate_description.sh" "$CONFIG_FILE" > "$SCRIPT_DIR/generated_description.txt"
bash "$SCRIPT_DIR/generate_thumbnail_from_video.sh" "$CONFIG_FILE"
bash "$SCRIPT_DIR/generate_title.sh" "$CONFIG_FILE" > "$SCRIPT_DIR/generated_title.txt"

echo "Generation pipeline completed."
