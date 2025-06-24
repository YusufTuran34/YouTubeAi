#!/bin/bash
# full_video_pipeline.sh - Complete video creation and multi-platform publishing
# Usage: ./full_video_pipeline.sh [content_type] [channel]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

function main() {
    local content_type="${1:-lofi}"
    local channel="${2:-default}"
    
    echo -e "${PURPLE}🎬 Full Video Pipeline${NC}"
    echo -e "${BLUE}Content Type: $content_type${NC}"
    echo -e "${BLUE}Channel: $channel${NC}"
    echo ""
    
    # Use full_pipeline workflow for complete content creation
    "$SCRIPT_DIR/run_workflow.sh" full_pipeline "$channel" "$content_type"
}

# Show usage if help requested
if [[ "${1:-}" == "help" || "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo -e "${YELLOW}Usage: $0 [content_type] [channel]${NC}"
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 lofi default          # LoFi video with full capabilities"
    echo "  $0 horoscope youtube_only # Horoscope video, YouTube only"
    echo "  $0 meditation default     # Meditation video with all platforms"
    exit 0
fi

main "$@" 