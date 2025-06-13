#!/bin/bash
# post_to_twitter.sh - Post a tweet about the uploaded video or stream

CONFIG_FILE="${1:-$(dirname "$0")/config.conf}"
MESSAGE="$2"

if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
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
if [ -z "$MESSAGE" ]; then
    STYLE="${VIDEO_STYLE:-${KEYWORDS:-lofi beats}}"
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
