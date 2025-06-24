#!/bin/bash
# cleanup_outputs.sh - remove previous output video and mp3 files

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SH_SCRIPTS_DIR="$(dirname "$SCRIPT_DIR")"
export SH_SCRIPTS_DIR
CONFIG_OVERRIDE="${1:-}"
source "$SH_SCRIPTS_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"

# Generated videoları saklamak için artık silmiyoruz

# Remove mp3 files in MUSIC_DIR if set
if [ -n "$MUSIC_DIR" ] && [ -d "$MUSIC_DIR" ]; then
    rm -f "$MUSIC_DIR"/*.mp3
fi

