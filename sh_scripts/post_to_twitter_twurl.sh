#!/bin/bash
# post_to_twitter_twurl.sh - Post tweet using twurl CLI tool

source ./common.sh

echo "🐦 TWITTER TWURL POST BAŞLATILIYOR"
echo "=================================="

# Check if twurl is installed
if ! command -v twurl &> /dev/null; then
    echo "❌ Twurl bulunamadı"
    echo "💡 Önce twurl yükleyin: ./install_twurl.sh"
    exit 1
fi

echo "✅ Twurl mevcut"

# Load Twitter credentials
load_twitter_credentials

# Check if credentials are available
if [ -z "$TWITTER_API_KEY" ] || [ -z "$TWITTER_API_SECRET" ]; then
    echo "❌ Twitter API bilgileri eksik"
    echo "💡 channels.env dosyasını kontrol edin"
    exit 1
fi

echo "✅ Twitter API bilgileri mevcut"

# Get tweet message
get_tweet_message
echo "📝 Tweet mesajı: $TWEET_MESSAGE"

# Check if already authorized
echo "🔐 Yetkilendirme kontrol ediliyor..."
if twurl account; then
    echo "✅ Zaten yetkilendirilmiş"
else
    echo "🔐 Yetkilendirme gerekli..."
    echo "💡 PIN kodu gerekebilir"
    
    if twurl authorize --consumer-key "$TWITTER_API_KEY" --consumer-secret "$TWITTER_API_SECRET"; then
        echo "✅ Yetkilendirme başarılı!"
    else
        echo "❌ Yetkilendirme başarısız"
        exit 1
    fi
fi

# Post tweet
echo "📤 Tweet gönderiliyor..."
if twurl -d "status=$TWEET_MESSAGE" /1.1/statuses/update.json; then
    echo "✅ Tweet başarıyla gönderildi!"
    
    # Get the response
    RESPONSE=$(twurl -d "status=$TWEET_MESSAGE" /1.1/statuses/update.json 2>/dev/null)
    
    if [ ! -z "$RESPONSE" ]; then
        echo "📊 Yanıt: $RESPONSE"
        
        # Extract tweet ID if possible
        TWEET_ID=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | cut -d':' -f2)
        if [ ! -z "$TWEET_ID" ]; then
            echo "🆔 Tweet ID: $TWEET_ID"
            echo "🔗 Link: https://twitter.com/i/status/$TWEET_ID"
        fi
    fi
else
    echo "❌ Tweet gönderilemedi"
    exit 1
fi

echo "�� İşlem tamamlandı!" 