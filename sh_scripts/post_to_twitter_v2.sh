#!/bin/bash
# post_to_twitter_v2.sh - Tweet using Twitter API v2 (No login required)

echo "🐦 TWITTER V2 POST BAŞLATILIYOR"
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_OVERRIDE=""
source "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"

# Twitter API v2 bilgileri
API_KEY="$TWITTER_API_KEY"
API_SECRET="$TWITTER_API_SECRET"
ACCESS_TOKEN="$TWITTER_ACCESS_TOKEN"
ACCESS_SECRET="$TWITTER_ACCESS_SECRET"

echo "🔍 Twitter API v2 bilgileri kontrol ediliyor..."

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

# Bearer Token oluştur (Base64 encoded API_KEY:API_SECRET)
BEARER_TOKEN=$(echo -n "$API_KEY:$API_SECRET" | base64)

echo "🔑 Bearer Token oluşturuldu"

# Tweet mesajı
MESSAGE="Automated tweet from shell script using Twitter API v2 - $(date)"

echo "📤 Tweet gönderiliyor: $MESSAGE"

# Tweet gönder
RESPONSE=$(curl -s -X POST "https://api.twitter.com/2/tweets" \
  -H "Authorization: Bearer $BEARER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"$MESSAGE\"}")

echo "🔍 Raw response: $RESPONSE"

# Response kontrolü
ERROR=$(echo "$RESPONSE" | jq -r '.errors[0].message // empty')
if [ -n "$ERROR" ]; then
  echo "❌ Tweet gönderme hatası: $ERROR"
  echo "🔍 Raw response: $RESPONSE"
  exit 1
fi

# Başarılı response
TWEET_ID=$(echo "$RESPONSE" | jq -r '.data.id')
TWEET_TEXT=$(echo "$RESPONSE" | jq -r '.data.text')

echo "✅ Tweet başarıyla gönderildi!"
echo "🆔 Tweet ID: $TWEET_ID"
echo "📝 Mesaj: $TWEET_TEXT"
echo "🔗 Link: https://twitter.com/i/status/$TWEET_ID" 