#!/bin/bash
# upload_and_stream.sh - output.mp4 ve remote_stream.sh dosyasını sunucuya gönderip yayın başlatır

CONFIG_FILE="${1:-$(dirname "$0")/config.conf}"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Konfigürasyon dosyası bulunamadı: $CONFIG_FILE" >&2
    exit 1
fi

RTMP_URL="${YOUTUBE_STREAM_URL}/${YOUTUBE_STREAM_KEY}"

if [ ! -f "$OUTPUT_VIDEO" ]; then
    echo "HATA: Yüklenecek video dosyası bulunamadı: $OUTPUT_VIDEO" >&2
    exit 1
fi
if [ ! -f "$PEM_FILE" ]; then
    echo "HATA: PEM anahtar dosyası bulunamadı: $PEM_FILE" >&2
    exit 1
fi

echo ">> Dosyalar sunucuya gönderiliyor..."
scp -i "$PEM_FILE" "$OUTPUT_VIDEO" remote_stream.sh config.conf "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/"
if [ $? -ne 0 ]; then
    echo "HATA: Dosya gönderimi başarısız oldu!" >&2
    exit 1
fi

echo ">> Yayın başlatılıyor (remote_stream.sh)..."
ssh -i "$PEM_FILE" "$REMOTE_USER@$REMOTE_HOST" bash -c "cd $REMOTE_DIR && bash remote_stream.sh"
