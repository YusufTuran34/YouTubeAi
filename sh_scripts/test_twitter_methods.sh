#!/bin/bash
# test_twitter_methods.sh - Test both Twitter automation methods

echo "🧪 TWITTER OTOMASYON YÖNTEMLERİ TEST EDİLİYOR"
echo "=============================================="

# Activate virtual environment
source .venv/bin/activate

# Create test tweet message
echo "Test tweet from automation script - $(date)" > generated_title.txt
echo "Testing both Tweepy and Selenium methods for Twitter automation" > generated_description.txt

echo ""
echo "🔧 1. TWEEPY (Twitter API v1.1) TEST EDİLİYOR"
echo "---------------------------------------------"

if python3 post_to_twitter_tweepy.py; then
    echo "✅ Tweepy başarılı!"
    TWEEPY_SUCCESS=true
else
    echo "❌ Tweepy başarısız"
    TWEEPY_SUCCESS=false
fi

echo ""
echo "🔧 2. SELENIUM (Web Otomasyonu) TEST EDİLİYOR"
echo "---------------------------------------------"

if python3 post_to_twitter_selenium.py; then
    echo "✅ Selenium başarılı!"
    SELENIUM_SUCCESS=true
else
    echo "❌ Selenium başarısız"
    SELENIUM_SUCCESS=false
fi

echo ""
echo "📊 TEST SONUÇLARI"
echo "================="

if [ "$TWEEPY_SUCCESS" = true ]; then
    echo "✅ Tweepy: ÇALIŞIYOR"
else
    echo "❌ Tweepy: ÇALIŞMIYOR"
fi

if [ "$SELENIUM_SUCCESS" = true ]; then
    echo "✅ Selenium: ÇALIŞIYOR"
else
    echo "❌ Selenium: ÇALIŞMIYOR"
fi

echo ""
echo "💡 ÖNERİLER:"
if [ "$TWEEPY_SUCCESS" = true ]; then
    echo "   🎯 Tweepy kullanın - API tabanlı, hızlı"
elif [ "$SELENIUM_SUCCESS" = true ]; then
    echo "   🎯 Selenium kullanın - Web otomasyonu, API limiti yok"
else
    echo "   ⚠️ Her iki yöntem de başarısız. Manuel kontrol gerekli."
fi

echo ""
echo "🔧 Kullanım komutları:"
echo "   Tweepy: python3 post_to_twitter_tweepy.py"
echo "   Selenium: python3 post_to_twitter_selenium.py" 