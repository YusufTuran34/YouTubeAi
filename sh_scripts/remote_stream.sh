#!/bin/bash
# remote_stream.sh - Sunucuda çalışır, gerekli ortamı kurar ve yayını başlatır

CONFIG_FILE="config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Konfigürasyon dosyası bulunamadı!" >&2
    exit 1
fi

RTMP_URL="${YOUTUBE_STREAM_URL}/${YOUTUBE_STREAM_KEY}"

echo ">> Önceki ffmpeg süreçleri kontrol ediliyor..."
if pgrep -f "ffmpeg -re -i" > /dev/null; then
    echo ">> Mevcut yayın tespit edildi. Durduruluyor..."
    pkill -f "ffmpeg -re -i"
    sleep 2
fi

echo ">> Yayın başlatılıyor..."
while true; do
  ffmpeg -re -i "$REMOTE_DIR/$(basename "$OUTPUT_VIDEO")" \
    -c:v libx264 -preset ultrafast -maxrate 7500k -bufsize 15000k \
    -pix_fmt yuv420p -c:a aac -b:a 160k -f flv "$RTMP_URL"
  echo ">> Yayın bitti. 5 saniye sonra tekrar başlayacak..."
  sleep 5
done
