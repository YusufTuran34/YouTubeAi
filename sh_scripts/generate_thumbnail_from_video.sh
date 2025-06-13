#!/bin/bash
# generate_thumbnail_from_video.sh - base.conf ve kanal ayarlarını kullanarak video dosyasından thumbnail üretir

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_OVERRIDE="${1:-}"
source "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"
if [ -z "$OUTPUT_VIDEO" ]; then
    echo "HATA: OUTPUT_VIDEO tanımlı değil." >&2
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
