#!/bin/bash
# cleanup_outputs.sh - remove previous output video and mp3 files

CONFIG_FILE="${1:-$(dirname "$0")/config.conf}"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Remove generated video if exists
[ -n "$OUTPUT_VIDEO" ] && rm -f "$OUTPUT_VIDEO"

# Remove mp3 files in MUSIC_DIR if set
if [ -n "$MUSIC_DIR" ] && [ -d "$MUSIC_DIR" ]; then
    rm -f "$MUSIC_DIR"/*.mp3
fi

