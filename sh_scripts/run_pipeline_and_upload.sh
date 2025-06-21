#!/bin/bash
# run_pipeline_and_upload.sh - optionally set duration then run generation pipeline and upload video

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Default values
DURATION_HOURS=""
CONFIG_OVERRIDE=""
source "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}"
CONFIG_FILE=""  # path passed to other scripts if override specified
RUN_GENERATION=1
RUN_UPLOAD=1
POST_TWITTER=0
POST_INSTAGRAM=0
TAG=""

# Parse arguments
if [[ "$1" =~ ^[0-9] ]]; then
    DURATION_HOURS="$1"
    shift
fi

while [ $# -gt 0 ]; do
    case "$1" in
        --config)
            CONFIG_OVERRIDE="$2"; CONFIG_FILE="$2"; shift 2;;
        --no-generation)
            RUN_GENERATION=0; shift;;
        --no-upload)
            RUN_UPLOAD=0; shift;;
        --post-twitter)
            POST_TWITTER=1; shift;;
        --post-instagram)
            POST_INSTAGRAM=1; shift;;
        --tag)
            TAG="$2"; shift 2;;
        *)
            shift;;
    esac
done

[ -n "$CONFIG_OVERRIDE" ] && load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE"

[ -n "$DURATION_HOURS" ] && bash "$SCRIPT_DIR/update_config.sh" VIDEO_DURATION_HOURS "$DURATION_HOURS" "$CONFIG_OVERRIDE"
[ -n "$TAG" ] && bash "$SCRIPT_DIR/update_config.sh" TAG "$TAG" "$CONFIG_OVERRIDE"

if [ "$RUN_GENERATION" -eq 1 ]; then
    bash "$SCRIPT_DIR/run_generation_pipeline.sh" "$CONFIG_OVERRIDE"
fi

if [ "$RUN_UPLOAD" -eq 1 ]; then
    UPLOAD_OUTPUT=$(bash "$SCRIPT_DIR/upload_video.sh" "$CONFIG_OVERRIDE")
    echo "$UPLOAD_OUTPUT"
    VIDEO_URL=$(echo "$UPLOAD_OUTPUT" | grep -o 'https://youtu.be/[A-Za-z0-9_-]*')
    if [ -n "$VIDEO_URL" ]; then
        echo "$VIDEO_URL" > "$SCRIPT_DIR/latest_video_url.txt"
        
        # Video upload başarılı olduysa Twitter'a post et
        if [ "$POST_TWITTER" -eq 1 ]; then
            echo "📢 Video yüklendi, Twitter'a otomatik tweet atılıyor..."
            
            # Selenium script ile tweet at - TAG parametresini geç
            cd "$SCRIPT_DIR"
            source .venv/bin/activate
            
            # TAG parametresine göre content type belirle
            CONTENT_TYPE="${TAG:-lofi}"
            python3 post_to_twitter_simple.py "$CONTENT_TYPE"
            
            if [ $? -eq 0 ]; then
                echo "✅ Twitter tweet başarıyla gönderildi!"
            else
                echo "❌ Twitter tweet gönderilemedi!"
            fi
        fi
    fi
fi

if [ "$POST_INSTAGRAM" -eq 1 ]; then
    bash "$SCRIPT_DIR/post_instagram_story.sh" "$CONFIG_OVERRIDE"
fi
