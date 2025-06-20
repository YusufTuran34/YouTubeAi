#!/bin/bash
# install_twurl.sh - Install twurl CLI tool for Twitter automation

echo "🐦 TWURL CLI TOOL YÜKLENİYOR"
echo "============================="

# Check if Ruby is installed
if ! command -v ruby &> /dev/null; then
    echo "❌ Ruby bulunamadı"
    echo "💡 Ruby yükleyin: brew install ruby"
    exit 1
fi

echo "✅ Ruby mevcut: $(ruby --version)"

# Check if gem is available
if ! command -v gem &> /dev/null; then
    echo "❌ Ruby gem bulunamadı"
    echo "💡 Ruby gem yükleyin"
    exit 1
fi

echo "✅ Ruby gem mevcut"

# Install twurl
echo "📦 Twurl yükleniyor..."
if gem install twurl; then
    echo "✅ Twurl başarıyla yüklendi!"
else
    echo "❌ Twurl yüklenemedi"
    echo "💡 Sudo ile deneyin: sudo gem install twurl"
    exit 1
fi

# Check if twurl is working
if command -v twurl &> /dev/null; then
    echo "✅ Twurl çalışıyor: $(twurl --version)"
else
    echo "❌ Twurl PATH'te bulunamadı"
    echo "💡 Terminal'i yeniden başlatın"
    exit 1
fi

echo ""
echo "🎯 TWURL KURULUMU TAMAMLANDI!"
echo "============================="
echo "🔧 Kullanım:"
echo "   twurl authorize --consumer-key KEY --consumer-secret SECRET"
echo "   twurl -d 'status=Test tweet' /1.1/statuses/update.json"
echo ""
echo "💡 İlk kullanımda PIN kodu gerekebilir" 