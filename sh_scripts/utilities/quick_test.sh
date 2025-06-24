#!/bin/bash
# quick_test.sh - Hızlı test sistemi

TEST_TYPE="${1:-all}"

echo "🚀 HIZLI TEST SİSTEMİ"
echo "===================="

case "$TEST_TYPE" in
  "tweet")
    echo "📝 Tweet Generation Test..."
    ./generate_tweet_advanced.sh lofi
    echo ""
    ./generate_tweet_advanced.sh horoscope aries
    ;;
  "horoscope")
    echo "🔮 Horoscope Test..."
    python3 post_to_twitter_simple.py horoscope aries
    ;;
  "lofi")
    echo "🎵 LoFi Test..."
    python3 post_to_twitter_simple.py lofi
    ;;
  "config")
    echo "⚙️ Config Test..."
    source common.sh
    load_channel_config "default"
    echo "✅ OPENAI_API_KEY: ${OPENAI_API_KEY:0:10}..."
    echo "✅ TWITTER_EMAIL: $TWITTER_EMAIL"
    ;;
  "all")
    echo "🔄 Tüm testler çalıştırılıyor..."
    echo ""
    echo "1️⃣ Config testi..."
    $0 config
    echo ""
    echo "2️⃣ Tweet generation testi..."
    $0 tweet
    echo ""
    echo "3️⃣ Horoscope testi..."
    $0 horoscope
    echo ""
    echo "4️⃣ LoFi testi..."
    $0 lofi
    ;;
  *)
    echo "❌ Geçersiz test tipi: $TEST_TYPE"
    echo "Kullanım: $0 [tweet|horoscope|lofi|config|all]"
    exit 1
    ;;
esac

echo ""
echo "✅ Test tamamlandı!" 