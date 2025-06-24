#!/bin/bash
# pipeline_manager.sh - Pipeline orchestration & workflow management
# Part of YouTubeAI Shell Architecture v2.0

set -euo pipefail

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SH_SCRIPTS_DIR="$(dirname "$SCRIPT_DIR")"
LOGS_DIR="$SH_SCRIPTS_DIR/logs"
PIPELINE_STATE_DIR="$LOGS_DIR/pipeline_states"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Load channel manager
source "$SCRIPT_DIR/channel_manager.sh"

# Ensure logs directory exists
mkdir -p "$LOGS_DIR" "$PIPELINE_STATE_DIR"

#==============================================================================
# PIPELINE EXECUTION FUNCTIONS
#==============================================================================

function execute_pipeline() {
    local workflow_type="$1"
    local channel="$2"
    local content_type="${3:-lofi}"
    local additional_params="${4:-}"
    
    local pipeline_id="pipeline_$(date +%s)_$$"
    local pipeline_log="$LOGS_DIR/${pipeline_id}.log"
    local pipeline_state="$PIPELINE_STATE_DIR/${pipeline_id}.state"
    
    echo -e "${PURPLE}🚀 Starting Pipeline: $pipeline_id${NC}" | tee "$pipeline_log"
    echo -e "${BLUE}   Workflow: $workflow_type${NC}" | tee -a "$pipeline_log"
    echo -e "${BLUE}   Channel: $channel${NC}" | tee -a "$pipeline_log"
    echo -e "${BLUE}   Content Type: $content_type${NC}" | tee -a "$pipeline_log"
    echo -e "${BLUE}   Parameters: $additional_params${NC}" | tee -a "$pipeline_log"
    echo "" | tee -a "$pipeline_log"
    
    # Initialize pipeline state
    cat > "$pipeline_state" <<EOF
{
    "pipeline_id": "$pipeline_id",
    "workflow_type": "$workflow_type",
    "channel": "$channel",
    "content_type": "$content_type",
    "additional_params": "$additional_params",
    "start_time": "$(date -Iseconds)",
    "status": "running",
    "steps": [],
    "outputs": {}
}
EOF
    
    # Load channel capabilities
    if ! load_channel_capabilities "$channel"; then
        update_pipeline_state "$pipeline_state" "failed" "Channel capabilities load failed"
        echo -e "${RED}❌ Pipeline failed: Could not load channel capabilities${NC}" | tee -a "$pipeline_log"
        return 1
    fi
    
    # Validate workflow requirements
    if ! validate_workflow_requirements "$workflow_type" "$channel"; then
        update_pipeline_state "$pipeline_state" "failed" "Workflow validation failed"
        echo -e "${RED}❌ Pipeline failed: Workflow not supported by channel${NC}" | tee -a "$pipeline_log"
        return 1
    fi
    
    # Build pipeline steps based on workflow type and channel capabilities
    local pipeline_steps=()
    if ! build_pipeline_steps pipeline_steps "$workflow_type" "$channel" "$content_type"; then
        update_pipeline_state "$pipeline_state" "failed" "Pipeline construction failed"
        echo -e "${RED}❌ Pipeline failed: Could not construct pipeline steps${NC}" | tee -a "$pipeline_log"
        return 1
    fi
    
    # Execute pipeline steps
    echo -e "${CYAN}📋 Pipeline steps to execute:${NC}" | tee -a "$pipeline_log"
    for step in "${pipeline_steps[@]}"; do
        echo -e "${CYAN}   • $step${NC}" | tee -a "$pipeline_log"
    done
    echo "" | tee -a "$pipeline_log"
    
    local step_count=0
    local total_steps=${#pipeline_steps[@]}
    
    for step in "${pipeline_steps[@]}"; do
        step_count=$((step_count + 1))
        
        echo -e "${YELLOW}⚡ Executing step $step_count/$total_steps: $step${NC}" | tee -a "$pipeline_log"
        
        if execute_pipeline_step "$step" "$channel" "$content_type" "$additional_params" "$pipeline_log" "$pipeline_state"; then
            echo -e "${GREEN}✅ Step $step_count completed successfully${NC}" | tee -a "$pipeline_log"
        else
            echo -e "${RED}❌ Pipeline failed at step $step_count: $step${NC}" | tee -a "$pipeline_log"
            update_pipeline_state "$pipeline_state" "failed" "Step $step_count failed: $step"
            return 1
        fi
        
        echo "" | tee -a "$pipeline_log"
    done
    
    # Pipeline completed successfully
    update_pipeline_state "$pipeline_state" "completed" "All steps completed successfully"
    echo -e "${GREEN}🎉 Pipeline $pipeline_id completed successfully!${NC}" | tee -a "$pipeline_log"
    
    # Show pipeline summary
    show_pipeline_summary "$pipeline_state" | tee -a "$pipeline_log"
    
    return 0
}

function build_pipeline_steps() {
    local array_var_name="$1"
    local workflow_type="$2"
    local channel="$3"
    local content_type="$4"
    
    # Clear the array by setting it to empty
    eval "$array_var_name=()"
    
    case "$workflow_type" in
        "video_upload")
            # Video generation workflow
            if has_generator "video"; then
                eval "$array_var_name+=(\"generators/generate_video.sh\")"
            fi
            
            if has_generator "title"; then
                eval "$array_var_name+=(\"generators/generate_title.sh\")"
            fi
            
            if has_generator "description"; then
                eval "$array_var_name+=(\"generators/generate_description.sh\")"
            fi
            
            if has_generator "thumbnail"; then
                eval "$array_var_name+=(\"generators/generate_thumbnail.sh\")"
            fi
            
            # Video processing
            if has_processor "video_encoding"; then
                eval "$array_var_name+=(\"processors/process_video.sh\")"
            fi
            
            # YouTube upload
            if has_publisher "youtube_upload"; then
                eval "$array_var_name+=(\"publishers/youtube/upload_video.sh\")"
            fi
            
            # Social media promotion
            if has_generator "tweet" && has_publisher "twitter_post"; then
                eval "$array_var_name+=(\"generators/generate_tweet.sh\")"
                eval "$array_var_name+=(\"publishers/twitter/post_tweet.sh\")"
            fi
            ;;
            
        "social_only")
            # Social media only workflow
            if has_generator "tweet"; then
                eval "$array_var_name+=(\"generators/generate_tweet.sh\")"
            fi
            
            if has_publisher "twitter_post"; then
                eval "$array_var_name+=(\"publishers/twitter/post_tweet.sh\")"
            fi
            
            if has_generator "story" && has_publisher "instagram_story"; then
                eval "$array_var_name+=(\"generators/generate_story.sh\")"
                eval "$array_var_name+=(\"publishers/instagram/post_story.sh\")"
            fi
            ;;
            
        "full_pipeline")
            # Complete content pipeline
            # Step 1: Generate all content
            if has_generator "video"; then
                eval "$array_var_name+=(\"generators/generate_video.sh\")"
            fi
            
            if has_generator "title"; then
                eval "$array_var_name+=(\"generators/generate_title.sh\")"
            fi
            
            if has_generator "description"; then
                eval "$array_var_name+=(\"generators/generate_description.sh\")"
            fi
            
            if has_generator "thumbnail"; then
                eval "$array_var_name+=(\"generators/generate_thumbnail.sh\")"
            fi
            
            if has_generator "tweet"; then
                eval "$array_var_name+=(\"generators/generate_tweet.sh\")"
            fi
            
            # Step 2: Process content
            if has_processor "video_encoding"; then
                eval "$array_var_name+=(\"processors/process_video.sh\")"
            fi
            
            # Step 3: Publish everywhere
            if has_publisher "youtube_upload"; then
                eval "$array_var_name+=(\"publishers/youtube/upload_video.sh\")"
            fi
            
            if has_publisher "twitter_post"; then
                eval "$array_var_name+=(\"publishers/twitter/post_tweet.sh\")"
            fi
            
            if has_publisher "instagram_story"; then
                eval "$array_var_name+=(\"publishers/instagram/post_story.sh\")"
            fi
            ;;
            
        "stream_workflow")
            # Live streaming workflow
            if has_generator "video"; then
                eval "$array_var_name+=(\"generators/generate_video.sh\")"
            fi
            
            if has_publisher "youtube_stream"; then
                eval "$array_var_name+=(\"publishers/youtube/start_stream.sh\")"
            fi
            
            # Promote stream on social media
            if has_generator "tweet" && has_publisher "twitter_post"; then
                eval "$array_var_name+=(\"generators/generate_tweet.sh\")"
                eval "$array_var_name+=(\"publishers/twitter/post_tweet.sh\")"
            fi
            ;;
            
        *)
            echo -e "${RED}❌ Unknown workflow type: $workflow_type${NC}"
            return 1
            ;;
    esac
    
    # Check if array has elements
    local array_length
    eval "array_length=\${#$array_var_name[@]}"
    if [[ $array_length -eq 0 ]]; then
        echo -e "${RED}❌ No pipeline steps generated for workflow: $workflow_type${NC}"
        return 1
    fi
    
    return 0
}

function execute_pipeline_step() {
    local step="$1"
    local channel="$2"
    local content_type="$3"
    local additional_params="$4"
    local pipeline_log="$5"
    local pipeline_state="$6"
    
    local step_start_time=$(date +%s)
    local step_script="$SH_SCRIPTS_DIR/$step"
    
    # Validate script exists
    if [[ ! -f "$step_script" ]]; then
        echo -e "${RED}❌ Script not found: $step_script${NC}" | tee -a "$pipeline_log"
        return 1
    fi
    
    # Prepare environment
    export CHANNEL="$channel"
    export CONTENT_TYPE="$content_type"
    export PIPELINE_MODE="true"
    
    # Execute step with timeout
    local step_log="$LOGS_DIR/step_$(basename "$step")_$(date +%s).log"
    
    echo -e "${CYAN}   Executing: $step_script${NC}" | tee -a "$pipeline_log"
    echo -e "${CYAN}   Log file: $step_log${NC}" | tee -a "$pipeline_log"
    
    # Run the script
    if timeout 600 bash "$step_script" $additional_params > "$step_log" 2>&1; then
        local exit_code=0
    else
        local exit_code=$?
    fi
    
    local step_end_time=$(date +%s)
    local step_duration=$((step_end_time - step_start_time))
    
    # Update pipeline state
    local step_status
    if [[ $exit_code -eq 0 ]]; then
        step_status="completed"
        echo -e "${GREEN}   ✅ Step completed in ${step_duration}s${NC}" | tee -a "$pipeline_log"
    else
        step_status="failed"
        echo -e "${RED}   ❌ Step failed in ${step_duration}s (exit code: $exit_code)${NC}" | tee -a "$pipeline_log"
        echo -e "${RED}   📋 Error details in: $step_log${NC}" | tee -a "$pipeline_log"
    fi
    
    # Log step in pipeline state
    update_step_in_pipeline_state "$pipeline_state" "$step" "$step_status" "$step_duration" "$exit_code" "$step_log"
    
    return $exit_code
}

#==============================================================================
# PIPELINE STATE MANAGEMENT
#==============================================================================

function update_pipeline_state() {
    local state_file="$1"
    local status="$2"
    local message="$3"
    
    local temp_file=$(mktemp)
    
    jq --arg status "$status" \
       --arg message "$message" \
       --arg end_time "$(date -Iseconds)" \
       '.status = $status | .message = $message | .end_time = $end_time' \
       "$state_file" > "$temp_file" && mv "$temp_file" "$state_file"
}

function update_step_in_pipeline_state() {
    local state_file="$1"
    local step="$2"
    local status="$3"
    local duration="$4"
    local exit_code="$5"
    local log_file="$6"
    
    local temp_file=$(mktemp)
    
    jq --arg step "$step" \
       --arg status "$status" \
       --arg duration "$duration" \
       --arg exit_code "$exit_code" \
       --arg log_file "$log_file" \
       --arg timestamp "$(date -Iseconds)" \
       '.steps += [{
           "step": $step,
           "status": $status,
           "duration": ($duration | tonumber),
           "exit_code": ($exit_code | tonumber),
           "log_file": $log_file,
           "timestamp": $timestamp
       }]' \
       "$state_file" > "$temp_file" && mv "$temp_file" "$state_file"
}

function show_pipeline_summary() {
    local state_file="$1"
    
    if [[ ! -f "$state_file" ]]; then
        echo -e "${RED}❌ Pipeline state file not found: $state_file${NC}"
        return 1
    fi
    
    echo -e "${PURPLE}📊 Pipeline Summary${NC}"
    echo -e "${PURPLE}==================${NC}"
    
    local pipeline_data=$(cat "$state_file")
    
    echo -e "${BLUE}Pipeline ID:${NC} $(echo "$pipeline_data" | jq -r '.pipeline_id')"
    echo -e "${BLUE}Workflow:${NC} $(echo "$pipeline_data" | jq -r '.workflow_type')"
    echo -e "${BLUE}Channel:${NC} $(echo "$pipeline_data" | jq -r '.channel')"
    echo -e "${BLUE}Status:${NC} $(echo "$pipeline_data" | jq -r '.status')"
    echo -e "${BLUE}Start Time:${NC} $(echo "$pipeline_data" | jq -r '.start_time')"
    echo -e "${BLUE}End Time:${NC} $(echo "$pipeline_data" | jq -r '.end_time // "N/A"')"
    
    echo ""
    echo -e "${BLUE}Steps Executed:${NC}"
    
    echo "$pipeline_data" | jq -r '.steps[] | "   " + (if .status == "completed" then "✅" else "❌" end) + " " + .step + " (" + (.duration | tostring) + "s)"'
    
    echo ""
    
    local total_steps=$(echo "$pipeline_data" | jq '.steps | length')
    local completed_steps=$(echo "$pipeline_data" | jq '[.steps[] | select(.status == "completed")] | length')
    local failed_steps=$(echo "$pipeline_data" | jq '[.steps[] | select(.status == "failed")] | length')
    
    echo -e "${BLUE}Statistics:${NC}"
    echo -e "${BLUE}   Total Steps:${NC} $total_steps"
    echo -e "${GREEN}   Completed:${NC} $completed_steps"
    echo -e "${RED}   Failed:${NC} $failed_steps"
}

#==============================================================================
# UTILITY FUNCTIONS
#==============================================================================

function list_recent_pipelines() {
    local count="${1:-10}"
    
    echo -e "${BLUE}📋 Recent Pipelines (last $count)${NC}"
    echo -e "${BLUE}========================${NC}"
    
    find "$PIPELINE_STATE_DIR" -name "*.state" -type f | sort -r | head -"$count" | while read -r state_file; do
        local pipeline_data=$(cat "$state_file")
        local pipeline_id=$(echo "$pipeline_data" | jq -r '.pipeline_id')
        local workflow=$(echo "$pipeline_data" | jq -r '.workflow_type')
        local channel=$(echo "$pipeline_data" | jq -r '.channel')
        local status=$(echo "$pipeline_data" | jq -r '.status')
        local start_time=$(echo "$pipeline_data" | jq -r '.start_time')
        
        local status_icon
        case "$status" in
            "completed") status_icon="${GREEN}✅${NC}" ;;
            "failed") status_icon="${RED}❌${NC}" ;;
            "running") status_icon="${YELLOW}🔄${NC}" ;;
            *) status_icon="${BLUE}❓${NC}" ;;
        esac
        
        echo -e "$status_icon $pipeline_id | $workflow | $channel | $start_time"
    done
}

function cleanup_old_pipelines() {
    local days="${1:-7}"
    
    echo -e "${YELLOW}🧹 Cleaning up pipelines older than $days days...${NC}"
    
    find "$PIPELINE_STATE_DIR" -name "*.state" -type f -mtime +$days -delete
    find "$LOGS_DIR" -name "pipeline_*.log" -type f -mtime +$days -delete
    find "$LOGS_DIR" -name "step_*.log" -type f -mtime +$days -delete
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

#==============================================================================
# MAIN EXECUTION (for testing)
#==============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script called directly - run tests
    echo -e "${PURPLE}🧪 Pipeline Manager Test Mode${NC}"
    echo ""
    
    case "${1:-test}" in
        "test")
            echo -e "${BLUE}🧪 Testing pipeline construction...${NC}"
            echo ""
            
            # Test different workflow types
            for workflow in "video_upload" "social_only" "full_pipeline"; do
                echo -e "${CYAN}Testing workflow: $workflow${NC}"
                if execute_pipeline "$workflow" "default" "lofi" "--dry-run"; then
                    echo -e "${GREEN}✅ $workflow: SUCCESS${NC}"
                else
                    echo -e "${RED}❌ $workflow: FAILED${NC}"
                fi
                echo ""
            done
            ;;
        "list")
            list_recent_pipelines "${2:-10}"
            ;;
        "cleanup")
            cleanup_old_pipelines "${2:-7}"
            ;;
        *)
            echo "Usage: $0 [test|list|cleanup]"
            ;;
    esac
fi 