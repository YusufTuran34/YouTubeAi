#!/bin/bash
# post_to_twitter_v2.sh - Tweet using Twitter API v2 (No login required)

echo "🐦 TWITTER V2 POST BAŞLATILIYOR"
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_OVERRIDE=""
source "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"

# Twitter API v2 bilgileri (OAuth 2.0 User Context)
CLIENT_ID="$TWITTER_CLIENT_ID"
CLIENT_SECRET="$TWITTER_CLIENT_SECRET"
AUTH_CODE="$TWITTER_AUTH_CODE"
CODE_VERIFIER="$TWITTER_CODE_VERIFIER"

echo "🔍 Twitter API v2 bilgileri kontrol ediliyor..."

# Gerekli parametreleri kontrol et
if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ] || [ -z "$AUTH_CODE" ] || [ -z "$CODE_VERIFIER" ]; then
  echo "❌ Eksik Twitter API bilgileri!"
  echo "   CLIENT_ID: $CLIENT_ID"
  echo "   CLIENT_SECRET: $CLIENT_SECRET"
  echo "   AUTH_CODE: $AUTH_CODE"
  echo "   CODE_VERIFIER: $CODE_VERIFIER"
  exit 1
fi

echo "✅ Twitter API bilgileri mevcut"

# Tweet mesajını oluştur
TITLE=""
DESCRIPTION=""
if [ -f generated_title.txt ]; then
  TITLE=$(head -n 1 generated_title.txt)
fi
if [ -f generated_description.txt ]; then
  DESCRIPTION=$(head -n 1 generated_description.txt)
fi
if [ -z "$TITLE" ] && [ -z "$DESCRIPTION" ]; then
  MESSAGE="Automated tweet from shell script using Twitter API v2 - $(date)"
else
  MESSAGE="$TITLE $DESCRIPTION"
fi

# Mesajı kısalt (Twitter 280 karakter limiti)
if [ ${#MESSAGE} -gt 280 ]; then
  MESSAGE="${MESSAGE:0:277}..."
fi

echo "📤 Tweet gönderiliyor: $MESSAGE"

# Access token al (OAuth 2.0 PKCE)
TOKEN_RESPONSE=$(curl -s -X POST "https://api.twitter.com/2/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Authorization: Basic $(echo -n "$CLIENT_ID:$CLIENT_SECRET" | base64)" \
  -d "grant_type=authorization_code" \
  -d "client_id=$CLIENT_ID" \
  -d "redirect_uri=http://localhost:8888/callback" \
  -d "code=$AUTH_CODE" \
  -d "code_verifier=$CODE_VERIFIER")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

if [ "$ACCESS_TOKEN" == "null" ] || [ -z "$ACCESS_TOKEN" ]; then
  echo "❌ Access token alınamadı"
  echo "🔍 Response: $TOKEN_RESPONSE"
  exit 1
fi

echo "🔑 Access token alındı"

# Tweet gönder (OAuth 2.0 User Context)
JSON_PAYLOAD=$(printf '%s' "$MESSAGE" | jq -Rs '{text: .}')

RESPONSE=$(curl -s -X POST "https://api.twitter.com/2/tweets" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD")

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