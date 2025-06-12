#!/bin/bash
# generate_title.sh - Videonun süresine göre LoFi başlık üretir

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

TITLE="LoFi Focus Music"

if [ "$DURATION_INT" -lt 900 ]; then
    TITLE="Quick Focus Beats - LoFi for Short Tasks"
elif [ "$DURATION_INT" -lt 2700 ]; then
    TITLE="Deep Work LoFi Vibes - 30 Min Focus Music"
elif [ "$DURATION_INT" -lt 5400 ]; then
    TITLE="Study Session LoFi Mix - 1 Hour of Focus"
else
    VARIANTS=("24/7 LoFi Focus Radio" "Ultimate Chill Mix for Studying" "LoFi Ambience for Productivity")
    TITLE="${VARIANTS[$RANDOM % ${#VARIANTS[@]}]}"
fi

echo "$TITLE"