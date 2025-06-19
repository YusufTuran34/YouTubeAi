#!/bin/bash
# post_to_twitter_v1.sh - Tweet using Twitter API v1.1 (No login required)

echo "🐦 TWITTER V1.1 POST BAŞLATILIYOR"
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_OVERRIDE=""
source "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"

# Twitter API v1.1 bilgileri
API_KEY="$TWITTER_API_KEY"
API_SECRET="$TWITTER_API_SECRET"
ACCESS_TOKEN="$TWITTER_ACCESS_TOKEN"
ACCESS_SECRET="$TWITTER_ACCESS_SECRET"

echo "🔍 Twitter API v1.1 bilgileri kontrol ediliyor..."

# Gerekli parametreleri kontrol et
if [ -z "$API_KEY" ] || [ -z "$API_SECRET" ] || [ -z "$ACCESS_TOKEN" ] || [ -z "$ACCESS_SECRET" ]; then
  echo "❌ Eksik Twitter API bilgileri!"
  echo "   API_KEY: $API_KEY"
  echo "   API_SECRET: $API_SECRET"
  echo "   ACCESS_TOKEN: $ACCESS_TOKEN"
  echo "   ACCESS_SECRET: $ACCESS_SECRET"
  exit 1
fi

echo "✅ Twitter API bilgileri mevcut"

# Tweet mesajı
MESSAGE="Automated tweet from shell script using Twitter API v1.1 - $(date)"

echo "📤 Tweet gönderiliyor: $MESSAGE"

# OAuth1.0a signature oluştur
TIMESTAMP=$(date +%s)
NONCE=$(openssl rand -hex 16)

# OAuth parametreleri
OAUTH_PARAMS="oauth_consumer_key=$API_KEY"
OAUTH_PARAMS="$OAUTH_PARAMS&oauth_nonce=$NONCE"
OAUTH_PARAMS="$OAUTH_PARAMS&oauth_signature_method=HMAC-SHA1"
OAUTH_PARAMS="$OAUTH_PARAMS&oauth_timestamp=$TIMESTAMP"
OAUTH_PARAMS="$OAUTH_PARAMS&oauth_token=$ACCESS_TOKEN"
OAUTH_PARAMS="$OAUTH_PARAMS&oauth_version=1.0"

# Tweet parametreleri
TWEET_PARAMS="status=$(echo "$MESSAGE" | sed 's/ /%20/g')"

# Signature base string oluştur
METHOD="POST"
URL="https://api.twitter.com/1.1/statuses/update.json"
PARAM_STRING="$OAUTH_PARAMS&$TWEET_PARAMS"
SIGNATURE_BASE="$METHOD&$(echo "$URL" | sed 's/:/%3A/g' | sed 's/\//%2F/g')&$(echo "$PARAM_STRING" | sed 's/:/%3A/g' | sed 's/\//%2F/g' | sed 's/=/%3D/g' | sed 's/&/%26/g')"

# Signature oluştur
SIGNING_KEY="$API_SECRET&$ACCESS_SECRET"
SIGNATURE=$(echo -n "$SIGNATURE_BASE" | openssl dgst -sha1 -hmac "$SIGNING_KEY" -binary | openssl base64 | sed 's/+/%2B/g' | sed 's/\//%2F/g' | sed 's/=/%3D/g')

# Authorization header oluştur
AUTH_HEADER="OAuth oauth_consumer_key=\"$API_KEY\",oauth_nonce=\"$NONCE\",oauth_signature=\"$SIGNATURE\",oauth_signature_method=\"HMAC-SHA1\",oauth_timestamp=\"$TIMESTAMP\",oauth_token=\"$ACCESS_TOKEN\",oauth_version=\"1.0\""

# Tweet gönder
RESPONSE=$(curl -s -X POST "https://api.twitter.com/1.1/statuses/update.json" \
  -H "Authorization: $AUTH_HEADER" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "$TWEET_PARAMS")

# Response kontrolü
ERROR=$(echo "$RESPONSE" | jq -r '.errors[0].message // empty')
if [ -n "$ERROR" ]; then
  echo "❌ Tweet gönderme hatası: $ERROR"
  echo "🔍 Raw response: $RESPONSE"
  exit 1
fi

# Başarılı response
TWEET_ID=$(echo "$RESPONSE" | jq -r '.id')
TWEET_TEXT=$(echo "$RESPONSE" | jq -r '.text')
USER_SCREEN_NAME=$(echo "$RESPONSE" | jq -r '.user.screen_name')

echo "✅ Tweet başarıyla gönderildi!"
echo "🆔 Tweet ID: $TWEET_ID"
echo "👤 Kullanıcı: @$USER_SCREEN_NAME"
echo "📝 Mesaj: $TWEET_TEXT"
echo "🔗 Link: https://twitter.com/$USER_SCREEN_NAME/status/$TWEET_ID" 