#!/bin/bash
# post_to_twitter.sh - Tweet using Twitter OAuth2 with PKCE (Fast & Auto token refresh)

echo "🐦 TWITTER POST BAŞLATILIYOR"
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_OVERRIDE=""
source "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"

# Hızlı token kontrolü
echo "🔍 Token durumu kontrol ediliyor..."
if [ -f "$SCRIPT_DIR/check_twitter_token.sh" ]; then
  if ! bash "$SCRIPT_DIR/check_twitter_token.sh" 2>/dev/null; then
    echo "❌ Token geçersiz veya expire olmuş."
    echo "📝 Yeni authorization code almak için:"
    echo "   bash sh_scripts/get_twitter_auth_code.sh '$TWITTER_CLIENT_ID'"
    exit 1
  fi
fi

# Access token'ı oku
ACCESS_TOKEN=""
if [ -f "$SCRIPT_DIR/twitter_access_token.txt" ]; then
  ACCESS_TOKEN=$(cat "$SCRIPT_DIR/twitter_access_token.txt")
  echo "✅ Access token okundu"
else
  echo "❌ Access token bulunamadı"
  exit 1
fi

# Tweet mesajı
MESSAGE="Automated tweet test from shell script with PKCE - $(date)"

# JSON güvenli hale getir
JSON_PAYLOAD=$(printf '%s' "$MESSAGE" | jq -Rs '{text: .}')

echo "📤 Tweet gönderiliyor: $MESSAGE"

# Tweet gönder (timeout ile)
RESPONSE=$(timeout 30 curl -s -X POST "https://api.twitter.com/2/tweets" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD")

# Timeout kontrolü
if [ $? -eq 124 ]; then
  echo "⏰ Tweet gönderme zaman aşımına uğradı"
  exit 1
fi

# Response kontrolü
ERROR=$(echo "$RESPONSE" | jq -r '.errors[0].message // empty')
if [ -n "$ERROR" ]; then
  echo "❌ Tweet gönderme hatası: $ERROR"
  echo "⚠️  Token geçersiz olabilir, yeni authorization code gerekli."
  exit 1
fi

TWEET_ID=$(echo "$RESPONSE" | jq -r '.data.id')
echo "✅ Tweet başarıyla gönderildi!"
echo "🆔 Tweet ID: $TWEET_ID"
echo "📝 Mesaj: $MESSAGE"
echo "🔗 Link: https://twitter.com/user/status/$TWEET_ID"
