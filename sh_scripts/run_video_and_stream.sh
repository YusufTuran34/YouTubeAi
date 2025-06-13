#!/bin/bash
# run_video_and_stream.sh - set duration then generate video and stream

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Defaults
DURATION_HOURS=12
CONFIG_FILE="$SCRIPT_DIR/config.conf"
POST_TWITTER=0
TAG=""

# Parse args
if [[ "$1" =~ ^[0-9] ]]; then
    DURATION_HOURS="$1"
    shift
fi

while [ $# -gt 0 ]; do
    case "$1" in
        --config)
            CONFIG_FILE="$2"; shift 2;;
        --post-twitter)
            POST_TWITTER=1; shift;;
        --tag)
            TAG="$2"; shift 2;;
        *)
            shift;;
    esac
done

bash "$SCRIPT_DIR/update_config.sh" VIDEO_DURATION_HOURS "$DURATION_HOURS" "$CONFIG_FILE"
[ -n "$TAG" ] && bash "$SCRIPT_DIR/update_config.sh" TAG "$TAG" "$CONFIG_FILE"

bash "$SCRIPT_DIR/cleanup_outputs.sh" "$CONFIG_FILE"
bash "$SCRIPT_DIR/generate_video.sh" "$CONFIG_FILE"
bash "$SCRIPT_DIR/upload_and_stream.sh" "$CONFIG_FILE"

if [ "$POST_TWITTER" -eq 1 ]; then
    bash "$SCRIPT_DIR/post_to_twitter.sh" "$CONFIG_FILE"
fi
