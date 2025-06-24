#!/bin/bash
# test_architecture.sh - Comprehensive testing for new shell script architecture
# Usage: ./test_architecture.sh [test_type]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SH_SCRIPTS_DIR="$(dirname "$SCRIPT_DIR")"
CORE_DIR="$SH_SCRIPTS_DIR/core"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

#==============================================================================
# TEST UTILITIES
#==============================================================================

function test_start() {
    local test_name="$1"
    echo -e "${CYAN}🧪 Testing: $test_name${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

function test_pass() {
    local test_name="$1"
    echo -e "${GREEN}✅ PASS: $test_name${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
}

function test_fail() {
    local test_name="$1"
    local error_msg="${2:-Unknown error}"
    echo -e "${RED}❌ FAIL: $test_name${NC}"
    echo -e "${RED}   Error: $error_msg${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
}

function test_summary() {
    echo ""
    echo -e "${PURPLE}📊 Test Summary${NC}"
    echo -e "${PURPLE}===============${NC}"
    echo -e "${BLUE}Total Tests: $TOTAL_TESTS${NC}"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}⚠️ $FAILED_TESTS test(s) failed${NC}"
        return 1
    fi
}

#==============================================================================
# DEPENDENCY TESTS
#==============================================================================

function test_dependencies() {
    echo -e "${BLUE}🔍 Testing Dependencies${NC}"
    echo -e "${BLUE}=======================${NC}"
    
    # Test jq
    test_start "jq command availability"
    if command -v jq >/dev/null 2>&1; then
        test_pass "jq command availability"
    else
        test_fail "jq command availability" "jq not installed"
    fi
    
    # Test python3
    test_start "python3 command availability"
    if command -v python3 >/dev/null 2>&1; then
        test_pass "python3 command availability"
    else
        test_fail "python3 command availability" "python3 not installed"
    fi
    
    # Test required Python packages
    test_start "Python packages availability"
    if python3 -c "import requests, json, urllib" 2>/dev/null; then
        test_pass "Python packages availability"
    else
        test_fail "Python packages availability" "Required Python packages not installed"
    fi
}

#==============================================================================
# CONFIGURATION TESTS
#==============================================================================

function test_configuration() {
    echo ""
    echo -e "${BLUE}⚙️ Testing Configuration${NC}"
    echo -e "${BLUE}=========================${NC}"
    
    # Test channel configs file
    test_start "Channel configs file existence"
    if [[ -f "$SH_SCRIPTS_DIR/channel_configs.json" ]]; then
        test_pass "Channel configs file existence"
    else
        test_fail "Channel configs file existence" "channel_configs.json not found"
    fi
    
    # Test channel configs JSON validity
    test_start "Channel configs JSON validity"
    if jq empty "$SH_SCRIPTS_DIR/channel_configs.json" 2>/dev/null; then
        test_pass "Channel configs JSON validity"
    else
        test_fail "Channel configs JSON validity" "Invalid JSON format"
    fi
    
    # Test content configs file
    test_start "Content configs file existence"
    if [[ -f "$SH_SCRIPTS_DIR/content_configs.json" ]]; then
        test_pass "Content configs file existence"
    else
        test_fail "Content configs file existence" "content_configs.json not found"
    fi
    
    # Test environment file
    test_start "Environment file existence"
    if [[ -f "$SH_SCRIPTS_DIR/channels.env" ]]; then
        test_pass "Environment file existence"
    else
        test_fail "Environment file existence" "channels.env not found"
    fi
}

#==============================================================================
# CORE MODULE TESTS
#==============================================================================

function test_core_modules() {
    echo ""
    echo -e "${BLUE}🏗️ Testing Core Modules${NC}"
    echo -e "${BLUE}========================${NC}"
    
    # Test channel manager
    test_start "Channel manager functionality"
    if source "$CORE_DIR/channel_manager.sh" && load_channel_capabilities "default" 2>/dev/null; then
        test_pass "Channel manager functionality"
    else
        test_fail "Channel manager functionality" "Cannot load channel capabilities"
    fi
    
    # Test pipeline manager
    test_start "Pipeline manager functionality"
    if source "$CORE_DIR/pipeline_manager.sh" 2>/dev/null; then
        test_pass "Pipeline manager functionality"
    else
        test_fail "Pipeline manager functionality" "Cannot load pipeline manager"
    fi
    
    # Test channel capabilities
    test_start "Channel capability checking"
    if source "$CORE_DIR/channel_manager.sh" && load_channel_capabilities "default" && has_capability "youtube" 2>/dev/null; then
        test_pass "Channel capability checking"
    else
        test_fail "Channel capability checking" "Cannot check capabilities"
    fi
}

#==============================================================================
# DIRECTORY STRUCTURE TESTS
#==============================================================================

function test_directory_structure() {
    echo ""
    echo -e "${BLUE}📁 Testing Directory Structure${NC}"
    echo -e "${BLUE}==============================${NC}"
    
    local required_dirs=(
        "core"
        "generators"
        "publishers"
        "publishers/youtube"
        "publishers/twitter"
        "publishers/instagram"
        "orchestrators"
        "utilities"
    )
    
    for dir in "${required_dirs[@]}"; do
        test_start "Directory existence: $dir"
        if [[ -d "$SH_SCRIPTS_DIR/$dir" ]]; then
            test_pass "Directory existence: $dir"
        else
            test_fail "Directory existence: $dir" "Directory not found"
        fi
    done
}

#==============================================================================
# SCRIPT FUNCTIONALITY TESTS
#==============================================================================

function test_script_functionality() {
    echo ""
    echo -e "${BLUE}🔧 Testing Script Functionality${NC}"
    echo -e "${BLUE}===============================${NC}"
    
    # Test orchestrator scripts
    local orchestrators=(
        "orchestrators/run_workflow.sh"
        "orchestrators/quick_social_post.sh"
        "orchestrators/full_video_pipeline.sh"
    )
    
    for script in "${orchestrators[@]}"; do
        test_start "Script existence and executability: $(basename "$script")"
        if [[ -f "$SH_SCRIPTS_DIR/$script" && -x "$SH_SCRIPTS_DIR/$script" ]]; then
            test_pass "Script existence and executability: $(basename "$script")"
        else
            test_fail "Script existence and executability: $(basename "$script")" "Script not found or not executable"
        fi
    done
    
    # Test help functionality
    test_start "Workflow orchestrator help"
    if "$SH_SCRIPTS_DIR/orchestrators/run_workflow.sh" help >/dev/null 2>&1; then
        test_pass "Workflow orchestrator help"
    else
        test_fail "Workflow orchestrator help" "Help command failed"
    fi
}

#==============================================================================
# CHANNEL TESTS
#==============================================================================

function test_channels() {
    echo ""
    echo -e "${BLUE}📺 Testing Channels${NC}"
    echo -e "${BLUE}===================${NC}"
    
    local channels=("default" "youtube_only" "social_only" "minimal" "test_channel")
    
    for channel in "${channels[@]}"; do
        test_start "Channel configuration: $channel"
        if source "$CORE_DIR/channel_manager.sh" && load_channel_capabilities "$channel" 2>/dev/null; then
            test_pass "Channel configuration: $channel"
        else
            test_fail "Channel configuration: $channel" "Cannot load channel"
        fi
    done
}

#==============================================================================
# WORKFLOW VALIDATION TESTS
#==============================================================================

function test_workflow_validation() {
    echo ""
    echo -e "${BLUE}🔄 Testing Workflow Validation${NC}"
    echo -e "${BLUE}==============================${NC}"
    
    local workflows=("video_upload" "social_only" "full_pipeline" "stream_workflow")
    local channel="default"
    
    for workflow in "${workflows[@]}"; do
        test_start "Workflow validation: $workflow"
        if source "$CORE_DIR/channel_manager.sh" && \
           load_channel_capabilities "$channel" && \
           validate_workflow_requirements "$workflow" "$channel" 2>/dev/null; then
            test_pass "Workflow validation: $workflow"
        else
            test_fail "Workflow validation: $workflow" "Workflow validation failed"
        fi
    done
}

#==============================================================================
# INTEGRATION TESTS
#==============================================================================

function test_integration() {
    echo ""
    echo -e "${BLUE}🔗 Testing Integration${NC}"
    echo -e "${BLUE}======================${NC}"
    
    # Test dry run pipeline
    test_start "Pipeline dry run"
    if source "$CORE_DIR/pipeline_manager.sh" && \
       load_channel_capabilities "test_channel" 2>/dev/null; then
        test_pass "Pipeline dry run"
    else
        test_fail "Pipeline dry run" "Pipeline integration test failed"
    fi
    
    # Test project manager integration
    test_start "Project manager integration"
    if [[ -f "$SH_SCRIPTS_DIR/../project_manager.sh" ]]; then
        if bash "$SH_SCRIPTS_DIR/../project_manager.sh" help >/dev/null 2>&1; then
            test_pass "Project manager integration"
        else
            test_fail "Project manager integration" "Project manager help failed"
        fi
    else
        test_fail "Project manager integration" "Project manager not found"
    fi
}

#==============================================================================
# MAIN EXECUTION
#==============================================================================

function run_all_tests() {
    echo -e "${PURPLE}🚀 YouTube AI Architecture Test Suite${NC}"
    echo -e "${PURPLE}=====================================${NC}"
    echo ""
    
    test_dependencies
    test_configuration
    test_core_modules
    test_directory_structure
    test_script_functionality
    test_channels
    test_workflow_validation
    test_integration
    
    echo ""
    test_summary
}

function run_specific_test() {
    local test_type="$1"
    
    case "$test_type" in
        "deps"|"dependencies")
            test_dependencies
            ;;
        "config"|"configuration")
            test_configuration
            ;;
        "core"|"modules")
            test_core_modules
            ;;
        "dirs"|"directories")
            test_directory_structure
            ;;
        "scripts"|"functionality")
            test_script_functionality
            ;;
        "channels")
            test_channels
            ;;
        "workflows"|"validation")
            test_workflow_validation
            ;;
        "integration")
            test_integration
            ;;
        *)
            echo -e "${RED}❌ Unknown test type: $test_type${NC}"
            echo -e "${YELLOW}Available tests: deps, config, core, dirs, scripts, channels, workflows, integration${NC}"
            return 1
            ;;
    esac
    
    test_summary
}

function show_usage() {
    echo -e "${YELLOW}YouTube AI Architecture Test Suite${NC}"
    echo ""
    echo "Usage: $0 [test_type]"
    echo ""
    echo "Test Types:"
    echo "  deps         - Test dependencies (jq, python3, etc.)"
    echo "  config       - Test configuration files"
    echo "  core         - Test core modules (channel_manager, pipeline_manager)"
    echo "  dirs         - Test directory structure"
    echo "  scripts      - Test script functionality"
    echo "  channels     - Test channel configurations"
    echo "  workflows    - Test workflow validation"
    echo "  integration  - Test integration between components"
    echo "  all          - Run all tests (default)"
    echo ""
    echo "Examples:"
    echo "  $0              # Run all tests"
    echo "  $0 core         # Test only core modules"
    echo "  $0 channels     # Test only channel configurations"
}

#==============================================================================
# SCRIPT EXECUTION
#==============================================================================

function main() {
    local test_type="${1:-all}"
    
    if [[ "$test_type" == "help" || "$test_type" == "--help" || "$test_type" == "-h" ]]; then
        show_usage
        return 0
    fi
    
    cd "$SH_SCRIPTS_DIR"  # Ensure we're in the right directory
    
    if [[ "$test_type" == "all" ]]; then
        run_all_tests
    else
        run_specific_test "$test_type"
    fi
}

main "$@" 