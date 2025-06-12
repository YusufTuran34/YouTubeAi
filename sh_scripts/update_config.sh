#!/bin/bash
# update_config.sh - Update a key in config.conf

KEY=$1
VALUE=$2
CONFIG_FILE="${3:-$(dirname "$0")/config.conf}"

if [ -z "$KEY" ] || [ -z "$VALUE" ]; then
  echo "Usage: $0 KEY VALUE [CONFIG_FILE]" >&2
  exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Config file not found: $CONFIG_FILE" >&2
  exit 1
fi

if grep -q "^$KEY=" "$CONFIG_FILE"; then
  sed -i.bak "s|^$KEY=.*|$KEY=\"$VALUE\"|" "$CONFIG_FILE"
else
  echo "$KEY=\"$VALUE\"" >> "$CONFIG_FILE"
fi
