#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/run_video_and_stream.sh" 12 "$@"
