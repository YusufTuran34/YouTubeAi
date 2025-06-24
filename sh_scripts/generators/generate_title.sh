#!/bin/bash
# generate_title.sh - Use OpenAI to create an SEO friendly title

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SH_SCRIPTS_DIR="$(dirname "$SCRIPT_DIR")"
export SH_SCRIPTS_DIR
CONFIG_OVERRIDE="${1:-}"
source "$SH_SCRIPTS_DIR/common.sh" 2>/dev/null
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE" 2>/dev/null

LATEST_FILE="$SH_SCRIPTS_DIR/latest_output_video.txt"
[ -f "$LATEST_FILE" ] && OUTPUT_VIDEO="$(cat "$LATEST_FILE")"

DURATION_SOURCE="${OUTPUT_VIDEO:-$VIDEO_FILE}"
if [ -z "$DURATION_SOURCE" ] || [ ! -f "$DURATION_SOURCE" ]; then
    echo "Video dosyası bulunamadı: $DURATION_SOURCE" >&2
    exit 1
fi

DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$DURATION_SOURCE")
DURATION_INT=${DURATION%.*}

TITLE=""
if [ -n "$OPENAI_API_KEY" ] && command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    PROMPT="Create a short, catchy and SEO friendly YouTube title for a lofi focus music video. Duration: ${DURATION_INT} seconds. Keywords: ${KEYWORDS}. Respond only with the title text, no quotes."
    RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{\"model\":\"${OPENAI_MODEL:-gpt-3.5-turbo}\",\"messages\":[{\"role\":\"user\",\"content\":\"$PROMPT\"}],\"max_tokens\":50}")
    TITLE=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' | tr -d '\r\n"')
fi

if [ -z "$TITLE" ] || [ "$TITLE" = "null" ]; then
    # Basit fallback başlıkları
    if [ "$DURATION_INT" -lt 900 ]; then
        TITLE="Quick Focus Beats - LoFi for Short Tasks"
    elif [ "$DURATION_INT" -lt 2700 ]; then
        TITLE="Deep Work LoFi Vibes - 30 Min Focus Music"
    elif [ "$DURATION_INT" -lt 5400 ]; then
        TITLE="Study Session LoFi Mix - 1 Hour of Focus"
    else
        VARIANTS=("24/7 LoFi Focus Radio" "Ultimate Chill Mix for Studying" "LoFi Ambience for Productivity")
        TITLE="${VARIANTS[$RANDOM % ${#VARIANTS[@]}]}"
    fi
fi

echo "$TITLE"