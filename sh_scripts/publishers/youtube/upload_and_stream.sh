#!/bin/bash
# upload_and_stream.sh - output.mp4 ve remote_stream.sh dosyasını sunucuya gönderip yayın başlatır

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_OVERRIDE="${1:-}"
source "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"

LATEST_FILE="$SCRIPT_DIR/latest_output_video.txt"
[ -f "$LATEST_FILE" ] && OUTPUT_VIDEO="$(cat "$LATEST_FILE")"

RTMP_URL="${YOUTUBE_STREAM_URL}/${YOUTUBE_STREAM_KEY}"

if [ ! -f "$OUTPUT_VIDEO" ]; then
    echo "HATA: Yüklenecek video dosyası bulunamadı: $OUTPUT_VIDEO" >&2
    exit 1
fi
if [ ! -f "$PEM_FILE" ]; then
    echo "HATA: PEM anahtar dosyası bulunamadı: $PEM_FILE" >&2
    exit 1
fi

LOCAL_CONFIG_FILE="${CONFIG_OVERRIDE:-$SCRIPT_DIR/configs/base.conf}"
LOCAL_ENV_FILE="${CHANNEL_ENV_FILE:-$SCRIPT_DIR/channels.env}"

echo ">> Dosyalar sunucuya gönderiliyor..."
ssh -i "$PEM_FILE" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_DIR/configs"
scp -i "$PEM_FILE" "$OUTPUT_VIDEO" remote_stream.sh common.sh "$LOCAL_ENV_FILE" "$LATEST_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/"
scp -i "$PEM_FILE" "$LOCAL_CONFIG_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/configs/base.conf"
if [ $? -ne 0 ]; then
    echo "HATA: Dosya gönderimi başarısız oldu!" >&2
    exit 1
fi

echo ">> Yayın başlatılıyor (remote_stream.sh)..."
ssh -i "$PEM_FILE" "$REMOTE_USER@$REMOTE_HOST" CHANNEL="${CHANNEL:-default}" bash -c "cd $REMOTE_DIR && bash remote_stream.sh configs/base.conf"
