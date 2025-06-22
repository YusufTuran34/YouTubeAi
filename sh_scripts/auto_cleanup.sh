#!/bin/bash
# auto_cleanup.sh - Otomatik sistem temizliği

echo "🧹 OTOMATIK TEMİZLİK BAŞLATILIYOR..."

# Chrome süreçlerini temizle
echo "🔄 Chrome süreçleri temizleniyor..."
pkill -f chrome 2>/dev/null || true
pkill -f chromedriver 2>/dev/null || true

# Geçici profilleri temizle
echo "📁 Geçici profiller temizleniyor..."
rm -rf /tmp/chrome_profile_* 2>/dev/null || true

# Port 8080'i temizle
echo "🌐 Port 8080 temizleniyor..."
lsof -ti:8080 | xargs kill -9 2>/dev/null || true

# Java süreçlerini temizle
echo "☕ Java süreçleri temizleniyor..."
pkill -f "java.*SchedulerApplication" 2>/dev/null || true

# Gradle daemon'ları temizle
echo "🔧 Gradle daemon'ları temizleniyor..."
./gradlew --stop 2>/dev/null || true

echo "✅ Otomatik temizlik tamamlandı!"
echo "🚀 Artık güvenle projeyi başlatabilirsin: ./gradlew bootRun --no-daemon" 