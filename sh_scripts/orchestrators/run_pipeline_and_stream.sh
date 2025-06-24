#!/bin/bash
# run_pipeline_and_stream.sh - set duration then run generation pipeline and stream

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Defaults
DURATION_HOURS=12
CONFIG_OVERRIDE=""
source "$SCRIPT_DIR/common.sh"
load_channel_config "${CHANNEL:-default}"
POST_TWITTER=0
POST_INSTAGRAM=0
TAG=""
# Parse args
if [[ "$1" =~ ^[0-9] ]]; then
    DURATION_HOURS="$1"
    shift
fi

while [ $# -gt 0 ]; do
    case "$1" in
        --config)
            CONFIG_OVERRIDE="$2"; shift 2;;
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

bash "$SCRIPT_DIR/update_config.sh" VIDEO_DURATION_HOURS "$DURATION_HOURS" "$CONFIG_OVERRIDE"
[ -n "$TAG" ] && bash "$SCRIPT_DIR/update_config.sh" TAG "$TAG" "$CONFIG_OVERRIDE"

bash "$SCRIPT_DIR/run_generation_pipeline.sh" "$CONFIG_OVERRIDE"
bash "$SCRIPT_DIR/upload_and_stream.sh" "$CONFIG_OVERRIDE"

if [ "$POST_TWITTER" -eq 1 ]; then
    echo "📢 Stream başlatıldı, Twitter'a otomatik tweet atılıyor..."
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

if [ "$POST_INSTAGRAM" -eq 1 ]; then
    bash "$SCRIPT_DIR/post_instagram_story.sh" "$CONFIG_OVERRIDE"
fi
