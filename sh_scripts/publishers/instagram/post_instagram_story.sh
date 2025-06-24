#!/bin/bash
# post_instagram_story.sh - Post the first frame of the latest output video as an Instagram story.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_OVERRIDE="${1:-}"
source "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"

LATEST_FILE="$SCRIPT_DIR/latest_output_video.txt"
[ -f "$LATEST_FILE" ] && OUTPUT_VIDEO="$(cat "$LATEST_FILE")"

if [ -z "$OUTPUT_VIDEO" ] || [ ! -f "$OUTPUT_VIDEO" ]; then
  echo "❌ OUTPUT_VIDEO not found: $OUTPUT_VIDEO" >&2
  exit 1
fi

STORY_IMAGE="$SCRIPT_DIR/story_frame.jpg"
ffmpeg -y -i "$OUTPUT_VIDEO" -frames:v 1 -q:v 2 "$STORY_IMAGE" >/dev/null 2>&1
if [ ! -f "$STORY_IMAGE" ]; then
  echo "❌ Failed to extract frame image." >&2
  exit 1
fi

if [ -z "$INSTAGRAM_USERNAME" ] || [ -z "$INSTAGRAM_PASSWORD" ]; then
  echo "❌ Instagram credentials missing." >&2
  exit 1
fi

pip3 show instagrapi >/dev/null 2>&1 || pip3 install --break-system-packages instagrapi >/dev/null 2>&1

python3 - <<PYEOF
import sys
from instagrapi import Client

username = "${INSTAGRAM_USERNAME}"
password = "${INSTAGRAM_PASSWORD}"
image = "${STORY_IMAGE}"

cl = Client()
try:
    cl.login(username, password)
    cl.photo_upload_to_story(image, "")
    print("✅ Instagram story posted.")
except Exception as e:
    print("❌ Failed to post story:", e)
    sys.exit(1)
PYEOF
