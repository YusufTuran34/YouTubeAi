#!/bin/bash
# generate_gif_with_openai.sh - Use OpenAI images API to create a short looping GIF.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_OVERRIDE="${1:-}"
source "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"

PROMPT="${AI_GIF_PROMPT:-lofi city at night animation}"
FRAME_COUNT="${AI_GIF_FRAMES:-4}"
GIF_OUTPUT="${AI_GIF_OUTPUT:-background.gif}"
WIDTH="${AI_GIF_WIDTH:-512}"
HEIGHT="${AI_GIF_HEIGHT:-512}"

if [ -z "$OPENAI_API_KEY" ]; then
    echo "OPENAI_API_KEY is required for GIF generation" >&2
    exit 1
fi

TMP_DIR=$(mktemp -d)

for i in $(seq 1 "$FRAME_COUNT"); do
    FRAME_PROMPT="$PROMPT frame $i of $FRAME_COUNT"
    response=$(curl -s https://api.openai.com/v1/images/generations \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{\"model\":\"dall-e-3\",\"prompt\":\"$FRAME_PROMPT\",\"n\":1,\"size\":\"${WIDTH}x${HEIGHT}\"}")
    url=$(echo "$response" | jq -r '.data[0].url')
    if [ -z "$url" ] || [ "$url" = "null" ]; then
        echo "Failed to generate frame $i" >&2
        rm -rf "$TMP_DIR"
        exit 1
    fi
    curl -s -L "$url" -o "$TMP_DIR/frame_${i}.png"
    if [ $? -ne 0 ]; then
        echo "Failed to download frame $i" >&2
        rm -rf "$TMP_DIR"
        exit 1
    fi
done

ffmpeg -y -framerate 2 -i "$TMP_DIR/frame_%d.png" -vf "scale=${WIDTH}:${HEIGHT},fps=10" "$GIF_OUTPUT"

rm -rf "$TMP_DIR"

echo "$GIF_OUTPUT"
