#!/bin/bash
# quick_social_post.sh - Quick social media posting orchestrator
# Usage: ./quick_social_post.sh [content_type] [zodiac_sign]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

function main() {
    local content_type="${1:-lofi}"
    local additional_params=""
    
    # Handle zodiac sign for horoscope content
    if [[ "$content_type" == "horoscope" ]]; then
        local zodiac_sign="${2:-aries}"
        additional_params="zodiac_sign=$zodiac_sign"
    fi
    
    echo -e "${BLUE}🔥 Quick Social Media Post${NC}"
    echo -e "${BLUE}Content Type: $content_type${NC}"
    echo -e "${BLUE}Additional Params: $additional_params${NC}"
    echo ""
    
    # Use social_only workflow with minimal channel for fast execution
    "$SCRIPT_DIR/run_workflow.sh" social_only minimal "$content_type" "$additional_params"
}

# Show usage if no args
if [[ $# -eq 0 ]]; then
    echo -e "${YELLOW}Usage: $0 [content_type] [zodiac_sign]${NC}"
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 lofi"
    echo "  $0 horoscope aries"
    echo "  $0 meditation"
    exit 0
fi

main "$@" 