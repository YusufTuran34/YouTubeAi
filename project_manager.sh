#!/bin/bash
# project_manager.sh - Ana proje yönetim scripti

ACTION="${1:-help}"

case "$ACTION" in
  "clean")
    echo "🧹 Proje temizleniyor..."
    cd sh_scripts && ./auto_cleanup.sh
    ;;
  "deep-clean")
    echo "🔥 DERİN TEMİZLİK BAŞLATILIYOR..."
    echo "🧹 Otomatik temizlik çalıştırılıyor..."
    cd sh_scripts && ./auto_cleanup.sh
    cd ..
    echo "🗑️ Geçici dosyalar temizleniyor..."
    rm -rf /tmp/chrome_profile_* 2>/dev/null || true
    rm -rf /tmp/tmp.* 2>/dev/null || true
    rm -rf sh_scripts/ai_generated_background_* 2>/dev/null || true
    rm -rf sh_scripts/runway_generated_background_* 2>/dev/null || true
    echo "📁 Build cache temizleniyor..."
    ./gradlew clean 2>/dev/null || true
    echo "🔧 System processes kontrol ediliyor..."
    pkill -f "java.*SchedulerApplication" 2>/dev/null || true
    pkill -f chromedriver 2>/dev/null || true
    pkill -f chrome 2>/dev/null || true
    lsof -ti:8080 | xargs kill -9 2>/dev/null || true
    echo "✅ Derin temizlik tamamlandı!"
    ;;
  "test")
    echo "🧪 Hızlı testler çalıştırılıyor..."
    cd sh_scripts && ./quick_test.sh "${2:-all}"
    ;;
  "start")
    echo "🚀 Proje başlatılıyor..."
    echo "🔥 Derin temizlik yapılıyor..."
    $0 deep-clean
    echo "⏳ 5 saniye güvenlik bekleniyor..."
    sleep 5
    echo "🎯 Spring Boot başlatılıyor..."
    ./gradlew bootRun --no-daemon
    ;;
  "restart")
    echo "🔄 Proje yeniden başlatılıyor..."
    $0 deep-clean
    echo "⏳ 10 saniye güvenlik bekleniyor..."
    sleep 10
    $0 start
    ;;
  "status")
    echo "📊 Proje durumu kontrol ediliyor..."
    echo ""
    echo "🌐 Port 8080 durumu:"
    lsof -i:8080 || echo "❌ Port 8080 boş"
    echo ""
    echo "☕ Java süreçleri:"
    ps aux | grep -E "(java|gradle)" | grep -v grep || echo "❌ Java süreçi yok"
    echo ""
    echo "🔧 Chrome süreçleri:"
    ps aux | grep -E "(chrome|chromedriver)" | grep -v grep || echo "✅ Chrome süreçi yok"
    ;;
  "logs")
    echo "📋 Son log dosyaları:"
    find . -name "*.log" -mtime -1 2>/dev/null | head -5
    ;;
  "help")
    echo "🎯 PROJE YÖNETİM SİSTEMİ"
    echo "========================"
    echo ""
    echo "Kullanım: $0 [komut] [parametre]"
    echo ""
    echo "Komutlar:"
    echo "  clean     - Sistem temizliği (Chrome, Java, port)"
    echo "  deep-clean - Derin temizlik (Chrome, Java, port)"
    echo "  test      - Hızlı testler (tweet, horoscope, lofi, config, all)"
    echo "  start     - Projeyi başlat (temizlik + start)"
    echo "  restart   - Projeyi yeniden başlat"
    echo "  status    - Sistem durumunu kontrol et"
    echo "  logs      - Son log dosyalarını göster"
    echo "  help      - Bu yardım mesajını göster"
    echo ""
    echo "Örnekler:"
    echo "  $0 clean              # Sistem temizliği"
    echo "  $0 deep-clean         # Derin temizlik"
    echo "  $0 test tweet         # Sadece tweet testi"
    echo "  $0 test all           # Tüm testler"
    echo "  $0 start              # Projeyi başlat"
    echo "  $0 restart            # Yeniden başlat"
    ;;
  *)
    echo "❌ Geçersiz komut: $ACTION"
    echo "Yardım için: $0 help"
    exit 1
    ;;
esac 