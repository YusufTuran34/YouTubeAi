#!/bin/bash
# run_workflow.sh - Main workflow orchestrator using new pipeline architecture
# Usage: ./run_workflow.sh <workflow_type> <channel> [content_type] [additional_params]

set -euo pipefail

# Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SH_SCRIPTS_DIR="$(dirname "$SCRIPT_DIR")"
CORE_DIR="$SH_SCRIPTS_DIR/core"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Load core modules
source "$CORE_DIR/channel_manager.sh"
source "$CORE_DIR/pipeline_manager.sh"

#==============================================================================
# USAGE & VALIDATION
#==============================================================================

function show_usage() {
    echo -e "${BLUE}🎯 YouTube AI Workflow Orchestrator${NC}"
    echo -e "${BLUE}===================================${NC}"
    echo ""
    echo "Usage: $0 <workflow_type> <channel> [content_type] [additional_params]"
    echo ""
    echo -e "${YELLOW}Workflow Types:${NC}"
    echo "  video_upload   - Complete video creation and YouTube upload"
    echo "  social_only    - Social media content only (Twitter/Instagram)"
    echo "  full_pipeline  - Complete content pipeline (all platforms)"
    echo "  stream_workflow - Live streaming setup and promotion"
    echo ""
    echo -e "${YELLOW}Available Channels:${NC}"
    if [[ -f "$SH_SCRIPTS_DIR/channel_configs.json" ]]; then
        jq -r '.channels | keys[]' "$SH_SCRIPTS_DIR/channel_configs.json" | sed 's/^/  /'
    else
        echo "  default, youtube_only, social_only, minimal, test_channel"
    fi
    echo ""
    echo -e "${YELLOW}Content Types:${NC}"
    echo "  lofi, horoscope, meditation"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 video_upload default lofi"
    echo "  $0 social_only twitter_only horoscope zodiac_sign=aries"
    echo "  $0 full_pipeline default lofi --dry-run"
    echo "  $0 stream_workflow youtube_only lofi duration=3600"
}

function validate_inputs() {
    local workflow_type="$1"
    local channel="$2"
    local content_type="${3:-lofi}"
    
    # Validate workflow type
    case "$workflow_type" in
        "video_upload"|"social_only"|"full_pipeline"|"stream_workflow")
            echo -e "${GREEN}✅ Valid workflow type: $workflow_type${NC}"
            ;;
        *)
            echo -e "${RED}❌ Invalid workflow type: $workflow_type${NC}"
            show_usage
            return 1
            ;;
    esac
    
    # Validate channel
    if ! load_channel_capabilities "$channel"; then
        echo -e "${RED}❌ Invalid channel: $channel${NC}"
        return 1
    fi
    
    # Validate workflow requirements
    if ! validate_workflow_requirements "$workflow_type" "$channel"; then
        echo -e "${RED}❌ Workflow not supported by channel${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ All inputs validated successfully${NC}"
    return 0
}

#==============================================================================
# MAIN WORKFLOW EXECUTION
#==============================================================================

function main() {
    local workflow_type="${1:-}"
    local channel="${2:-}"
    local content_type="${3:-lofi}"
    local additional_params="${4:-}"
    
    # Show header
    echo -e "${PURPLE}🚀 YouTube AI Workflow Orchestrator${NC}"
    echo -e "${PURPLE}====================================${NC}"
    echo ""
    
    # Check for help request
    if [[ "$workflow_type" == "help" || "$workflow_type" == "--help" || "$workflow_type" == "-h" || -z "$workflow_type" ]]; then
        show_usage
        return 0
    fi
    
    # Validate inputs
    if ! validate_inputs "$workflow_type" "$channel" "$content_type"; then
        return 1
    fi
    
    # Show execution summary
    echo -e "${BLUE}📋 Execution Summary${NC}"
    echo -e "${BLUE}====================${NC}"
    echo -e "${BLUE}Workflow Type:${NC} $workflow_type"
    echo -e "${BLUE}Channel:${NC} $channel ($(get_channel_name))"
    echo -e "${BLUE}Content Type:${NC} $content_type"
    echo -e "${BLUE}Additional Params:${NC} $additional_params"
    echo ""
    
    # Setup environment
    export WORKFLOW_TYPE="$workflow_type"
    export CHANNEL="$channel"
    export CONTENT_TYPE="$content_type"
    export PIPELINE_MODE="true"
    
    # Change to scripts directory for execution
    cd "$SH_SCRIPTS_DIR"
    
    # Execute pipeline
    echo -e "${PURPLE}🎬 Starting pipeline execution...${NC}"
    echo ""
    
    if execute_pipeline "$workflow_type" "$channel" "$content_type" "$additional_params"; then
        echo ""
        echo -e "${GREEN}🎉 Workflow completed successfully!${NC}"
        echo -e "${YELLOW}💡 Check the logs directory for detailed execution logs${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}❌ Workflow failed!${NC}"
        echo -e "${YELLOW}💡 Check the logs directory for error details${NC}"
        return 1
    fi
}

#==============================================================================
# ERROR HANDLING
#==============================================================================

function cleanup_on_exit() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo ""
        echo -e "${YELLOW}⚠️ Workflow interrupted (exit code: $exit_code)${NC}"
        echo -e "${YELLOW}💡 Performing cleanup...${NC}"
        # Add any necessary cleanup here
    fi
}

trap cleanup_on_exit EXIT

#==============================================================================
# SCRIPT EXECUTION
#==============================================================================

# Ensure we have required dependencies
if ! command -v jq >/dev/null 2>&1; then
    echo -e "${RED}❌ Missing dependency: jq${NC}"
    echo -e "${YELLOW}💡 Install with: brew install jq${NC}"
    exit 1
fi

# Execute main function with all arguments
main "$@" 