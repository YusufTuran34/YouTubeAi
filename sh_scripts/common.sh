#!/bin/bash
# common.sh - utilities for multi-channel configuration

load_channel_config() {
    local channel="${1:-default}"
    local override="$2"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local cfg_dir="$script_dir/configs"
    local base_conf="$cfg_dir/base.conf"
    local env_file="${CHANNEL_ENV_FILE:-$script_dir/channels.env}"

    if [ -f "$base_conf" ]; then
        # shellcheck disable=SC1090
        source "$base_conf"
    fi

    if [ -f "$env_file" ]; then
        # shellcheck disable=SC1090
        source "$env_file"
    fi

    if [ -n "$CHANNEL_CONFIGS" ] && command -v jq >/dev/null 2>&1; then
        local json
        json=$(echo "$CHANNEL_CONFIGS" | jq -c --arg name "$channel" '.[] | select(.name==$name)')
        if [ -n "$json" ]; then
            echo "$json" | jq -r 'paths(scalars) as $p | [($p|join(".")), (getpath($p))] | @tsv' | while IFS=$'\t' read -r path value; do
                case "$path" in
                    youtube.CLIENT_ID) export CLIENT_ID="$value" ;;
                    youtube.CLIENT_SECRET) export CLIENT_SECRET="$value" ;;
                    youtube.REFRESH_TOKEN) export REFRESH_TOKEN="$value" ;;
                    youtube.STREAM_KEY) export YOUTUBE_STREAM_KEY="$value" ;;
                    twitter.API_KEY) export TWITTER_API_KEY="$value" ;;
                    twitter.API_SECRET) export TWITTER_API_SECRET="$value" ;;
                    twitter.ACCESS_TOKEN) export TWITTER_ACCESS_TOKEN="$value" ;;
                    twitter.ACCESS_SECRET) export TWITTER_ACCESS_SECRET="$value" ;;
                    *) key=$(echo "$path" | tr '.-' '_'); export "$key"="$value" ;;
                esac
            done
        fi
    fi

    if [ -n "$override" ] && [ -f "$override" ]; then
        # shellcheck disable=SC1090
        source "$override"
    fi
}
