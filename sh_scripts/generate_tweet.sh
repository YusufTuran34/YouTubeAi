#!/bin/bash
# generate_tweet.sh - Use OpenAI to create an SEO friendly tweet text

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_OVERRIDE="${1:-}"
source "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"

# Video URL'ini al
VIDEO_URL_FILE="$SCRIPT_DIR/latest_video_url.txt"
if [ ! -f "$VIDEO_URL_FILE" ]; then
    echo "Video URL dosyası bulunamadı: $VIDEO_URL_FILE" >&2
    exit 1
fi

VIDEO_URL=$(cat "$VIDEO_URL_FILE")
if [ -z "$VIDEO_URL" ]; then
    echo "Video URL boş!" >&2
    exit 1
fi

# Video başlığını al
TITLE_FILE="$SCRIPT_DIR/generated_title.txt"
if [ -f "$TITLE_FILE" ]; then
    VIDEO_TITLE=$(cat "$TITLE_FILE")
else
    VIDEO_TITLE="LoFi Focus Music"
fi

# Video süresini al
LATEST_FILE="$SCRIPT_DIR/latest_output_video.txt"
[ -f "$LATEST_FILE" ] && OUTPUT_VIDEO="$(cat "$LATEST_FILE")"

DURATION_SOURCE="${OUTPUT_VIDEO:-$VIDEO_FILE}"
DURATION=""
if [ -n "$DURATION_SOURCE" ] && [ -f "$DURATION_SOURCE" ]; then
    DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$DURATION_SOURCE")
    DURATION_INT=${DURATION%.*}
    DURATION_TEXT="Duration: ${DURATION_INT} seconds"
else
    DURATION_TEXT=""
fi

TWEET_TEXT=""
if [ -n "$OPENAI_API_KEY" ] && command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    PROMPT="Create an engaging, SEO-friendly tweet for a YouTube video. 

Video Title: ${VIDEO_TITLE}
${DURATION_TEXT}
Keywords: ${KEYWORDS}
Video URL: ${VIDEO_URL}

Requirements:
- Keep it under 280 characters (including the URL)
- Make it engaging and click-worthy
- Include relevant hashtags for lofi/focus music
- Be natural and conversational
- Include the video URL at the end

Respond only with the tweet text, no explanations."

    RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{\"model\":\"${OPENAI_MODEL:-gpt-3.5-turbo}\",\"messages\":[{\"role\":\"user\",\"content\":\"$PROMPT\"}],\"max_tokens\":100}")
    
    TWEET_TEXT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' | tr -d '\r')
fi

if [ -z "$TWEET_TEXT" ] || [ "$TWEET_TEXT" = "null" ]; then
    # Basit fallback tweet metni
    TWEET_TEXT="${VIDEO_TITLE} 🎵

Perfect for focus, study, or relaxation sessions.

${VIDEO_URL}

#LoFi #FocusMusic #StudyMusic #ChillBeats"
fi

echo "$TWEET_TEXT" 