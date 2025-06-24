#!/bin/sh
# common.sh - multi-channel config loader (POSIX uyumlu)

load_channel_config() {
  channel="${1:-default}"
  override="$2"
  # Use SH_SCRIPTS_DIR if available, otherwise detect it from common.sh location
  if [ -n "$SH_SCRIPTS_DIR" ]; then
    script_dir="$SH_SCRIPTS_DIR"
  else
    # Get sh_scripts directory from common.sh location
    common_dir="$(cd "$(dirname "$0")" && pwd)"
    case "$common_dir" in
      */sh_scripts) script_dir="$common_dir" ;;
      */sh_scripts/*) script_dir="$(dirname "$common_dir")" ;;
      *) script_dir="$(pwd)/sh_scripts" ;;
    esac
  fi
  cfg_dir="$script_dir/configs"
  base_conf="$cfg_dir/base.conf"
  env_file="${CHANNEL_ENV_FILE:-$script_dir/channels.env}"

  [ -f "$base_conf" ] && . "$base_conf"
  [ -f "$env_file" ] && . "$env_file"

  if [ -n "$CHANNEL_CONFIGS" ] && command -v jq >/dev/null 2>&1; then
    # Validate JSON before processing
    if echo "$CHANNEL_CONFIGS" | jq empty >/dev/null 2>&1; then
      json=$(echo "$CHANNEL_CONFIGS" | jq -c --arg name "$channel" '.[] | select(.name==$name)')
      if [ -n "$json" ]; then
        tmpfile=$(mktemp) || exit 1
        echo "$json" | jq -r 'paths(scalars) as $p |
          [($p|join(".")), (getpath($p))] | @tsv' > "$tmpfile"

              while IFS="$(printf '\t')" read -r path value; do
                case "$path" in
                  youtube.CLIENT_ID) export CLIENT_ID="$value" ;;
                  youtube.CLIENT_SECRET) export CLIENT_SECRET="$value" ;;
                  youtube.REFRESH_TOKEN) export REFRESH_TOKEN="$value" ;;
                  youtube.STREAM_KEY) export YOUTUBE_STREAM_KEY="$value" ;;

                  twitter.API_KEY) export TWITTER_API_KEY="$value" ;;
                  twitter.API_SECRET) export TWITTER_API_SECRET="$value" ;;
                  twitter.ACCESS_TOKEN) export TWITTER_ACCESS_TOKEN="$value" ;;
                  twitter.ACCESS_SECRET) export TWITTER_ACCESS_SECRET="$value" ;;
                  twitter.CLIENT_ID) export TWITTER_CLIENT_ID="$value" ;;
                  twitter.CLIENT_SECRET) export TWITTER_CLIENT_SECRET="$value" ;;
                  twitter.TWITTER_AUTH_CODE) export TWITTER_AUTH_CODE="$value" ;;
                  twitter.TWITTER_CODE_VERIFIER) export TWITTER_CODE_VERIFIER="$value" ;;

                  instagram.USERNAME) export INSTAGRAM_USERNAME="$value" ;;
                  instagram.PASSWORD) export INSTAGRAM_PASSWORD="$value" ;;

                  openai.API_KEY) export OPENAI_API_KEY="$value" ;;
                  runway.API_KEY) export RUNWAY_API_KEY="$value" ;;

                  *)
                    key=$(echo "$path" | tr '.-' '_')
                    export "$key"="$value"
                    ;;
                esac
              done < "$tmpfile"

        rm -f "$tmpfile"
      else
        echo "[HATA] '$channel' isimli kanal CHANNEL_CONFIGS içinde bulunamadı!" >&2
        exit 1
      fi
    else
      echo "[DEBUG] CHANNEL_CONFIGS geçersiz JSON formatında, environment variable'ları doğrudan kullanılıyor..." >&2
      # Continue with existing env vars set by JobService
      return 0 2>/dev/null || true
    fi
  else
    echo "[DEBUG] CHANNEL_CONFIGS boş, environment variable'ları doğrudan kullanılıyor..." >&2
    # Don't exit - let the script continue with existing env vars or fail gracefully later
    return 0 2>/dev/null || true
  fi

  if [ -n "$override" ] && [ -f "$override" ]; then
    echo "[DEBUG] Override config yükleniyor: $override" >&2
    . "$override"
  fi
  
  # Load content configs for video generation
  load_content_configs "$script_dir"
}

# Load content_configs.json settings as environment variables
load_content_configs() {
  script_dir="$1"
  content_config_file="$script_dir/content_configs.json"
  
  if [ -f "$content_config_file" ] && command -v jq >/dev/null 2>&1; then
    echo "[DEBUG] Content configs yükleniyor: $content_config_file" >&2
    
    # Extract video generation settings
    export USE_AI_VIDEO_GENERATION=$(jq -r '.video_generation.use_ai_generation // false' "$content_config_file" | sed 's/true/1/; s/false/0/')
    export USE_OPENAI_GIF=$(jq -r '.video_generation.openai.enabled // false' "$content_config_file" | sed 's/true/1/; s/false/0/')
    export USE_GOOGLE_DRIVE=$(jq -r '.video_generation.google_drive.enabled // false' "$content_config_file" | sed 's/true/1/; s/false/0/')
    export DRIVE_FOLDER_ID=$(jq -r '.video_generation.google_drive.folder_id // ""' "$content_config_file")
    export USE_RUNWAY_API=$(jq -r '.video_generation.use_runway_api // false' "$content_config_file" | sed 's/true/1/; s/false/0/')
    export RUNWAY_MODEL=$(jq -r '.video_generation.runway.model // "gen3a_turbo"' "$content_config_file")
    export RUNWAY_DURATION=$(jq -r '.video_generation.runway.duration // 5' "$content_config_file")
    export RUNWAY_RATIO=$(jq -r '.video_generation.runway.ratio // "1280:768"' "$content_config_file")
    
    echo "[DEBUG] Video generation flags: USE_AI_VIDEO_GENERATION=$USE_AI_VIDEO_GENERATION, USE_OPENAI_GIF=$USE_OPENAI_GIF, USE_GOOGLE_DRIVE=$USE_GOOGLE_DRIVE" >&2
  else
    echo "[DEBUG] Content config file bulunamadı veya jq mevcut değil: $content_config_file" >&2
  fi
}

# Get tweet message from generated_title.txt and generated_description.txt
get_tweet_message() {
    local title=""
    local desc=""
    if [ -f generated_title.txt ]; then
        title="$(cat generated_title.txt | head -1 | tr -d '\n')"
    fi
    if [ -f generated_description.txt ]; then
        desc="$(cat generated_description.txt | head -1 | tr -d '\n')"
    fi
    if [ -n "$title" ] || [ -n "$desc" ]; then
        export TWEET_MESSAGE="$title $desc"
    else
        export TWEET_MESSAGE="Automated tweet from twurl $(date)"
    fi
    # Twitter 280 karakter limiti
    if [ ${#TWEET_MESSAGE} -gt 280 ]; then
        export TWEET_MESSAGE="${TWEET_MESSAGE:0:277}..."
    fi
}
