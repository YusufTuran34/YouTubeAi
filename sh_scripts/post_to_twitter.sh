#!/bin/bash
# post_to_twitter.sh - Post a tweet about the uploaded video or stream
# Usage: post_to_twitter.sh [--config FILE] [--tag TAG] [--url VIDEO_URL] [--message TEXT]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.conf"
MESSAGE=""
TAG=""
VIDEO_URL=""

while [ $# -gt 0 ]; do
  case "$1" in
    --config)
      CONFIG_FILE="$2"; shift 2;;
    --tag)
      TAG="$2"; shift 2;;
    --url)
      VIDEO_URL="$2"; shift 2;;
    --message|-m)
      MESSAGE="$2"; shift 2;;
    *)
      if [ -z "$MESSAGE" ]; then
        MESSAGE="$1"; shift
      else
        shift
      fi;;
  esac
done

if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi

URL_FILE="$SCRIPT_DIR/latest_video_url.txt"
if [ -z "$VIDEO_URL" ] && [ -f "$URL_FILE" ]; then
    VIDEO_URL="$(cat "$URL_FILE")"
fi

# Validate credentials
if [ -z "$TWITTER_API_KEY" ] || [ -z "$TWITTER_API_SECRET" ] || [ -z "$TWITTER_ACCESS_TOKEN" ] || [ -z "$TWITTER_ACCESS_SECRET" ]; then
    echo "Twitter API credentials are missing in config.conf" >&2
    exit 1
fi

# Default message if none provided
STYLE="${TAG:-${VIDEO_STYLE:-${KEYWORDS:-lofi beats}}}"

# Generate tweet with ChatGPT if available and no custom message
if [ -z "$MESSAGE" ] && [ -n "$OPENAI_API_KEY" ] && command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    PROMPT="Write a short enthusiastic tweet inviting people to watch our new $STYLE video on YouTube. Include this URL if provided: $VIDEO_URL"
    RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{\"model\":\"${OPENAI_MODEL:-gpt-3.5-turbo}\",\"messages\":[{\"role\":\"user\",\"content\":\"$PROMPT\"}],\"max_tokens\":60}")
    MESSAGE=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' | tr -d '\r')
fi

if [ -z "$MESSAGE" ]; then
    if [ -n "$VIDEO_URL" ]; then
        MESSAGE="New $STYLE video uploaded! Watch here: $VIDEO_URL"
    else
        MESSAGE="Enjoy our latest $STYLE content!"
    fi
fi

export TWITTER_API_KEY TWITTER_API_SECRET TWITTER_ACCESS_TOKEN TWITTER_ACCESS_SECRET TWEET_MESSAGE="$MESSAGE"

python3 - <<'PY'
import os
try:
    import tweepy
except ImportError:
    import subprocess, sys
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', '--quiet', 'tweepy'])
    import tweepy

api_key = os.environ['TWITTER_API_KEY']
api_secret = os.environ['TWITTER_API_SECRET']
access_token = os.environ['TWITTER_ACCESS_TOKEN']
access_secret = os.environ['TWITTER_ACCESS_SECRET']
message = os.environ['TWEET_MESSAGE']

auth = tweepy.OAuth1UserHandler(api_key, api_secret, access_token, access_secret)
api = tweepy.API(auth)
api.update_status(status=message)
PY
