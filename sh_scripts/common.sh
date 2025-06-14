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
          youtube.CLIENT_ID) CLIENT_ID="$value" ;;
          youtube.CLIENT_SECRET) CLIENT_SECRET="$value" ;;
          youtube.REFRESH_TOKEN) REFRESH_TOKEN="$value" ;;
          youtube.STREAM_KEY) YOUTUBE_STREAM_KEY="$value" ;;
          twitter.API_KEY) TWITTER_API_KEY="$value" ;;
          twitter.API_SECRET) TWITTER_API_SECRET="$value" ;;
          twitter.ACCESS_TOKEN) TWITTER_ACCESS_TOKEN="$value" ;;
          twitter.ACCESS_SECRET) TWITTER_ACCESS_SECRET="$value" ;;
          *)
            key=$(echo "$path" | tr '.-' '_')
            eval "export $key=\"\$value\"" ;;
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
