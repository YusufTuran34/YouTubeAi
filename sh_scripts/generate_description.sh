#!/bin/bash
# generate_description.sh - Video süresine göre SEO uyumlu açıklama üretir

CONFIG_FILE="${1:-$(dirname "$0")/config.sh}"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Config dosyası bulunamadı!" >&2
    exit 1
fi

if [ ! -f "$VIDEO_FILE" ]; then
    echo "Video dosyası bulunamadı: $VIDEO_FILE" >&2
    exit 1
fi

DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE")
DURATION_INT=${DURATION%.*}

# Varyasyon seçimi
if [ "$DURATION_INT" -lt 900 ]; then
  PURPOSE="Ideal for quick tasks and short focus sessions."
elif [ "$DURATION_INT" -lt 2700 ]; then
  PURPOSE="Perfect for studying, writing, and deep focus."
elif [ "$DURATION_INT" -lt 5400 ]; then
  PURPOSE="Stay productive with this extended LoFi mix."
else
  PURPOSE="A long-format LoFi stream to help you stay in flow all day."
fi

cat <<EOF
🎧 LoFi Focus Music 🎧

$PURPOSE

This music is designed to help you concentrate, stay calm, and stay focused.

All music used is copyright-safe and sourced from Jamendo under Creative Commons (CC BY) license.

📌 Tags: LoFi, Chillhop, Study Music, Focus Beats, Productivity, No Copyright Music

#lofi #focusmusic #studymusic #chillbeats
EOF
