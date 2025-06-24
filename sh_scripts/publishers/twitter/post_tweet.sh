#!/bin/bash
# post_tweet.sh - Standardized Twitter posting interface
# Usage: ./post_tweet.sh [tweet_content] [config_override]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SH_SCRIPTS_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Load common utilities
source "$SH_SCRIPTS_DIR/common.sh"

function post_tweet() {
    local tweet_content="${1:-}"
    local config_override="${2:-}"
    
    echo -e "${BLUE}🐦 Twitter Publisher${NC}"
    echo -e "${BLUE}==================${NC}"
    
    # Load channel configuration
    load_channel_config "${CHANNEL:-default}" "$config_override"
    
    # Determine tweet content source
    if [[ -n "$tweet_content" ]]; then
        export TWEET_MESSAGE="$tweet_content"
        echo -e "${BLUE}📝 Using provided content: ${TWEET_MESSAGE:0:50}...${NC}"
    else
        # Try to get content from generated files
        get_tweet_message
        if [[ -z "${TWEET_MESSAGE:-}" ]]; then
            echo -e "${RED}❌ No tweet content provided or found${NC}"
            echo -e "${YELLOW}💡 Usage: $0 \"Your tweet content\" [config_override]${NC}"
            return 1
        fi
        echo -e "${BLUE}📝 Using generated content: ${TWEET_MESSAGE:0:50}...${NC}"
    fi
    
    # Validate content length
    if [[ ${#TWEET_MESSAGE} -gt 280 ]]; then
        echo -e "${YELLOW}⚠️ Content too long (${#TWEET_MESSAGE} chars), truncating...${NC}"
        export TWEET_MESSAGE="${TWEET_MESSAGE:0:277}..."
    fi
    
    echo -e "${BLUE}📊 Final content length: ${#TWEET_MESSAGE} characters${NC}"
    echo -e "${BLUE}🔤 Content: $TWEET_MESSAGE${NC}"
    echo ""
    
    # Choose posting method based on available credentials
    local post_script=""
    if [[ -n "${TWITTER_AUTH_CODE:-}" && -n "${TWITTER_CODE_VERIFIER:-}" ]]; then
        post_script="$SCRIPT_DIR/post_to_twitter_simple.py"
        echo -e "${BLUE}🔐 Using OAuth 2.0 authentication${NC}"
    elif [[ -n "${TWITTER_API_KEY:-}" && -n "${TWITTER_ACCESS_TOKEN:-}" ]]; then
        post_script="$SCRIPT_DIR/post_to_twitter_api.py"
        echo -e "${BLUE}🔐 Using API key authentication${NC}"
    else
        echo -e "${RED}❌ No valid Twitter credentials found${NC}"
        echo -e "${YELLOW}💡 Please configure Twitter credentials in channels.env${NC}"
        return 1
    fi
    
    # Execute posting
    echo -e "${BLUE}🚀 Posting to Twitter...${NC}"
    
    if python3 "$post_script"; then
        echo -e "${GREEN}✅ Successfully posted to Twitter!${NC}"
        
        # Log success
        echo "$(date -Iseconds) | SUCCESS | Twitter post | $TWEET_MESSAGE" >> "$SH_SCRIPTS_DIR/logs/twitter_posts.log"
        
        # Output URL if available (for pipeline use)
        if [[ -f "$SH_SCRIPTS_DIR/latest_tweet_url.txt" ]]; then
            local tweet_url=$(cat "$SH_SCRIPTS_DIR/latest_tweet_url.txt")
            echo -e "${GREEN}🔗 Tweet URL: $tweet_url${NC}"
            echo "$tweet_url"  # stdout for pipeline capture
        fi
        
        return 0
    else
        echo -e "${RED}❌ Failed to post to Twitter${NC}"
        
        # Log failure
        echo "$(date -Iseconds) | FAILED | Twitter post | $TWEET_MESSAGE" >> "$SH_SCRIPTS_DIR/logs/twitter_posts.log"
        
        return 1
    fi
}

function main() {
    # Create logs directory if it doesn't exist
    mkdir -p "$SH_SCRIPTS_DIR/logs"
    
    # Execute posting
    post_tweet "$@"
}

# Handle help requests
if [[ "${1:-}" == "help" || "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo -e "${YELLOW}Twitter Publisher - Standardized Interface${NC}"
    echo ""
    echo "Usage: $0 [tweet_content] [config_override]"
    echo ""
    echo "Examples:"
    echo "  $0 \"Hello Twitter!\"                    # Post specific content"
    echo "  $0                                       # Use generated content"
    echo "  $0 \"Custom tweet\" custom_config.json   # With config override"
    echo ""
    echo "Environment Variables:"
    echo "  CHANNEL          - Channel to use (default: default)"
    echo "  TWEET_MESSAGE    - Tweet content to post"
    echo "  CONTENT_TYPE     - Content type for context"
    exit 0
fi

# Execute main function
main "$@" 