#!/bin/bash
# generate_tweet_advanced.sh - Advanced tweet generation with JSON configuration

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTENT_TYPE="${1:-lofi}"  # Default content type
ZODIAC_SIGN="${2:-aries}"  # Default zodiac sign for horoscope
CONFIG_OVERRIDE="${3:-}"
source "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"

# JSON configuration file path
CONFIG_FILE="$SCRIPT_DIR/content_configs.json"

# Check if JSON config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Validate content type using JSON
VALID_CONTENT_TYPES=$(jq -r '.content_types | keys | join(" ")' "$CONFIG_FILE")
if ! echo "$VALID_CONTENT_TYPES" | grep -q "$CONTENT_TYPE"; then
    echo "❌ Invalid content type: $CONTENT_TYPE"
    echo "✅ Available types: $VALID_CONTENT_TYPES"
    exit 1
fi

# Load configuration from JSON
NAME=$(jq -r ".content_types.$CONTENT_TYPE.name" "$CONFIG_FILE")
DESCRIPTION=$(jq -r ".content_types.$CONTENT_TYPE.description" "$CONFIG_FILE")
HASHTAGS=$(jq -r ".content_types.$CONTENT_TYPE.hashtags | join(\" \")" "$CONFIG_FILE")
EMOJIS=$(jq -r ".content_types.$CONTENT_TYPE.emojis | join(\" \")" "$CONFIG_FILE")
TONE=$(jq -r ".content_types.$CONTENT_TYPE.tone" "$CONFIG_FILE")
VIDEO_RELATED=$(jq -r ".content_types.$CONTENT_TYPE.video_related" "$CONFIG_FILE")
REQUIRES_ZODIAC=$(jq -r ".content_types.$CONTENT_TYPE.requires_zodiac // false" "$CONFIG_FILE")

echo "🎯 Content Type: $CONTENT_TYPE"
echo "📝 Name: $NAME"
echo "🔮 Video Related: $VIDEO_RELATED"
echo "🌟 Requires Zodiac: $REQUIRES_ZODIAC"

# Validate zodiac sign if required
if [[ "$REQUIRES_ZODIAC" == "true" ]]; then
    VALID_ZODIAC_SIGNS=$(jq -r '.zodiac_signs | join(" ")' "$CONFIG_FILE")
    if ! echo "$VALID_ZODIAC_SIGNS" | grep -q "$ZODIAC_SIGN"; then
        echo "❌ Invalid zodiac sign: $ZODIAC_SIGN"
        echo "✅ Available signs: $VALID_ZODIAC_SIGNS"
        exit 1
    fi
fi

# Check if video exists for video-related content
VIDEO_URL=""
VIDEO_TITLE=""
if [[ "$VIDEO_RELATED" == "true" ]]; then
    if [[ -f "$SCRIPT_DIR/latest_video_url.txt" ]]; then
        VIDEO_URL=$(cat "$SCRIPT_DIR/latest_video_url.txt" | head -1)
        if [[ -f "$SCRIPT_DIR/generated_title.txt" ]]; then
            VIDEO_TITLE=$(cat "$SCRIPT_DIR/generated_title.txt" | head -1)
        fi
    fi
fi

# Determine which prompt to use
PROMPT_KEY="general"
if [[ "$VIDEO_RELATED" == "true" && -n "$VIDEO_URL" && -n "$VIDEO_TITLE" ]]; then
    PROMPT_KEY="video"
    echo "📹 Video detected: $VIDEO_TITLE"
elif [[ "$REQUIRES_ZODIAC" == "true" ]]; then
    PROMPT_KEY="daily"
    echo "🔮 Creating content for: $ZODIAC_SIGN"
fi

# Get prompt from JSON
PROMPT=$(jq -r ".content_types.$CONTENT_TYPE.prompts.$PROMPT_KEY" "$CONFIG_FILE")

# Replace placeholders in prompt
if [[ "$VIDEO_RELATED" == "true" && -n "$VIDEO_TITLE" ]]; then
    PROMPT=$(echo "$PROMPT" | sed "s/{VIDEO_TITLE}/$VIDEO_TITLE/g")
fi

if [[ "$REQUIRES_ZODIAC" == "true" ]]; then
    PROMPT=$(echo "$PROMPT" | sed "s/{ZODIAC_SIGN}/$ZODIAC_SIGN/g")
fi

# Get OpenAI settings from JSON
OPENAI_MODEL=$(jq -r '.settings.openai_model' "$CONFIG_FILE")
MAX_TOKENS=$(jq -r '.settings.max_tokens' "$CONFIG_FILE")
TEMPERATURE=$(jq -r '.settings.temperature' "$CONFIG_FILE")
MAX_LENGTH=$(jq -r '.settings.max_tweet_length' "$CONFIG_FILE")

# Generate tweet using ChatGPT
echo "🤖 Generating tweet with ChatGPT..."
TWEET_TEXT=$(curl -s -X POST "https://api.openai.com/v1/chat/completions" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$OPENAI_MODEL\",
    \"messages\": [
      {
        \"role\": \"system\",
        \"content\": \"You are a social media expert. Create engaging, authentic tweets that match the specified tone and style.\"
      },
      {
        \"role\": \"user\",
        \"content\": \"$PROMPT\"
      }
    ],
    \"max_tokens\": $MAX_TOKENS,
    \"temperature\": $TEMPERATURE
  }" | jq -r '.choices[0].message.content' | tr -d '\n')

# Clean up the tweet text
TWEET_TEXT=$(echo "$TWEET_TEXT" | sed 's/^"//;s/"$//' | sed 's/^Tweet: //' | sed 's/^Here.*://')

# Validate tweet length
TWEET_LENGTH=${#TWEET_TEXT}
if [[ $TWEET_LENGTH -gt $MAX_LENGTH ]]; then
    echo "⚠️ Tweet too long ($TWEET_LENGTH chars), truncating..."
    TWEET_TEXT=$(echo "$TWEET_TEXT" | cut -c1-$((MAX_LENGTH-3)))"..."
fi

# Save tweet and metadata
echo "$TWEET_TEXT" > "$SCRIPT_DIR/generated_tweet.txt"
echo "$CONTENT_TYPE" > "$SCRIPT_DIR/last_content_type.txt"
echo "$ZODIAC_SIGN" > "$SCRIPT_DIR/last_zodiac_sign.txt"

echo "✅ Tweet generated successfully!"
echo "📊 Tweet length: $TWEET_LENGTH characters"
echo "📝 Tweet content: $TWEET_TEXT" 