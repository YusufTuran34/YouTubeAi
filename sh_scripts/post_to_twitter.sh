#!/bin/bash
# post_to_twitter.sh - Tweet using Twitter OAuth2 with PKCE

echo "SEND TWIT INITIALIZE"
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_OVERRIDE=""
source "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"

# Config verilerini oku
CLIENT_ID="$TWITTER_CLIENT_ID"
CLIENT_SECRET="$TWITTER_CLIENT_SECRET"
AUTH_CODE="$TWITTER_AUTH_CODE"
CODE_VERIFIER="$TWITTER_CODE_VERIFIER"
REDIRECT_URI="http://localhost:8888/callback"
TOKEN_URL="https://api.twitter.com/2/oauth2/token"


# Kodlar eksikse çık
if [ -z "$CLIENT_ID" ] || [ -z "$AUTH_CODE" ] || [ -z "$CODE_VERIFIER" ]; then
  echo "❌ Eksik parametreler: CLIENT_ID, AUTH_CODE veya CODE_VERIFIER boş."
  exit 1
fi

# Token alma isteği (Authorization header ile, body'de client_secret yok)
BASIC_AUTH=$(echo -n "$CLIENT_ID:$CLIENT_SECRET" | base64)

RESPONSE=$(curl -s -X POST "$TOKEN_URL" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Authorization: Basic $BASIC_AUTH" \
  -d "grant_type=authorization_code" \
  -d "client_id=$CLIENT_ID" \
  -d "redirect_uri=$REDIRECT_URI" \
  -d "code=$AUTH_CODE" \
  -d "code_verifier=$CODE_VERIFIER")

# Token kontrol
ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.access_token')
if [ "$ACCESS_TOKEN" == "null" ] || [ -z "$ACCESS_TOKEN" ]; then
  echo "❌ Failed to get access token. Response:"
  echo "$RESPONSE"
  exit 1
fi

echo "[DEBUG] Token response:"
echo "$RESPONSE"

# Tweet mesajı
MESSAGE="Automated tweet test from shell script with PKCE"

# JSON güvenli hale getir
JSON_PAYLOAD=$(printf '%s' "$MESSAGE" | jq -Rs '{text: .}')

# Tweet gönder
curl -s -X POST "https://api.twitter.com/2/tweets" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD"

echo -e "\n✅ Tweet sent: $MESSAGE"
