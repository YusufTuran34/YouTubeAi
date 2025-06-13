#!/bin/bash
# generate_description.sh - Create SEO friendly description via OpenAI

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_OVERRIDE="${1:-}"
source "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"

if [ -z "$OUTPUT_VIDEO" ] || [ ! -f "$OUTPUT_VIDEO" ]; then
    echo "Video dosyası bulunamadı: $OUTPUT_VIDEO" >&2
    exit 1
fi

DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUTPUT_VIDEO")
DURATION_INT=${DURATION%.*}

DESCRIPTION=""
if [ -n "$OPENAI_API_KEY" ] && command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    PROMPT="Write a concise and SEO friendly YouTube description for a lofi focus music video. Duration: ${DURATION_INT} seconds. Keywords: ${KEYWORDS}. Limit to 150 words."
    RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{\"model\":\"${OPENAI_MODEL:-gpt-3.5-turbo}\",\"messages\":[{\"role\":\"user\",\"content\":\"$PROMPT\"}],\"max_tokens\":200}")
    DESCRIPTION=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' | tr -d '\r')
fi

if [ -z "$DESCRIPTION" ] || [ "$DESCRIPTION" = "null" ]; then
    # Eski basit açıklama şablonu
    if [ "$DURATION_INT" -lt 900 ]; then
      PURPOSE="Ideal for quick tasks and short focus sessions."
    elif [ "$DURATION_INT" -lt 2700 ]; then
      PURPOSE="Perfect for studying, writing, and deep focus."
    elif [ "$DURATION_INT" -lt 5400 ]; then
      PURPOSE="Stay productive with this extended LoFi mix."
    else
      PURPOSE="A long-format LoFi stream to help you stay in flow all day."
    fi

    DESCRIPTION=$(cat <<EOF
🎧 LoFi Focus Music 🎧

$PURPOSE

This music is designed to help you concentrate, stay calm, and stay focused.

All music used is copyright-safe and sourced from Jamendo under Creative Commons (CC BY) license.

📌 Tags: LoFi, Chillhop, Study Music, Focus Beats, Productivity, No Copyright Music

#lofi #focusmusic #studymusic #chillbeats
EOF
)
fi

echo "$DESCRIPTION"
