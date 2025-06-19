#!/bin/bash
# update_twitter_auth_env.sh - Twitter auth code ve code_verifier'ı channels.env'ye otomatik yaz

set -e

CHANNELS_ENV="$(dirname "$0")/channels.env"
AUTH_URL="$1"
CODE_VERIFIER_FILE="$(dirname "$0")/twitter_auth_code.txt"

if [[ -z "$AUTH_URL" ]]; then
  echo "Kullanım: $0 '<callback_url>'"
  echo "Örnek: $0 'http://localhost:8888/callback?state=...&code=...'
"
  exit 1
fi

# URL'den code parametresini çek
CODE=$(echo "$AUTH_URL" | sed -n 's/.*[?&]code=\([^&]*\).*/\1/p')
if [[ -z "$CODE" ]]; then
  echo "URL'den code parametresi bulunamadı!"
  exit 2
fi

# code_verifier'ı dosyadan al
if [[ ! -f "$CODE_VERIFIER_FILE" ]]; then
  echo "twitter_auth_code.txt bulunamadı!"
  exit 3
fi
CODE_VERIFIER=$(cat "$CODE_VERIFIER_FILE" | head -n1)

# channels.env'de güncelle
TMP_FILE=$(mktemp)
cat "$CHANNELS_ENV" | \
  sed "s/\("TWITTER_AUTH_CODE"[ ]*:[ ]*\)\"[^\"]*\"/\1\"$CODE\"/" | \
  sed "s/\("TWITTER_CODE_VERIFIER"[ ]*:[ ]*\)\"[^\"]*\"/\1\"$CODE_VERIFIER\"/" > "$TMP_FILE"

mv "$TMP_FILE" "$CHANNELS_ENV"
echo "channels.env dosyası güncellendi!"
echo "Yeni TWITTER_AUTH_CODE: $CODE"
echo "Yeni TWITTER_CODE_VERIFIER: $CODE_VERIFIER"

# Config verilerini oku
CLIENT_ID="$TWITTER_CLIENT_ID"
CLIENT_SECRET="$TWITTER_CLIENT_SECRET"
AUTH_CODE="$TWITTER_AUTH_CODE"
CODE_VERIFIER="$TWITTER_CODE_VERIFIER"

echo "DEBUG: CLIENT_ID=$CLIENT_ID"
echo "DEBUG: CLIENT_SECRET=$CLIENT_SECRET"
echo "DEBUG: AUTH_CODE=$AUTH_CODE"
echo "DEBUG: CODE_VERIFIER=$CODE_VERIFIER" 