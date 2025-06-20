#!/bin/bash
# post_to_twitter.sh - Tweet using Twitter API v2 with Refresh Token (Fully Automatic)

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Load Twitter credentials
source "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}"

# Twitter API v2 bilgileri
CLIENT_ID="$TWITTER_CLIENT_ID"
CLIENT_SECRET="$TWITTER_CLIENT_SECRET"
AUTH_CODE="$TWITTER_AUTH_CODE"
CODE_VERIFIER="$TWITTER_CODE_VERIFIER"

echo "🔍 Twitter API v2 bilgileri kontrol ediliyor..."

# Gerekli parametreleri kontrol et
if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
  echo "❌ Eksik Twitter API bilgileri!"
  exit 1
fi

echo "✅ Twitter API bilgileri mevcut"

# Refresh token dosyası
REFRESH_TOKEN_FILE="$SCRIPT_DIR/twitter_refresh_token.txt"

# Refresh token varsa kullan, yoksa authorization code ile al
if [ -f "$REFRESH_TOKEN_FILE" ]; then
  REFRESH_TOKEN=$(cat "$REFRESH_TOKEN_FILE")
  echo "🔄 Mevcut refresh token kullanılıyor..."
  
  # Refresh token ile access token al
  TOKEN_RESPONSE=$(curl -s -X POST "https://api.twitter.com/2/oauth2/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Authorization: Basic $(echo -n "$CLIENT_ID:$CLIENT_SECRET" | base64)" \
    -d "grant_type=refresh_token" \
    -d "refresh_token=$REFRESH_TOKEN")
  
  ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')
  NEW_REFRESH_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.refresh_token // empty')
  
  if [ "$ACCESS_TOKEN" == "null" ] || [ -z "$ACCESS_TOKEN" ]; then
    echo "⚠️  Refresh token geçersiz, yeni authorization code ile yenileniyor..."
    rm -f "$REFRESH_TOKEN_FILE"
  else
    echo "✅ Refresh token ile access token alındı"
    # Yeni refresh token'ı kaydet
    if [ -n "$NEW_REFRESH_TOKEN" ] && [ "$NEW_REFRESH_TOKEN" != "null" ]; then
      echo "$NEW_REFRESH_TOKEN" > "$REFRESH_TOKEN_FILE"
      echo "💾 Yeni refresh token kaydedildi"
    fi
  fi
fi

# Eğer refresh token yoksa veya geçersizse, authorization code kullan
if [ ! -f "$REFRESH_TOKEN_FILE" ] || [ "$ACCESS_TOKEN" == "null" ] || [ -z "$ACCESS_TOKEN" ]; then
  if [ -z "$AUTH_CODE" ] || [ -z "$CODE_VERIFIER" ]; then
    echo "❌ Authorization code eksik! Yeni authorization code almanız gerekiyor."
    echo "📝 Komut: bash get_twitter_auth_code.sh '$CLIENT_ID'"
    exit 1
  fi
  
  echo "🔄 Authorization code ile refresh token alınıyor..."
  
  # Authorization code ile access token ve refresh token al
  TOKEN_RESPONSE=$(curl -s -X POST "https://api.twitter.com/2/oauth2/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Authorization: Basic $(echo -n "$CLIENT_ID:$CLIENT_SECRET" | base64)" \
    -d "grant_type=authorization_code" \
    -d "client_id=$CLIENT_ID" \
    -d "redirect_uri=http://localhost:8888/callback" \
    -d "code=$AUTH_CODE" \
    -d "code_verifier=$CODE_VERIFIER")
  
  ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')
  REFRESH_TOKEN_NEW=$(echo "$TOKEN_RESPONSE" | jq -r '.refresh_token // empty')
  
  if [ "$ACCESS_TOKEN" == "null" ] || [ -z "$ACCESS_TOKEN" ]; then
    echo "❌ Access token alınamadı"
    echo "🔍 Response: $TOKEN_RESPONSE"
    exit 1
  fi
  
  # Refresh token'ı kaydet (gelecek kullanım için)
  if [ -n "$REFRESH_TOKEN_NEW" ] && [ "$REFRESH_TOKEN_NEW" != "null" ]; then
    echo "$REFRESH_TOKEN_NEW" > "$REFRESH_TOKEN_FILE"
    echo "💾 Refresh token kaydedildi - artık tam otomatik!"
  fi
  
  echo "✅ Authorization code ile access token alındı"
fi

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
  MESSAGE="Automated tweet from pipeline - $(date)"
else
  MESSAGE="$TITLE $DESCRIPTION"
fi

# Mesajı kısalt (Twitter 280 karakter limiti)
if [ ${#MESSAGE} -gt 280 ]; then
  MESSAGE="${MESSAGE:0:277}..."
fi

echo "📤 Tweet gönderiliyor: $MESSAGE"

# Tweet gönder (OAuth 2.0 User Context)
JSON_PAYLOAD=$(printf '%s' "$MESSAGE" | jq -Rs '{text: .}')

RESPONSE=$(curl -s -X POST "https://api.twitter.com/2/tweets" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD")

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
echo "🎉 Artık tam otomatik! Bir daha authorization code girmeye gerek yok."
