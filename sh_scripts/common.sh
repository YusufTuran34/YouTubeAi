#!/bin/sh
# common.sh - multi-channel config loader (POSIX uyumlu)

load_channel_config() {
  channel="${1:-default}"
  override="$2"
  script_dir="$(cd "$(dirname "$0")" && pwd)"
  cfg_dir="$script_dir/configs"
  base_conf="$cfg_dir/base.conf"
  env_file="${CHANNEL_ENV_FILE:-$script_dir/channels.env}"

  [ -f "$base_conf" ] && . "$base_conf"
  [ -f "$env_file" ] && . "$env_file"

  if [ -n "$CHANNEL_CONFIGS" ] && command -v jq >/dev/null 2>&1; then
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
    echo "[HATA] jq bulunamadı veya CHANNEL_CONFIGS boş!" >&2
    exit 1
  fi

  if [ -n "$override" ] && [ -f "$override" ]; then
    echo "[DEBUG] Override config yükleniyor: $override"
    . "$override"
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
