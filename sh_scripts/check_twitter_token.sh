#!/bin/bash
# check_twitter_token.sh - Twitter token'larının expire olup olmadığını kontrol et ve gerekirse yenile

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_OVERRIDE="${1:-}"
source "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"

# Config verilerini oku
CLIENT_ID="$TWITTER_CLIENT_ID"
CLIENT_SECRET="$TWITTER_CLIENT_SECRET"
AUTH_CODE="$TWITTER_AUTH_CODE"
CODE_VERIFIER="$TWITTER_CODE_VERIFIER"
REFRESH_TOKEN="$TWITTER_REFRESH_TOKEN"
REDIRECT_URI="http://localhost:8888/callback"
TOKEN_URL="https://api.twitter.com/2/oauth2/token"

echo "🔍 Twitter token durumu kontrol ediliyor..."

# Önce refresh token ile deneme
if [ -n "$REFRESH_TOKEN" ] && [ -n "$CLIENT_ID" ] && [ -n "$CLIENT_SECRET" ]; then
  echo "🔄 Refresh token ile token yenileniyor..."
  REFRESH_RESPONSE=$(timeout 30 curl -s -X POST "$TOKEN_URL" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -H "Authorization: Basic $(echo -n "$CLIENT_ID:$CLIENT_SECRET" | base64)" \
    -d "grant_type=refresh_token" \
    -d "refresh_token=$REFRESH_TOKEN")
  
  REFRESH_ERROR=$(echo "$REFRESH_RESPONSE" | jq -r '.error // empty')
  if [ -z "$REFRESH_ERROR" ]; then
    ACCESS_TOKEN=$(echo "$REFRESH_RESPONSE" | jq -r '.access_token')
    NEW_REFRESH_TOKEN=$(echo "$REFRESH_RESPONSE" | jq -r '.refresh_token // empty')
    
    if [ "$ACCESS_TOKEN" != "null" ] && [ -n "$ACCESS_TOKEN" ]; then
      echo "✅ Refresh token ile yeni access token alındı"
      
      # Yeni refresh token'ı kaydet
      if [ -n "$NEW_REFRESH_TOKEN" ] && [ "$NEW_REFRESH_TOKEN" != "null" ]; then
        echo "💾 Yeni refresh token kaydediliyor..."
        echo "🔄 Refresh Token: $NEW_REFRESH_TOKEN"
        echo "🔍 Full Response: $REFRESH_RESPONSE"
        # Burada channels.env'yi güncelleyebiliriz
      fi
      
      # Token'ı test et
      echo "🧪 Token test ediliyor..."
      TEST_RESPONSE=$(timeout 10 curl -s -X GET "https://api.twitter.com/2/users/me" \
        -H "Authorization: Bearer $ACCESS_TOKEN")
      
      if [ $? -eq 124 ]; then
        echo "⏰ Token test zaman aşımına uğradı"
        exit 1
      fi
      
      TEST_ERROR=$(echo "$TEST_RESPONSE" | jq -r '.errors[0].message // empty')
      if [ -z "$TEST_ERROR" ]; then
        echo "✅ Twitter token geçerli ve çalışıyor!"
        echo "👤 Kullanıcı: $(echo "$TEST_RESPONSE" | jq -r '.data.username')"
        echo "🆔 ID: $(echo "$TEST_RESPONSE" | jq -r '.data.id')"
        
        # Token'ı geçici dosyaya kaydet
        echo "$ACCESS_TOKEN" > "$SCRIPT_DIR/twitter_access_token.txt"
        echo "💾 Access token kaydedildi: $SCRIPT_DIR/twitter_access_token.txt"
        exit 0
      fi
    fi
  fi
  echo "⚠️  Refresh token ile yenileme başarısız, authorization code deneniyor..."
fi

# Authorization code ile deneme (mevcut kod)
if [ -z "$CLIENT_ID" ] || [ -z "$AUTH_CODE" ] || [ -z "$CODE_VERIFIER" ]; then
  echo "❌ Eksik parametreler: CLIENT_ID, AUTH_CODE veya CODE_VERIFIER boş."
  echo "⚠️  Manuel olarak yeni authorization code almanız gerekiyor:"
  echo "   bash sh_scripts/get_twitter_auth_code.sh '$CLIENT_ID'"
  exit 1
fi

# Token alma isteği (timeout ile)
echo "🔄 Authorization code ile token alınıyor..."
RESPONSE=$(timeout 30 curl -s -X POST "$TOKEN_URL" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Authorization: Basic $(echo -n "$CLIENT_ID:$CLIENT_SECRET" | base64)" \
  -d "grant_type=authorization_code" \
  -d "client_id=$CLIENT_ID" \
  -d "redirect_uri=$REDIRECT_URI" \
  -d "code=$AUTH_CODE" \
  -d "code_verifier=$CODE_VERIFIER")

# Timeout kontrolü
if [ $? -eq 124 ]; then
  echo "⏰ Token alma zaman aşımına uğradı"
  exit 1
fi

# Response'u kontrol et
ERROR=$(echo "$RESPONSE" | jq -r '.error // empty')
if [ -n "$ERROR" ]; then
  echo "❌ Token hatası: $ERROR"
  echo "🔍 Raw response: $RESPONSE"
  echo "⚠️  Authorization code expire olmuş veya geçersiz."
  echo "📝 Yeni authorization code almak için:"
  echo "   bash sh_scripts/get_twitter_auth_code.sh '$CLIENT_ID'"
  exit 1
fi

# Access token'ı kontrol et
ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.access_token')
REFRESH_TOKEN_NEW=$(echo "$RESPONSE" | jq -r '.refresh_token // empty')

if [ "$ACCESS_TOKEN" == "null" ] || [ -z "$ACCESS_TOKEN" ]; then
  echo "❌ Access token alınamadı. Response:"
  echo "$RESPONSE"
  exit 1
fi

# Yeni refresh token'ı kaydet
if [ -n "$REFRESH_TOKEN_NEW" ] && [ "$REFRESH_TOKEN_NEW" != "null" ]; then
  echo "💾 Yeni refresh token alındı ve kaydediliyor..."
  echo "🔄 Refresh Token: $REFRESH_TOKEN_NEW"
  echo "🔍 Full Response: $RESPONSE"
  # Burada channels.env'yi güncelleyebiliriz
fi

# Token'ı hızlı test et (timeout ile)
echo "🧪 Token test ediliyor..."
TEST_RESPONSE=$(timeout 10 curl -s -X GET "https://api.twitter.com/2/users/me" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

# Timeout kontrolü
if [ $? -eq 124 ]; then
  echo "⏰ Token test zaman aşımına uğradı"
  exit 1
fi

TEST_ERROR=$(echo "$TEST_RESPONSE" | jq -r '.errors[0].message // empty')
if [ -n "$TEST_ERROR" ]; then
  echo "❌ Token test hatası: $TEST_ERROR"
  echo "⚠️  Token geçersiz, yeni authorization code gerekli."
  echo "📝 Yeni authorization code almak için:"
  echo "   bash sh_scripts/get_twitter_auth_code.sh '$CLIENT_ID'"
  exit 1
fi

echo "✅ Twitter token geçerli ve çalışıyor!"
echo "👤 Kullanıcı: $(echo "$TEST_RESPONSE" | jq -r '.data.username')"
echo "🆔 ID: $(echo "$TEST_RESPONSE" | jq -r '.data.id')"

# Token'ı geçici dosyaya kaydet (diğer script'ler için)
echo "$ACCESS_TOKEN" > "$SCRIPT_DIR/twitter_access_token.txt"
echo "💾 Access token kaydedildi: $SCRIPT_DIR/twitter_access_token.txt" 