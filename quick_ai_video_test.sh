#!/bin/bash
# quick_ai_video_test.sh - Hızlı AI Video Generation Test

echo "🎬 AI VIDEO GENERATION TEST"
echo "=========================="

cd sh_scripts

# Test 1: LoFi Video
echo "🎵 1. LoFi Video Test..."
./generate_ai_video_background.sh lofi 2>&1 | head -15
echo ""

# Wait a bit
echo "⏳ 10 saniye bekleniyor..."
sleep 10

# Test 2: Meditation Video  
echo "🧘 2. Meditation Video Test..."
./generate_ai_video_background.sh meditation 2>&1 | head -15
echo ""

# Wait a bit
echo "⏳ 10 saniye bekleniyor..."
sleep 10

# Test 3: Horoscope Video
echo "🔮 3. Horoscope Video Test..."
./generate_ai_video_background.sh horoscope 2>&1 | head -15
echo ""

# Wait for completion
echo "⏳ 20 saniye daha bekleniyor..."
sleep 20

# Check results
echo "📊 SONUÇLAR:"
echo "============"
ls -la ai_generated_background_*.mp4 ai_generated_background_*.gif ai_generated_background_*.png 2>/dev/null | tail -10

echo ""
echo "📹 OLUŞTURULAN DOSYALAR:"
for file in ai_generated_background_*.{mp4,gif,png}; do
    if [ -f "$file" ]; then
        size=$(du -h "$file" | cut -f1)
        echo "✅ $file ($size)"
    fi
done

echo ""
echo "🎯 TEST TAMAMLANDI!"
echo "Videoları açmak için: open ai_generated_background_*.{mp4,gif}" 