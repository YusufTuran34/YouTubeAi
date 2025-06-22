#!/bin/bash
# generate_video.sh - FFmpeg kullanarak arkaplan videosu ve müziklerle output video oluşturma

echo ">> Önceki geçici dosyalar temizleniyor..."
rm -f /tmp/audio_list.txt /tmp/audio_list_ext.txt
rm -rf /tmp/video_folder

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_OVERRIDE="${1:-}"
source "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"

LATEST_FILE="$SCRIPT_DIR/latest_output_video.txt"
if [ -f "$LATEST_FILE" ]; then
  OUTPUT_VIDEO="$(cat "$LATEST_FILE")"
else
  DIR="$(dirname "$OUTPUT_VIDEO")"
  BASE="$(basename "$OUTPUT_VIDEO")"
  EXT="${BASE##*.}"
  NAME="${BASE%.*}"
  TIMESTAMP=$(date +'%Y%m%d_%H%M')
  OUTPUT_VIDEO="$DIR/${NAME}_${TIMESTAMP}.${EXT}"
  echo "$OUTPUT_VIDEO" > "$LATEST_FILE"
fi
export OUTPUT_VIDEO

TARGET_SECONDS=$(echo "$VIDEO_DURATION_HOURS * 3600" | bc)
TARGET_SECONDS=${TARGET_SECONDS%.*}  # Virgülden sonrasını at
AUDIO_LIST_EXTENDED="/tmp/audio_list_ext.txt"
mkdir -p "$MUSIC_DIR"

# Arkaplan videosunu belirle
VIDEO_FILE=""

# Content type'ı belirle (parametreden ya da default)
CONTENT_TYPE="${TAG:-lofi}"

# AI Video Background üretme seçeneği (Yeni configuratif sistem)
if [ "${USE_AI_VIDEO_GENERATION:-1}" -eq 1 ]; then
    echo ">> AI ile konfigüratif arkaplan video üretiliyor..."
    echo ">> İçerik türü: $CONTENT_TYPE"
    VIDEO_FILE="$("$SCRIPT_DIR/generate_ai_video_background.sh" "$CONTENT_TYPE" "$CONFIG_OVERRIDE")"
    if [ -n "$VIDEO_FILE" ] && [ -f "$VIDEO_FILE" ]; then
        echo ">> AI üretilen video: $VIDEO_FILE"
    else
        echo ">> AI video üretimi başarısız, alternatif yöntemlere geçiliyor..." >&2
        VIDEO_FILE=""
    fi
fi

# Fallback: OpenAI ile GIF üretme seçeneği (Eski sistem)
if [ -z "$VIDEO_FILE" ] && [ "${USE_OPENAI_GIF:-0}" -eq 1 ]; then
    echo ">> Fallback: OpenAI ile arkaplan GIF'i üretiliyor..."
    VIDEO_FILE="$("$SCRIPT_DIR/generate_gif_with_openai.sh" "$CONFIG_OVERRIDE")"
    if [ -n "$VIDEO_FILE" ] && [ -f "$VIDEO_FILE" ]; then
        echo ">> Üretilen GIF: $VIDEO_FILE"
    else
        echo "HATA: OpenAI GIF üretimi başarısız oldu." >&2
        VIDEO_FILE=""
    fi
fi

# OpenAI başarısız olduysa Google Drive'dan dosya indir
if [ -z "$VIDEO_FILE" ] && [ "${USE_GOOGLE_DRIVE:-0}" -eq 1 ] && [ -n "$DRIVE_FOLDER_ID" ]; then
    if command -v gdown >/dev/null 2>&1; then
        echo ">> Google Drive'dan arkaplan dosyası indiriliyor..."
        TMP_DRIVE_DIR=$(mktemp -d)
        gdown --quiet --folder "https://drive.google.com/drive/folders/${DRIVE_FOLDER_ID}" -O "$TMP_DRIVE_DIR" --remaining-ok
        DRIVE_FILE=$(find "$TMP_DRIVE_DIR" -type f \( -iname '*.mp4' -o -iname '*.gif' \) | shuf -n 1)
        if [ -n "$DRIVE_FILE" ]; then
            VIDEO_FILE="$DRIVE_FILE"
            echo ">> İndirilen dosya: $VIDEO_FILE"
        else
            echo "HATA: Google Drive klasöründe uygun dosya bulunamadı." >&2
        fi
    else
        echo "HATA: gdown aracı yüklü değil, Google Drive kullanılamıyor." >&2
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
    echo "HATA: Arkaplan videosu için kaynak bulunamadı. BACKGROUND_VIDEO, VIDEO_SOURCE_DIR veya USE_OPENAI_GIF tanımlı olmalı." >&2
    exit 1
fi

# Müzikleri Jamendo üzerinden indir (eğer aktifse)
if [ "${USE_JAMENDO:-0}" -eq 1 ] && [ -n "$JAMENDO_CLIENT_ID" ]; then
    echo ">> Jamendo API'den müzik indiriliyor..."
    mkdir -p "$MUSIC_DIR"
    response=$(curl -s "https://api.jamendo.com/v3.0/tracks/?client_id=$JAMENDO_CLIENT_ID&format=json&tags=$TAG&limit=100&audioformat=mp31&license_cc=by")
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
    -movflags +faststart \
    -t "$TARGET_SECONDS" "$OUTPUT_VIDEO"

if [ $? -ne 0 ]; then
    echo "FFmpeg video oluşturma işlemi başarısız oldu!" >&2
    exit 1
fi

echo ">> Video başarıyla oluşturuldu: $OUTPUT_VIDEO"
