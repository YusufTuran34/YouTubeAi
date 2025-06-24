#!/bin/bash
# channel_manager.sh - Channel capability management & abstraction layer
# Part of YouTubeAI Shell Architecture v2.0

set -euo pipefail

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
CHANNEL_CONFIGS_FILE="$CONFIG_DIR/channel_configs.json"
CHANNEL_CAPABILITIES=""
CURRENT_CHANNEL=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

#==============================================================================
# CHANNEL LOADING FUNCTIONS
#==============================================================================

function load_channel_capabilities() {
    local channel="${1:-default}"
    
    echo -e "${BLUE}🔄 Loading capabilities for channel: $channel${NC}"
    
    # Validate config file exists
    if [[ ! -f "$CHANNEL_CONFIGS_FILE" ]]; then
        echo -e "${RED}❌ Channel config file not found: $CHANNEL_CONFIGS_FILE${NC}"
        return 1
    fi
    
    # Load channel config from JSON
    CHANNEL_CONFIG=$(jq ".channels.\"$channel\"" "$CHANNEL_CONFIGS_FILE" 2>/dev/null)
    
    if [[ "$CHANNEL_CONFIG" == "null" || -z "$CHANNEL_CONFIG" ]]; then
        echo -e "${RED}❌ Channel not found: $channel${NC}"
        echo -e "${YELLOW}💡 Available channels:${NC}"
        list_available_channels
        return 1
    fi
    
    # Export for global use
    export CHANNEL_CAPABILITIES="$CHANNEL_CONFIG"
    export CURRENT_CHANNEL="$channel"
    
    echo -e "${GREEN}✅ Channel capabilities loaded for: $channel${NC}"
    return 0
}

function list_available_channels() {
    if [[ -f "$CHANNEL_CONFIGS_FILE" ]]; then
        echo -e "${BLUE}📋 Available channels:${NC}"
        jq -r '.channels | keys[]' "$CHANNEL_CONFIGS_FILE" | sed 's/^/   • /'
    fi
}

function get_channel_name() {
    echo "$CHANNEL_CAPABILITIES" | jq -r '.name // "Unknown Channel"'
}

#==============================================================================
# CAPABILITY CHECKING FUNCTIONS  
#==============================================================================

function has_capability() {
    local capability="$1"
    
    if [[ -z "$CHANNEL_CAPABILITIES" ]]; then
        echo -e "${RED}❌ No channel loaded. Call load_channel_capabilities first.${NC}"
        return 1
    fi
    
    local result=$(echo "$CHANNEL_CAPABILITIES" | jq -r ".capabilities // [] | contains([\"$capability\"])")
    [[ "$result" == "true" ]]
}

function has_generator() {
    local generator="$1"
    
    if [[ -z "$CHANNEL_CAPABILITIES" ]]; then
        return 1
    fi
    
    local result=$(echo "$CHANNEL_CAPABILITIES" | jq -r ".generators.\"$generator\" // false")
    [[ "$result" == "true" ]]
}

function has_publisher() {
    local publisher="$1"
    
    if [[ -z "$CHANNEL_CAPABILITIES" ]]; then
        return 1
    fi
    
    local result=$(echo "$CHANNEL_CAPABILITIES" | jq -r ".publishers.\"$publisher\" // false")
    [[ "$result" == "true" ]]
}

function has_processor() {
    local processor="$1"
    
    if [[ -z "$CHANNEL_CAPABILITIES" ]]; then
        return 1
    fi
    
    local result=$(echo "$CHANNEL_CAPABILITIES" | jq -r ".processors.\"$processor\" // false")
    [[ "$result" == "true" || "$result" != "false" ]]
}

#==============================================================================
# CONFIGURATION GETTERS
#==============================================================================

function get_generator_config() {
    local generator="$1"
    echo "$CHANNEL_CAPABILITIES" | jq -r ".generators.\"$generator\" // false"
}

function get_publisher_config() {
    local publisher="$1"
    echo "$CHANNEL_CAPABILITIES" | jq -r ".publishers.\"$publisher\" // false"
}

function get_processor_config() {
    local processor="$1"
    echo "$CHANNEL_CAPABILITIES" | jq -r ".processors.\"$processor\" // false"
}

function get_all_capabilities() {
    echo "$CHANNEL_CAPABILITIES" | jq -r '.capabilities[]? // empty'
}

function get_enabled_generators() {
    echo "$CHANNEL_CAPABILITIES" | jq -r '.generators | to_entries[] | select(.value == true) | .key'
}

function get_enabled_publishers() {
    echo "$CHANNEL_CAPABILITIES" | jq -r '.publishers | to_entries[] | select(.value == true) | .key'
}

#==============================================================================
# VALIDATION FUNCTIONS
#==============================================================================

function validate_channel_capability() {
    local channel="$1"
    local capability="$2"
    
    load_channel_capabilities "$channel"
    
    if has_capability "$capability"; then
        echo -e "${GREEN}✅ Channel '$channel' supports: $capability${NC}"
        return 0
    else
        echo -e "${RED}❌ Channel '$channel' does not support: $capability${NC}"
        echo -e "${YELLOW}💡 Supported capabilities:${NC}"
        get_all_capabilities | sed 's/^/   • /'
        return 1
    fi
}

function validate_workflow_requirements() {
    local workflow_type="$1"
    local channel="$2"
    
    echo -e "${BLUE}🔍 Validating workflow requirements...${NC}"
    echo -e "${BLUE}   Workflow: $workflow_type${NC}"
    echo -e "${BLUE}   Channel: $channel${NC}"
    
    load_channel_capabilities "$channel"
    
    case "$workflow_type" in
        "video_upload")
            if has_generator "video" && has_publisher "youtube_upload"; then
                echo -e "${GREEN}✅ Video upload workflow supported${NC}"
                return 0
            else
                echo -e "${RED}❌ Video upload workflow not supported${NC}"
                echo -e "${YELLOW}💡 Requires: video generator + youtube_upload publisher${NC}"
                return 1
            fi
            ;;
        "social_only")
            if has_generator "tweet" && (has_publisher "twitter_post" || has_publisher "instagram_story"); then
                echo -e "${GREEN}✅ Social only workflow supported${NC}"
                return 0
            else
                echo -e "${RED}❌ Social only workflow not supported${NC}"
                echo -e "${YELLOW}💡 Requires: tweet generator + social publisher${NC}"
                return 1
            fi
            ;;
        "full_pipeline")
            if has_generator "video" && has_generator "tweet" && has_publisher "youtube_upload" && has_publisher "twitter_post"; then
                echo -e "${GREEN}✅ Full pipeline workflow supported${NC}"
                return 0
            else
                echo -e "${RED}❌ Full pipeline workflow not supported${NC}"
                echo -e "${YELLOW}💡 Requires: video+tweet generators + youtube+twitter publishers${NC}"
                return 1
            fi
            ;;
        "stream_workflow")
            if has_generator "video" && has_publisher "youtube_stream"; then
                echo -e "${GREEN}✅ Stream workflow supported${NC}"
                return 0
            else
                echo -e "${RED}❌ Stream workflow not supported${NC}"
                echo -e "${YELLOW}💡 Requires: video generator + youtube_stream publisher${NC}"
                return 1
            fi
            ;;
        *)
            echo -e "${YELLOW}⚠️ Unknown workflow type: $workflow_type${NC}"
            return 1
            ;;
    esac
}

#==============================================================================
# DEBUGGING & UTILITIES
#==============================================================================

function debug_channel_info() {
    if [[ -z "$CHANNEL_CAPABILITIES" ]]; then
        echo -e "${RED}❌ No channel loaded${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🔍 Channel Debug Info${NC}"
    echo -e "${BLUE}=====================${NC}"
    echo -e "${BLUE}Current Channel:${NC} $CURRENT_CHANNEL"
    echo -e "${BLUE}Channel Name:${NC} $(get_channel_name)"
    echo ""
    
    echo -e "${BLUE}📋 Capabilities:${NC}"
    get_all_capabilities | sed 's/^/   ✓ /'
    echo ""
    
    echo -e "${BLUE}🔧 Enabled Generators:${NC}"
    get_enabled_generators | sed 's/^/   ✓ /'
    echo ""
    
    echo -e "${BLUE}📤 Enabled Publishers:${NC}"
    get_enabled_publishers | sed 's/^/   ✓ /'
    echo ""
    
    echo -e "${BLUE}📊 Raw Config:${NC}"
    echo "$CHANNEL_CAPABILITIES" | jq '.'
}

function check_dependencies() {
    local missing_deps=()
    
    # Check for required commands
    command -v jq >/dev/null 2>&1 || missing_deps+=("jq")
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Missing dependencies: ${missing_deps[*]}${NC}"
        echo -e "${YELLOW}💡 Install with: brew install ${missing_deps[*]}${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ All dependencies satisfied${NC}"
    return 0
}

#==============================================================================
# MAIN EXECUTION (for testing)
#==============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script called directly - run tests
    echo -e "${BLUE}🧪 Channel Manager Test Mode${NC}"
    echo ""
    
    check_dependencies
    echo ""
    
    # Test with default channel
    if load_channel_capabilities "default"; then
        debug_channel_info
        echo ""
        
        # Test capabilities
        echo -e "${BLUE}🧪 Testing capabilities...${NC}"
        has_capability "youtube" && echo -e "${GREEN}✅ YouTube capability: YES${NC}" || echo -e "${RED}❌ YouTube capability: NO${NC}"
        has_generator "video" && echo -e "${GREEN}✅ Video generator: YES${NC}" || echo -e "${RED}❌ Video generator: NO${NC}"
        has_publisher "twitter_post" && echo -e "${GREEN}✅ Twitter publisher: YES${NC}" || echo -e "${RED}❌ Twitter publisher: NO${NC}"
        
        echo ""
        validate_workflow_requirements "full_pipeline" "default"
    fi
fi 