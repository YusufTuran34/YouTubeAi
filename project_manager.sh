#!/bin/bash
# project_manager.sh - Ana proje yönetim scripti

ACTION="${1:-help}"

case "$ACTION" in
  "clean")
    echo "🧹 Proje temizleniyor..."
    cd sh_scripts && ./utilities/auto_cleanup.sh
    ;;
  "deep-clean")
    echo "🔥 DERİN TEMİZLİK BAŞLATILIYOR..."
    echo "🧹 Otomatik temizlik çalıştırılıyor..."
    cd sh_scripts && ./utilities/auto_cleanup.sh
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
    cd sh_scripts && ./utilities/quick_test.sh "${2:-all}"
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
  # NEW WORKFLOW COMMANDS USING NEW ARCHITECTURE
  "workflow")
    echo "🎬 Workflow çalıştırılıyor..."
    cd sh_scripts
    shift # Remove "workflow" from arguments
    ./orchestrators/run_workflow.sh "$@"
    ;;
  "social")
    echo "📱 Hızlı sosyal medya paylaşımı..."
    cd sh_scripts
    ./orchestrators/quick_social_post.sh "${2:-lofi}" "${3:-}"
    ;;
  "video")
    echo "🎥 Tam video pipeline..."
    cd sh_scripts
    ./orchestrators/full_video_pipeline.sh "${2:-lofi}" "${3:-default}"
    ;;
  "channels")
    echo "📋 Mevcut kanallar:"
    cd sh_scripts
    ./core/channel_manager.sh
    ;;
  "pipeline-status")
    echo "📊 Pipeline durumu:"
    cd sh_scripts
    ./core/pipeline_manager.sh list "${2:-10}"
    ;;
  "pipeline-cleanup")
    echo "🧹 Eski pipeline logları temizleniyor..."
    cd sh_scripts
    ./core/pipeline_manager.sh cleanup "${2:-7}"
    ;;
  "help")
    echo "🎯 PROJE YÖNETİM SİSTEMİ"
    echo "========================"
    echo ""
    echo "Kullanım: $0 [komut] [parametre]"
    echo ""
    echo "🔧 Sistem Komutları:"
    echo "  clean     - Sistem temizliği (Chrome, Java, port)"
    echo "  deep-clean - Derin temizlik (Chrome, Java, port)"
    echo "  test      - Hızlı testler (tweet, horoscope, lofi, config, all)"
    echo "  start     - Projeyi başlat (temizlik + start)"
    echo "  restart   - Projeyi yeniden başlat"
    echo "  status    - Sistem durumunu kontrol et"
    echo "  logs      - Son log dosyalarını göster"
    echo ""
    echo "🎬 Yeni Workflow Komutları:"
    echo "  workflow <type> <channel> [content] [params] - Tam workflow çalıştır"
    echo "  social [content_type] [zodiac_sign]          - Hızlı sosyal medya paylaşımı"
    echo "  video [content_type] [channel]               - Tam video pipeline"
    echo "  channels                                     - Mevcut kanalları listele"
    echo "  pipeline-status [count]                      - Pipeline durumunu göster"
    echo "  pipeline-cleanup [days]                      - Eski logları temizle"
    echo ""
    echo "🎯 Workflow Türleri:"
    echo "  video_upload   - Video oluşturma ve YouTube yükleme"
    echo "  social_only    - Sadece sosyal medya içeriği"
    echo "  full_pipeline  - Tam içerik pipeline'ı"
    echo "  stream_workflow - Canlı yayın workflow'ı"
    echo ""
    echo "📋 Mevcut Kanallar:"
    echo "  default, youtube_only, social_only, minimal, test_channel"
    echo ""
    echo "🎨 İçerik Türleri:"
    echo "  lofi, horoscope, meditation"
    echo ""
    echo "📖 Örnekler:"
    echo "  $0 clean                              # Sistem temizliği"
    echo "  $0 test all                           # Tüm testler"
    echo "  $0 social lofi                        # Hızlı LoFi tweet"
    echo "  $0 social horoscope aries             # Koç burcu horoskopu"
    echo "  $0 video lofi default                 # LoFi video pipeline"
    echo "  $0 workflow video_upload youtube_only lofi  # YouTube'a LoFi video"
    echo "  $0 workflow social_only minimal horoscope zodiac_sign=gemini"
    echo "  $0 channels                           # Kanal listesi"
    echo "  $0 pipeline-status 5                  # Son 5 pipeline"
    ;;
  *)
    echo "❌ Geçersiz komut: $ACTION"
    echo "Yardım için: $0 help"
    exit 1
    ;;
esac 