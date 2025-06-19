#!/bin/bash
# generate_description.sh - Create SEO friendly description via OpenAI

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_OVERRIDE="${1:-}"
source "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"

LATEST_FILE="$SCRIPT_DIR/latest_output_video.txt"
[ -f "$LATEST_FILE" ] && OUTPUT_VIDEO="$(cat "$LATEST_FILE")"

if [ -z "$OUTPUT_VIDEO" ] || [ ! -f "$OUTPUT_VIDEO" ]; then
    echo "Video dosyası bulunamadı: $OUTPUT_VIDEO" >&2
    exit 1
fi

DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUTPUT_VIDEO")
DURATION_INT=${DURATION%.*}

DESCRIPTION=""
if [ -n "$OPENAI_API_KEY" ] && command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    # JSON-safe prompt oluştur
    PROMPT_CONTENT="Create a highly SEO-optimized YouTube description for a lofi focus music video. Video duration: ${DURATION_INT} seconds. Keywords: ${KEYWORDS}. Include: engaging hook, benefits description, call to action, and 8-12 hashtags. Make it similar to successful lofi music channels. Keep under 200 words."
    
    RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{\"model\":\"${OPENAI_MODEL:-gpt-3.5-turbo}\",\"messages\":[{\"role\":\"user\",\"content\":\"$PROMPT_CONTENT\"}],\"max_tokens\":300}")
    
    DESCRIPTION=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' | tr -d '\r')
fi
if [ -z "$DESCRIPTION" ] || [ "$DESCRIPTION" = "null" ]; then
    # Eski basit açıklama şablonu
    if [ "$DURATION_INT" -lt 900 ]; then
      PURPOSE="Perfect for quick tasks, short study sessions, and productivity bursts."
      DURATION_TEXT="Quick 15-minute focus session"
    elif [ "$DURATION_INT" -lt 2700 ]; then
      PURPOSE="Ideal for studying, writing, coding, and deep work sessions."
      DURATION_TEXT="Extended focus session"
    elif [ "$DURATION_INT" -lt 5400 ]; then
      PURPOSE="Stay productive with this extended LoFi mix for long work sessions."
      DURATION_TEXT="Long-format productivity mix"
    else
      PURPOSE="A comprehensive LoFi stream to help you stay in flow all day long."
      DURATION_TEXT="All-day productivity stream"
    fi

    DESCRIPTION=$(cat <<EOF
🎧 Boost Your Focus with LoFi Study Music 🎧

$PURPOSE This $DURATION_TEXT features calming beats and relaxing melodies designed to enhance concentration and reduce distractions.

Perfect for: studying, working, coding, reading, writing, and any task that requires deep focus.

🎵 All music is copyright-safe and sourced from Jamendo under Creative Commons license.

💡 Like this video if it helps you focus!
🔔 Subscribe for more daily lofi music content
📱 Turn on notifications to never miss new uploads

#lofi #studymusic #focusmusic #chillbeats #productivity #lofimusic #studying #workmusic #codingmusic #relaxing #chillhop #concentration
EOF
)
fi

echo "$DESCRIPTION"
