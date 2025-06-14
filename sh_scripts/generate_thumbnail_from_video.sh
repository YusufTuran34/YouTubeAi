#!/bin/sh
# generate_thumbnail_from_video.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_OVERRIDE="${1:-}"
. "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"

# Ensure OUTPUT_VIDEO is set and exists
if [ -z "$OUTPUT_VIDEO" ] || [ ! -f "$OUTPUT_VIDEO" ]; then
  echo "❌ HATA: OUTPUT_VIDEO tanımlı değil veya dosya bulunamadı: $OUTPUT_VIDEO" >&2
  exit 1
fi

# Determine thumbnail output file
THUMBNAIL_OUTPUT="${THUMBNAIL_FILE:-thumbnail.jpg}"

echo "🎞 Thumbnail oluşturuluyor: $THUMBNAIL_OUTPUT"
ffmpeg -y -i "$OUTPUT_VIDEO" \
  -frames:v 1 -update 1 \
  -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
  -q:v 2 "$THUMBNAIL_OUTPUT" >/dev/null 2>&1

if [ $? -eq 0 ] && [ -f "$THUMBNAIL_OUTPUT" ]; then
  echo "✅ Thumbnail başarıyla oluşturuldu: $THUMBNAIL_OUTPUT"
  exit 0
else
  echo "❌ Thumbnail oluşturulamadı!" >&2
  exit 1
fi
