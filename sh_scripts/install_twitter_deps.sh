#!/bin/bash
# install_twitter_deps.sh - Install Python dependencies for Twitter automation

echo "🐍 PYTHON TWITTER BAĞIMLILIKLARI YÜKLENİYOR"

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "📦 Virtual environment oluşturuluyor..."
    python3 -m venv .venv
fi

# Activate virtual environment
echo "🔧 Virtual environment aktifleştiriliyor..."
source .venv/bin/activate

# Install required packages
echo "📥 Gerekli paketler yükleniyor..."

# Tweepy for Twitter API v1.1
echo "📦 Tweepy yükleniyor..."
pip install tweepy

# Selenium for web automation
echo "📦 Selenium yükleniyor..."
pip install selenium

# Additional useful packages
echo "📦 Ek paketler yükleniyor..."
pip install requests
pip install beautifulsoup4

echo "✅ Tüm paketler başarıyla yüklendi!"
echo ""
echo "🔧 Kullanım:"
echo "   Tweepy ile tweet: python3 post_to_twitter_tweepy.py"
echo "   Selenium ile tweet: python3 post_to_twitter_selenium.py"
echo ""
echo "💡 Not: Selenium için Chrome ve ChromeDriver gerekli" 