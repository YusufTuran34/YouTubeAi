#!/bin/bash
# generate_video.sh - FFmpeg kullanarak arkaplan videosu ve müziklerle output video oluşturma

echo ">> Önceki geçici dosyalar temizleniyor..."
rm -f /tmp/audio_list.txt /tmp/audio_list_ext.txt
rm -rf /tmp/video_folder

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SH_SCRIPTS_DIR="$(dirname "$SCRIPT_DIR")"
export SH_SCRIPTS_DIR
CONFIG_OVERRIDE="${1:-}"
source "$SH_SCRIPTS_DIR/common.sh"
load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"

LATEST_FILE="$SH_SCRIPTS_DIR/latest_output_video.txt"
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

# AI Video Background üretme seçeneği
if [ "${USE_AI_VIDEO_GENERATION:-0}" -eq 1 ]; then
    echo ">> AI ile konfigüratif arkaplan video üretiliyor..."
    echo ">> İçerik türü: ${CONTENT_TYPE}"
    
    # Try AI video generation first
    echo ">> 🤖 AI video generation script çalıştırılıyor..."
    AI_VIDEO_OUTPUT=$("$SCRIPT_DIR/generate_ai_video_background.sh" "$CONTENT_TYPE" 2>&1)
    AI_EXIT_CODE=$?
    
    # Parse the last line as the output file path (AI script outputs path as last line)
    AI_VIDEO_FILE=$(echo "$AI_VIDEO_OUTPUT" | tail -1 | grep -E '\.(mp4|gif|png)$')
    
    if [ $AI_EXIT_CODE -eq 0 ] && [ -n "$AI_VIDEO_FILE" ] && [ -f "$AI_VIDEO_FILE" ]; then
        VIDEO_FILE="$AI_VIDEO_FILE"
        echo ">> ✅ AI video başarıyla üretildi: $VIDEO_FILE"
    else
        echo ">> ⚠️ AI video üretimi başarısız (exit code: $AI_EXIT_CODE), alternatif yöntemlere geçiliyor..."
        echo ">> 📋 AI Script Output (debug):"
        echo "$AI_VIDEO_OUTPUT" | head -5
        echo ">> 📋 Parsed file path: '$AI_VIDEO_FILE'"
        VIDEO_FILE=""
    fi
fi

# FALLBACK SİSTEMLERİ - Basic fallback sistemini aktif hale getirdim
# Fallback 1: OpenAI ile GIF üretme seçeneği (Eski sistem) - İsteğe bağlı
if [ -z "$VIDEO_FILE" ] && [ "${USE_OPENAI_GIF:-0}" -eq 1 ]; then
    echo ">> Fallback: OpenAI ile arkaplan GIF'i üretiliyor..."
    VIDEO_FILE="$("$SCRIPT_DIR/generate_gif_with_openai.sh" "$CONFIG_OVERRIDE")"
    if [ -n "$VIDEO_FILE" ] && [ -f "$VIDEO_FILE" ]; then
        echo ">> ✅ Üretilen GIF: $VIDEO_FILE"
    else
        echo ">> ❌ OpenAI GIF üretimi başarısız oldu." >&2
        VIDEO_FILE=""
    fi
fi

# Fallback 2: Google Drive'dan dosya indir - İsteğe bağlı
if [ -z "$VIDEO_FILE" ] && [ "${USE_GOOGLE_DRIVE:-0}" -eq 1 ] && [ -n "$DRIVE_FOLDER_ID" ]; then
    if command -v gdown >/dev/null 2>&1; then
        echo ">> Fallback: Google Drive'dan arkaplan dosyası indiriliyor..."
        TMP_DRIVE_DIR=$(mktemp -d)
        gdown --quiet --folder "https://drive.google.com/drive/folders/${DRIVE_FOLDER_ID}" -O "$TMP_DRIVE_DIR" --remaining-ok 2>/dev/null
        DRIVE_FILE=$(find "$TMP_DRIVE_DIR" -type f \( -iname '*.mp4' -o -iname '*.gif' \) | shuf -n 1)
        if [ -n "$DRIVE_FILE" ]; then
            VIDEO_FILE="$DRIVE_FILE"
            echo ">> ✅ İndirilen dosya: $VIDEO_FILE"
        else
            echo ">> ⚠️ Google Drive klasöründe uygun dosya bulunamadı." >&2
        fi
        rm -rf "$TMP_DRIVE_DIR" 2>/dev/null
    else
        echo ">> ⚠️ gdown aracı yüklü değil, Google Drive kullanılamıyor." >&2
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

# First, check if reverse playback is enabled for the input video file
REVERSE_ENABLED="false"
PLAY_FORWARD_REVERSE="false"

# Load reverse playback settings from content configs if available
if [ -f "$SH_SCRIPTS_DIR/content_configs.json" ]; then
    REVERSE_ENABLED=$(jq -r '.video_generation.reverse_playback.enabled // false' "$SH_SCRIPTS_DIR/content_configs.json" 2>/dev/null || echo "false")
    PLAY_FORWARD_REVERSE=$(jq -r '.video_generation.reverse_playback.play_forward_then_reverse // false' "$SH_SCRIPTS_DIR/content_configs.json" 2>/dev/null || echo "false")
fi

echo ">> 🔍 Reverse playback settings: enabled=$REVERSE_ENABLED, forward_reverse=$PLAY_FORWARD_REVERSE"

# Apply reverse playback to source video BEFORE adding music (if enabled)
PROCESSED_VIDEO_FILE="$VIDEO_FILE"
if [ "$REVERSE_ENABLED" = "true" ] && [ "$PLAY_FORWARD_REVERSE" = "true" ] && command -v ffmpeg >/dev/null 2>&1; then
    echo ">> 🔄 Applying reverse playbook to source video before adding music..."
    
    # Create temporary files for processing
    REVERSE_VIDEO_FILE="/tmp/reverse_$(basename "$VIDEO_FILE")"
    COMBINED_VIDEO_FILE="/tmp/combined_$(basename "$VIDEO_FILE")"
    
    # Create reverse video with proper re-encoding
    echo ">> ⏪ Creating reverse version of source video with re-encoding..."
    ffmpeg -y -i "$VIDEO_FILE" \
        -vf "reverse,fps=30" \
        -c:v libx264 -preset fast -pix_fmt yuv420p \
        -an \
        "$REVERSE_VIDEO_FILE" >/dev/null 2>&1
    
    if [ -f "$REVERSE_VIDEO_FILE" ]; then
        # Re-encode original to match reverse format exactly
        TEMP_ORIGINAL_VIDEO="/tmp/temp_original_$(basename "$VIDEO_FILE")"
        echo ">> 🔄 Re-encoding original video for compatibility..."
        ffmpeg -y -i "$VIDEO_FILE" \
            -c:v libx264 -preset fast -pix_fmt yuv420p \
            -r 30 -an \
            "$TEMP_ORIGINAL_VIDEO" >/dev/null 2>&1
        
        if [ -f "$TEMP_ORIGINAL_VIDEO" ]; then
            # Create concatenation list with matching formats
            echo "file '$TEMP_ORIGINAL_VIDEO'" > /tmp/video_concat_list.txt
            echo "file '$REVERSE_VIDEO_FILE'" >> /tmp/video_concat_list.txt
            
            # Combine original and reverse with re-encoding
            echo ">> 🔗 Combining forward and reverse for seamless background loop..."
            ffmpeg -y -f concat -safe 0 -i /tmp/video_concat_list.txt \
                -c:v libx264 -preset fast -pix_fmt yuv420p \
                "$COMBINED_VIDEO_FILE" >/dev/null 2>&1
            
            if [ -f "$COMBINED_VIDEO_FILE" ]; then
                PROCESSED_VIDEO_FILE="$COMBINED_VIDEO_FILE"
                echo ">> ✅ Reverse playback applied to source video - duration doubled!"
            else
                echo ">> ⚠️ Failed to combine forward and reverse videos, using original"
            fi
            
            # Cleanup temporary files
            rm -f "$REVERSE_VIDEO_FILE" "$TEMP_ORIGINAL_VIDEO" /tmp/video_concat_list.txt
        else
            echo ">> ⚠️ Failed to re-encode original video, using original"
            rm -f "$REVERSE_VIDEO_FILE" /tmp/video_concat_list.txt
        fi
    else
        echo ">> ⚠️ Failed to create reverse video, using original"
    fi
fi

ffmpeg -y -stream_loop -1 -i "$PROCESSED_VIDEO_FILE" \
    -f concat -safe 0 -i "$AUDIO_LIST_EXTENDED" \
    -map 0:v -map 1:a \
    -vf "scale=854:480,fps=${GIF_FPS:-24}" \
    -c:v ${VIDEO_CODEC:-libx264} -preset ${PRESET:-veryfast} -pix_fmt yuv420p \
    -c:a ${AUDIO_CODEC:-aac} -b:a ${AUDIO_BITRATE:-128k} \
    -movflags +faststart \
    -t "$TARGET_SECONDS" "$OUTPUT_VIDEO"

if [ $? -ne 0 ]; then
    echo "FFmpeg video oluşturma işlemi başarısız oldu!" >&2
    exit 1
fi

# Cleanup temporary combined video file if it was created
if [ "$PROCESSED_VIDEO_FILE" != "$VIDEO_FILE" ]; then
    rm -f "$PROCESSED_VIDEO_FILE"
fi

echo ">> Video başarıyla oluşturuldu: $OUTPUT_VIDEO"
