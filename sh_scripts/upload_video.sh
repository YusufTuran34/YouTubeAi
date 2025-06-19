#!/bin/bash
# YouTube Video Yükleme Otomasyon Script'i
escape_json() {
  printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read())[1:-1])'
}
set -e
set -x
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_OVERRIDE="${1:-}"
source "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"
CONFIG_FILE="$CONFIG_OVERRIDE"

LATEST_FILE="$SCRIPT_DIR/latest_output_video.txt"
[ -f "$LATEST_FILE" ] && OUTPUT_VIDEO="$(cat "$LATEST_FILE")"
echo "VIDEO LATEST_FILE :$LATEST_FILE "
if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ] || [ -z "$REFRESH_TOKEN" ]; then
  echo "HATA: OAuth2 API bilgileri eksik."
  exit 1
fi

if [ -z "$OUTPUT_VIDEO" ]; then
  echo "HATA: Video bilgileri eksik."
  exit 1
fi

VIDEO_PATH="$OUTPUT_VIDEO"
THUMB_PATH="$THUMBNAIL_FILE"

# If relative, try current working directory first, then fall back to script dir
if [[ "$VIDEO_PATH" != /* ]]; then
  if [ -f "$VIDEO_PATH" ]; then
    VIDEO_PATH="$(realpath "$VIDEO_PATH")"
  else
    VIDEO_PATH="$SCRIPT_DIR/$VIDEO_PATH"
  fi
fi


if [ ! -f "$VIDEO_PATH" ]; then
  echo "HATA: Video dosyası bulunamadı: $VIDEO_PATH"
  exit 1
fi

if [[ "$THUMB_PATH" != /* ]]; then
  if [ -f "$THUMB_PATH" ]; then
    THUMB_PATH="$(realpath "$THUMB_PATH")"
  else
    THUMB_PATH="$SCRIPT_DIR/$THUMB_PATH"
  fi
fi

if [ -z "$VIDEO_DESCRIPTION" ]; then
  echo "⚠️  VIDEO_DESCRIPTION boş, otomatik oluşturuluyor..."
  VIDEO_DESCRIPTION=$(bash "$SCRIPT_DIR/generate_description.sh" "$CONFIG_FILE")
  if [ -z "$VIDEO_DESCRIPTION" ]; then
    echo "HATA: VIDEO_DESCRIPTION üretilemedi!"
    exit 1
  fi
fi

# Thumbnail eksikse otomatik oluştur
if [ -z "$THUMB_PATH" ] || [ ! -f "$THUMB_PATH" ]; then
  echo "⚠️  Thumbnail eksik veya bulunamadı, otomatik oluşturuluyor..."
  bash "$SCRIPT_DIR/generate_thumbnail_from_video.sh" "$CONFIG_FILE"

  if [ ! -f "$THUMB_PATH" ]; then
    echo "HATA: Thumbnail oluşturulamadı: $THUMB_PATH"
    exit 1
  fi
fi

# VIDEO_TITLE eksikse otomatik oluştur
if [ -z "$VIDEO_TITLE" ]; then
  echo "⚠️  VIDEO_TITLE boş, otomatik oluşturuluyor..."
  VIDEO_TITLE=$(bash "$SCRIPT_DIR/generate_title.sh" "$CONFIG_FILE")
  if [ -z "$VIDEO_TITLE" ]; then
    echo "HATA: VIDEO_TITLE oluşturulamadı!"
    exit 1
  fi
fi

ACCESS_TOKEN=$(curl -s -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=$CLIENT_ID" \
    -d "client_secret=$CLIENT_SECRET" \
    -d "refresh_token=$REFRESH_TOKEN" \
    -d "grant_type=refresh_token" \
    "https://accounts.google.com/o/oauth2/token" \
    | awk -F'"' '/access_token/ {print $4}' )
if [ -z "$ACCESS_TOKEN" ]; then
  echo "HATA: Erişim tokenı alınamadı."
  exit 1
fi

API_URL="https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status"
TITLE_ESCAPED=$(escape_json "$VIDEO_TITLE")
DESC_ESCAPED=$(escape_json "$VIDEO_DESCRIPTION")
[ -z "$VIDEO_CATEGORY" ] && VIDEO_CATEGORY="22"
[ -z "$VIDEO_PRIVACY" ] && VIDEO_PRIVACY="private"
JSON_DATA=$(cat <<EOF
{
  "snippet": {
    "title": "$TITLE_ESCAPED",
    "description": "$DESC_ESCAPED",
    "categoryId": "$VIDEO_CATEGORY"
  },
  "status": {
    "privacyStatus": "$VIDEO_PRIVACY"
  }
}
EOF
)

TMP_HDR_FILE=$(mktemp)
HTTP_CODE=$(curl -s -X POST "$API_URL" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json; charset=UTF-8" \
    -d "$JSON_DATA" \
    -o /dev/null -D "$TMP_HDR_FILE" -w "%{http_code}")
if [ "$HTTP_CODE" -ne 200 ] && [ "$HTTP_CODE" -ne 201 ]; then
  echo "HATA: Yükleme oturumu başlatılamadı (HTTP $HTTP_CODE)."
  rm -f "$TMP_HDR_FILE"
  exit 1
fi
UPLOAD_URL=$(grep -i "location:" "$TMP_HDR_FILE" | awk '{print $2}' | tr -d '\r')
rm -f "$TMP_HDR_FILE"
if [ -z "$UPLOAD_URL" ]; then
  echo "HATA: Yükleme URL'i alınamadı."
  exit 1
fi

# Chunked upload için dosya boyutunu al
FILE_SIZE=$(stat -f%z "$VIDEO_PATH" 2>/dev/null || stat -c%s "$VIDEO_PATH" 2>/dev/null)
CHUNK_SIZE=10485760  # 10MB chunks
TOTAL_CHUNKS=$(( (FILE_SIZE + CHUNK_SIZE - 1) / CHUNK_SIZE ))

echo "📁 Video boyutu: $FILE_SIZE bytes"
echo "📦 Chunk boyutu: $CHUNK_SIZE bytes"
echo "🔢 Toplam chunk: $TOTAL_CHUNKS"

# İlk chunk'ı yükle (Content-Range header ile)
FIRST_CHUNK_END=$((CHUNK_SIZE - 1))
if [ $FIRST_CHUNK_END -gt $FILE_SIZE ]; then
  FIRST_CHUNK_END=$((FILE_SIZE - 1))
fi

# İlk chunk'ı geçici dosyaya çıkar
FIRST_CHUNK_FILE=$(mktemp)
dd if="$VIDEO_PATH" of="$FIRST_CHUNK_FILE" bs=$CHUNK_SIZE count=1 2>/dev/null

TMP_RES_FILE=$(mktemp)
HTTP_CODE=$(curl -s -X PUT \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: video/mp4" \
    -H "Content-Range: bytes 0-$FIRST_CHUNK_END/$FILE_SIZE" \
    --data-binary "@$FIRST_CHUNK_FILE" \
    -o "$TMP_RES_FILE" -w "%{http_code}" \
    "$UPLOAD_URL")

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
  echo "✅ Video başarıyla yüklendi!"
  UPLOAD_RESPONSE="$(cat "$TMP_RES_FILE")"
  rm -f "$TMP_RES_FILE" "$FIRST_CHUNK_FILE"
  VIDEO_ID=$(echo "$UPLOAD_RESPONSE" | grep -m1 '"id":' | sed 's/.*"id": *"\([^"]*\)".*/\1/')
  if [ -z "$VIDEO_ID" ]; then
    echo "HATA: Video ID alınamadı!"
    exit 1
  fi
else
  echo "⚠️  Tek seferlik yükleme başarısız (HTTP $HTTP_CODE), chunked upload deneniyor..."
  
  # Chunked upload için dd kullan
  CHUNK_FILE=$(mktemp)
  OFFSET=0
  
  for ((i=1; i<=TOTAL_CHUNKS; i++)); do
    echo "📤 Chunk $i/$TOTAL_CHUNKS yükleniyor..."
    
    # Chunk'ı dosyadan çıkar
    dd if="$VIDEO_PATH" of="$CHUNK_FILE" bs=$CHUNK_SIZE skip=$((OFFSET / CHUNK_SIZE)) count=1 2>/dev/null
    
    CHUNK_SIZE_ACTUAL=$(stat -f%z "$CHUNK_FILE" 2>/dev/null || stat -c%s "$CHUNK_FILE" 2>/dev/null)
    CHUNK_START=$OFFSET
    CHUNK_END=$((OFFSET + CHUNK_SIZE_ACTUAL - 1))
    
    HTTP_CODE=$(curl -s -X PUT \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: video/mp4" \
        -H "Content-Range: bytes $CHUNK_START-$CHUNK_END/$FILE_SIZE" \
        --data-binary "@$CHUNK_FILE" \
        -o "$TMP_RES_FILE" -w "%{http_code}" \
        "$UPLOAD_URL")
    
    if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
      echo "✅ Chunk $i başarıyla yüklendi!"
      UPLOAD_RESPONSE="$(cat "$TMP_RES_FILE")"
      VIDEO_ID=$(echo "$UPLOAD_RESPONSE" | grep -m1 '"id":' | sed 's/.*"id": *"\([^"]*\)".*/\1/')
      if [ -n "$VIDEO_ID" ]; then
        break
      fi
    elif [ "$HTTP_CODE" -eq 308 ]; then
      echo "📤 Chunk $i yüklendi, devam ediliyor..."
      OFFSET=$((OFFSET + CHUNK_SIZE_ACTUAL))
    else
      echo "❌ Chunk $i yükleme hatası (HTTP $HTTP_CODE)"
      cat "$TMP_RES_FILE"
      rm -f "$TMP_RES_FILE" "$CHUNK_FILE" "$FIRST_CHUNK_FILE"
      exit 1
    fi
  done
  
  rm -f "$TMP_RES_FILE" "$CHUNK_FILE" "$FIRST_CHUNK_FILE"
  
  if [ -z "$VIDEO_ID" ]; then
    echo "HATA: Video yükleme tamamlanamadı!"
    exit 1
  fi
fi

if [ -n "$THUMB_PATH" ]; then
  TMP_THUMB_RES=$(mktemp)
  THUMB_URL="https://www.googleapis.com/upload/youtube/v3/thumbnails/set?videoId=${VIDEO_ID}&uploadType=media"
  HTTP_CODE=$(curl -s -X POST \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "Content-Type: image/jpeg" \
      --data-binary "@$THUMB_PATH" \
      -o "$TMP_THUMB_RES" -w "%{http_code}" \
      "$THUMB_URL")
  if [ "$HTTP_CODE" -ne 200 ]; then
    echo "HATA: Thumbnail yüklenemedi (HTTP $HTTP_CODE)."
    cat "$TMP_THUMB_RES"
    rm -f "$TMP_THUMB_RES"
    exit 1
  fi
  rm -f "$TMP_THUMB_RES"
fi

echo "✅ Video yüklendi! YouTube Link: https://youtu.be/$VIDEO_ID"
