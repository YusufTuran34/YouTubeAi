#!/bin/bash
# YouTube Video Yükleme Otomasyon Script'i

set -e
set -x

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.conf"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "HATA: config.conf bulunamadı! Lütfen script ile aynı dizine koyun ve ayarları yapın."
  exit 1
fi
. "$CONFIG_FILE"

if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ] || [ -z "$REFRESH_TOKEN" ]; then
  echo "HATA: OAuth2 API bilgileri eksik."
  exit 1
fi

if [ -z "$OUTPUT_VIDEO" ] then
  echo "HATA: Video bilgileri eksik."
  exit 1
fi

VIDEO_PATH="$OUTPUT_VIDEO"
THUMB_PATH="$THUMBNAIL_FILE"
[[ "$VIDEO_PATH" != /* ]] && VIDEO_PATH="$SCRIPT_DIR/$VIDEO_PATH"
[[ "$THUMB_PATH" != /* ]] && THUMB_PATH="$SCRIPT_DIR/$THUMB_PATH"
if [ ! -f "$VIDEO_PATH" ]; then
  echo "HATA: Video dosyası bulunamadı: $VIDEO_PATH"
  exit 1
fi

if [ -z "$VIDEO_DESCRIPTION" ]; then
  echo "⚠️  VIDEO_DESCRIPTION boş, otomatik oluşturuluyor..."
  VIDEO_DESCRIPTION=$(sh "$SCRIPT_DIR/generate_description.sh" "$CONFIG_FILE")
  if [ -z "$VIDEO_DESCRIPTION" ]; then
    echo "HATA: VIDEO_DESCRIPTION üretilemedi!"
    exit 1
  fi
fi

# Thumbnail eksikse otomatik oluştur
if [ -n "$THUMB_PATH" ] && [ ! -f "$THUMB_PATH" ]; then
  echo "⚠️  Thumbnail dosyası bulunamadı, otomatik oluşturuluyor..."
  sh "$SCRIPT_DIR/generate_thumbnail_from_video.sh" "$CONFIG_FILE"

  if [ ! -f "$THUMB_PATH" ]; then
    echo "HATA: Thumbnail oluşturulamadı: $THUMB_PATH"
    exit 1
  fi
fi

# VIDEO_TITLE eksikse otomatik oluştur
if [ -n "$VIDEO_TITLE" ] && [ ! -f "$VIDEO_TITLE" ]; then
  echo "⚠️  VIDEO_TITLE dosyası bulunamadı, otomatik oluşturuluyor..."
  sh "$SCRIPT_DIR/generate_title.sh" "$CONFIG_FILE"

  if [ ! -f "$VIDEO_TITLE" ]; then
    echo "HATA: VIDEO_TITLE oluşturulamadı: $VIDEO_TITLE"
    exit 1
  fi
fi

echo "OAuth2 token alınıyor..."
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

echo "Yükleme oturumu başlatılıyor..."
API_URL="https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status"
TITLE_ESCAPED=$(echo "$VIDEO_TITLE" | sed 's/"/\"/g')
DESC_ESCAPED=$(echo "$VIDEO_DESCRIPTION" | sed 's/"/\"/g')
[ -z "$VIDEO_CATEGORY" ] && VIDEO_CATEGORY="22"
[ -z "$VIDEO_PRIVACY" ] && VIDEO_PRIVACY="unlisted"
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

TMP_RES_FILE=$(mktemp)
HTTP_CODE=$(curl -s -X PUT \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: video/*" \
    --data-binary "@$VIDEO_PATH" \
    -o "$TMP_RES_FILE" -w "%{http_code}" \
    "$UPLOAD_URL")
if [ "$HTTP_CODE" -ne 200 ] && [ "$HTTP_CODE" -ne 201 ]; then
  echo "HATA: Video yükleme başarısız (HTTP $HTTP_CODE)."
  cat "$TMP_RES_FILE"
  rm -f "$TMP_RES_FILE"
  exit 1
fi
UPLOAD_RESPONSE="$(cat "$TMP_RES_FILE")"
rm -f "$TMP_RES_FILE"
VIDEO_ID=$(echo "$UPLOAD_RESPONSE" | grep -m1 '"id":' | sed 's/.*"id": *"\([^"]*\)".*/\1/')
if [ -z "$VIDEO_ID" ]; then
  echo "HATA: Video ID alınamadı!"
  exit 1
fi
echo "Video ID: $VIDEO_ID"

if [ -n "$THUMB_PATH" ]; then
  echo "Thumbnail yükleniyor: $THUMB_PATH ..."
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
  echo "Thumbnail başarıyla yüklendi."
fi

echo "✅ Video yüklendi! YouTube Link: https://youtu.be/$VIDEO_ID"
