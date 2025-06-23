#!/bin/bash
# quick_manual_tweet.sh - Manuel tweet için hızlı helper

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Son oluşturulan tweet içeriğini al
if [ -f "generated_tweet.txt" ]; then
    TWEET_TEXT=$(cat generated_tweet.txt)
else
    TWEET_TEXT="Yeni video yayında! #LoFi #StudyMusic #ChillBeats"
fi

# Son video URL'ini al
if [ -f "latest_video_url.txt" ]; then
    VIDEO_URL=$(cat latest_video_url.txt)
else
    VIDEO_URL="https://youtube.com/watch?v=EXAMPLE"
fi

echo "🐦 MANUEL TWEET HELPER"
echo "====================="
echo ""
echo "📋 Hazır Tweet İçeriği:"
echo "------------------------"
echo "$TWEET_TEXT"
echo ""
echo "🔗 Video URL: $VIDEO_URL"
echo ""
echo "📱 Manuel Posting İçin:"
echo "1. https://x.com/compose/post adresine git"
echo "2. Yukarıdaki tweet içeriğini kopyala"
echo "3. Tweet kutusuna yapıştır"
echo "4. Tweet'i gönder"
echo ""
echo "📋 Tweet panoya kopyalandı (macOS):"

# macOS clipboard'a kopyala
echo "$TWEET_TEXT" | pbcopy 2>/dev/null || echo "Clipboard copy failed"

echo "✅ Tweet içeriği hazır!" 