#!/bin/bash
# run_generation_pipeline.sh - generates video, description, thumbnail and title sequentially.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SH_SCRIPTS_DIR="$(dirname "$SCRIPT_DIR")"
export SH_SCRIPTS_DIR
CONFIG_OVERRIDE="${1:-}"
source "$SH_SCRIPTS_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"
CONFIG_FILE="$CONFIG_OVERRIDE"

set -e
bash "$SH_SCRIPTS_DIR/utilities/cleanup_outputs.sh" "$CONFIG_FILE"

bash "$SH_SCRIPTS_DIR/generators/generate_video.sh" "$CONFIG_FILE"
bash "$SH_SCRIPTS_DIR/generators/generate_description.sh" "$CONFIG_FILE" > "$SH_SCRIPTS_DIR/generated_description.txt"
bash "$SH_SCRIPTS_DIR/generators/generate_thumbnail_from_video.sh" "$CONFIG_FILE"
bash "$SH_SCRIPTS_DIR/generators/generate_title.sh" "$CONFIG_FILE" > "$SH_SCRIPTS_DIR/generated_title.txt"

echo "Generation pipeline completed."
