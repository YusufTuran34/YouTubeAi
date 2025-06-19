#!/bin/bash
# post_to_twitter.sh - Tweet using twurl (no login required after first setup)

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

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
  MESSAGE="$TITLE\n$DESCRIPTION"
fi

# Mesajı tek satıra çevir (Twitter API için)
MESSAGE=$(echo "$MESSAGE" | tr '\n' ' ')

# twurl ile tweet at
RESPONSE=$(twurl -d "status=$MESSAGE" "/1.1/statuses/update.json" 2>&1)

# Sonucu kontrol et
if echo "$RESPONSE" | grep -q '"id"'; then
  TWEET_ID=$(echo "$RESPONSE" | jq -r '.id_str')
  USER_SCREEN_NAME=$(echo "$RESPONSE" | jq -r '.user.screen_name')
  echo "✅ Tweet başarıyla gönderildi!"
  echo "🔗 Link: https://twitter.com/$USER_SCREEN_NAME/status/$TWEET_ID"
else
  echo "❌ Tweet gönderilemedi!"
  echo "🔍 Response: $RESPONSE"
  exit 1
fi
