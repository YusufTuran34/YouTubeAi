#!/bin/bash
# generate_thumbnail_from_video.sh - config.sh üzerinden belirlenen video dosyasından thumbnail üretir

CONFIG_FILE="${1:-$(dirname "$0")/config.sh}"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "HATA: Konfigürasyon dosyası bulunamadı: $CONFIG_FILE" >&2
    exit 1
fi

if [ -z "$OUTPUT_VIDEO" ]; then
    echo "HATA: VIDEO_FILE config.sh içinde tanımlı değil." >&2
    exit 1
fi

THUMBNAIL_OUTPUT="${THUMBNAIL_FILE:-thumbnail.jpg}"

if [ ! -f "$OUTPUT_VIDEO" ]; then
    echo "HATA: Video dosyası bulunamadı: $OUTPUT_VIDEO" >&2
    exit 1
fi

echo "🎞 Thumbnail oluşturuluyor: $THUMBNAIL_OUTPUT"
ffmpeg -y -i "$OUTPUT_VIDEO" -ss 00:00:01.000 -vframes 1 "$THUMBNAIL_OUTPUT"

if [ $? -eq 0 ]; then
    echo "✅ Thumbnail başarıyla oluşturuldu: $THUMBNAIL_OUTPUT"
else
    echo "❌ Thumbnail oluşturulamadı!" >&2
    exit 1
fi
