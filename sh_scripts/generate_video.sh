#!/bin/bash
# generate_video.sh - FFmpeg kullanarak arkaplan videosu ve müziklerle output video oluşturma

echo ">> Önceki geçici dosyalar temizleniyor..."
rm -f /tmp/audio_list.txt /tmp/audio_list_ext.txt
rm -rf /tmp/video_folder
rm -f "$OUTPUT_VIDEO"

CONFIG_FILE="${1:-$(dirname "$0")/config.conf}"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Konfigürasyon dosyası bulunamadı: $CONFIG_FILE" >&2
    exit 1
fi

TARGET_SECONDS=$(echo "$VIDEO_DURATION_HOURS * 3600" | bc)
TARGET_SECONDS=${TARGET_SECONDS%.*}  # Virgülden sonrasını at
AUDIO_LIST_EXTENDED="/tmp/audio_list_ext.txt"
mkdir -p "$MUSIC_DIR"

# Arkaplan videosunu belirle
VIDEO_FILE=""
if [ "${USE_GOOGLE_DRIVE:-0}" -eq 1 ] && [ -n "$DRIVE_FOLDER_ID" ]; then
    echo ">> Google Drive klasöründen video indiriliyor..."
    VIDEO_TEMP_DIR="/tmp/video_folder"
    mkdir -p "$VIDEO_TEMP_DIR"
    gdown --folder "https://drive.google.com/drive/folders/${DRIVE_FOLDER_ID}" -O "$VIDEO_TEMP_DIR"
    SELECTED_VIDEO=$(find "$VIDEO_TEMP_DIR" -type f -iname '*.mp4' | shuf -n 1)
    if [ -n "$SELECTED_VIDEO" ]; then
        VIDEO_FILE="$SELECTED_VIDEO"
        echo ">> Seçilen video: $VIDEO_FILE"
    fi
fi

if [ -z "$VIDEO_FILE" ]; then
    if [ -n "$BACKGROUND_VIDEO" ] && [ -f "$BACKGROUND_VIDEO" ]; then
        VIDEO_FILE="$BACKGROUND_VIDEO"
        echo ">> Belirtilen arkaplan videosu kullanılacak: $VIDEO_FILE"
    elif [ -d "$VIDEO_SOURCE_DIR" ]; then
        echo ">> $VIDEO_SOURCE_DIR içinden rastgele arkaplan videosu seçiliyor..."
        SELECTED_VIDEO=$(find "$VIDEO_SOURCE_DIR" -type f -iname '*.mp4' | shuf -n 1)
        if [ -n "$SELECTED_VIDEO" ]; then
            VIDEO_FILE="$SELECTED_VIDEO"
            echo ">> Seçilen arkaplan videosu: $VIDEO_FILE"
        fi
    fi
fi

if [ -z "$VIDEO_FILE" ]; then
    echo "HATA: Arkaplan videosu için kaynak bulunamadı. Google Drive, BACKGROUND_VIDEO veya VIDEO_SOURCE_DIR tanımlı olmalı." >&2
    exit 1
fi

# Müzikleri Jamendo üzerinden indir (eğer aktifse)
if [ "${USE_JAMENDO:-0}" -eq 1 ] && [ -n "$CLIENT_ID" ]; then
    echo ">> Jamendo API'den müzik indiriliyor..."
    mkdir -p "$MUSIC_DIR"
    response=$(curl -s "https://api.jamendo.com/v3.0/tracks/?client_id=$CLIENT_ID&format=json&tags=$TAG&limit=100&audioformat=mp31&license_cc=by")
    if [ -z "$response" ]; then
        echo "HATA: Jamendo API yanıtı boş." >&2
        exit 1
    fi

    total_duration=0
    echo "$response" | jq -c '.results[]' | while read -r track; do
        duration=$(echo "$track" | jq '.duration')
        title=$(echo "$track" | jq -r '.name')
        artist=$(echo "$track" | jq -r '.artist_name')
        mp3_url=$(echo "$track" | jq -r '.audio')
        safe_title=$(echo "${artist}-${title}" | tr -dc '[:alnum:]._-')
        output_file="$MUSIC_DIR/$safe_title.mp3"

        if [ ! -f "$output_file" ]; then
            echo ">> İndiriliyor: $output_file"
            curl -s -L "$mp3_url" -o "$output_file"
        fi

        if [ -f "$output_file" ]; then
            dur=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$output_file")
            dur_int=${dur%.*}
            total_duration=$((total_duration + dur_int))
            echo "Toplam süre: $total_duration saniye"
            if [ "$total_duration" -ge "$TARGET_SECONDS" ]; then
                echo ">> Yeterli müzik indirildi."
                break
            fi
        fi
    done
fi

# Müzik dosyalarını kontrol et
echo ">> Müzik dosyaları hazırlanıyor..."
mp3_count=$(find "$MUSIC_DIR" -type f -iname '*.mp3' | wc -l)
if [ "$mp3_count" -eq 0 ]; then
    echo "HATA: $MUSIC_DIR dizininde .mp3 dosyası bulunamadı. Lütfen en az bir müzik dosyası ekleyin." >&2
    exit 1
fi

# Ses listesi oluştur (şarkıları tekrar ederek hedef süreye ulaş)
total_duration=0
> "$AUDIO_LIST_EXTENDED"
while [ $total_duration -lt $TARGET_SECONDS ]; do
    for f in $(find "$MUSIC_DIR" -type f -iname '*.mp3' | sort); do
        dur=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$f")
        dur_int=${dur%.*}
        total_duration=$(( total_duration + dur_int ))
        realpath_file="$(realpath "$f")"
        echo "file '$realpath_file'" >> "$AUDIO_LIST_EXTENDED"
        if [ $total_duration -ge $TARGET_SECONDS ]; then
            break
        fi
    done
done
echo ">> Toplam müzik süresi: $total_duration saniye"

# FFmpeg ile videoyu oluştur
echo ">> FFmpeg ile $VIDEO_DURATION_HOURS saatlik video oluşturuluyor ($OUTPUT_VIDEO)..."
ffmpeg -y -stream_loop -1 -i "$VIDEO_FILE" \
    -f concat -safe 0 -i "$AUDIO_LIST_EXTENDED" \
    -map 0:v -map 1:a \
    -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2,fps=${GIF_FPS:-30}" \
    -c:v ${VIDEO_CODEC:-libx264} -preset ${PRESET:-ultrafast} -pix_fmt yuv420p \
    -c:a ${AUDIO_CODEC:-aac} -b:a ${AUDIO_BITRATE:-160k} \
    -t "$TARGET_SECONDS" "$OUTPUT_VIDEO"

if [ $? -ne 0 ]; then
    echo "FFmpeg video oluşturma işlemi başarısız oldu!" >&2
    exit 1
fi

echo ">> Video başarıyla oluşturuldu: $OUTPUT_VIDEO"
