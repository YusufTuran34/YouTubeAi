#!/bin/bash
# get_twitter_auth_code.sh - Twitter OAuth2 PKCE ile yeni authorization code al

set -e

# Config
CLIENT_ID="$1"
REDIRECT_URI="http://localhost:8888/callback"
SCOPE="tweet.write tweet.read users.read offline.access"
STATE="state$(date +%s)"

# PKCE için code_verifier ve code_challenge üret
CODE_VERIFIER=$(openssl rand -base64 32 | tr -d '=+/')
CODE_CHALLENGE=$(echo -n "$CODE_VERIFIER" | openssl dgst -sha256 -binary | openssl base64 | tr -d '=+/')

# Yetkilendirme linki oluştur
AUTH_URL="https://twitter.com/i/oauth2/authorize?response_type=code&client_id=$CLIENT_ID&redirect_uri=$REDIRECT_URI&scope=$(echo $SCOPE | sed 's/ /%20/g')&state=$STATE&code_challenge=$CODE_CHALLENGE&code_challenge_method=S256"

echo "1. Tarayıcında aşağıdaki linki aç ve giriş yaparak izin ver:"
echo "$AUTH_URL"
echo
read -p "2. Tarayıcıdan yönlendirme sonrası URL'deki 'code' parametresini buraya yapıştır: " AUTH_CODE

# Code verifier'ı dosyaya kaydet
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "$CODE_VERIFIER" > "$SCRIPT_DIR/twitter_auth_code.txt"

echo
cat <<EOF
---
TWITTER_AUTH_CODE='$AUTH_CODE'
TWITTER_CODE_VERIFIER='$CODE_VERIFIER'
---
Bunları channels.env dosyasındaki ilgili alanlara ekleyin.
EOF 