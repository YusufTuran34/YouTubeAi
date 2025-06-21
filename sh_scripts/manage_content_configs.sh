#!/bin/bash
# manage_content_configs.sh - Content configuration management tool

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/content_configs.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq is required but not installed. Please install jq first.${NC}"
    exit 1
fi

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}❌ Configuration file not found: $CONFIG_FILE${NC}"
    exit 1
fi

show_help() {
    echo -e "${BLUE}Content Configuration Management Tool${NC}"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  list                    - List all content types"
    echo "  show <type>             - Show details of a specific content type"
    echo "  add <type>              - Add a new content type (interactive)"
    echo "  edit <type>             - Edit an existing content type"
    echo "  remove <type>           - Remove a content type"
    echo "  validate                - Validate JSON configuration"
    echo "  backup                  - Create a backup of the configuration"
    echo "  restore <file>          - Restore from backup file"
    echo "  help                    - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 show lofi"
    echo "  $0 add tech"
    echo "  $0 remove fitness"
    echo "  $0 validate"
}

list_content_types() {
    echo -e "${BLUE}📋 Available Content Types:${NC}"
    echo ""
    
    # Get all content types
    content_types=$(jq -r '.content_types | keys[]' "$CONFIG_FILE")
    
    for type in $content_types; do
        name=$(jq -r ".content_types.$type.name" "$CONFIG_FILE")
        description=$(jq -r ".content_types.$type.description" "$CONFIG_FILE")
        video_related=$(jq -r ".content_types.$type.video_related" "$CONFIG_FILE")
        requires_zodiac=$(jq -r ".content_types.$type.requires_zodiac // false" "$CONFIG_FILE")
        
        echo -e "${GREEN}• $type${NC}"
        echo "  Name: $name"
        echo "  Description: $description"
        echo "  Video Related: $video_related"
        echo "  Requires Zodiac: $requires_zodiac"
        echo ""
    done
}

show_content_type() {
    local content_type="$1"
    
    if [[ -z "$content_type" ]]; then
        echo -e "${RED}❌ Please specify a content type${NC}"
        return 1
    fi
    
    # Check if content type exists
    if ! jq -e ".content_types.$content_type" "$CONFIG_FILE" > /dev/null 2>&1; then
        echo -e "${RED}❌ Content type '$content_type' not found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📋 Content Type: $content_type${NC}"
    echo ""
    
    # Show all details
    jq -r ".content_types.$content_type" "$CONFIG_FILE" | jq -r '
        "Name: " + .name,
        "Description: " + .description,
        "Tone: " + .tone,
        "Video Related: " + (.video_related | tostring),
        "Requires Zodiac: " + (.requires_zodiac // false | tostring),
        "",
        "Hashtags:",
        (.hashtags | join(", ")),
        "",
        "Emojis:",
        (.emojis | join(" ")),
        "",
        "Prompts:",
        (.prompts | to_entries | .[] | "  " + .key + ": " + .value)
    '
}

add_content_type() {
    local content_type="$1"
    
    if [[ -z "$content_type" ]]; then
        echo -e "${RED}❌ Please specify a content type name${NC}"
        return 1
    fi
    
    # Check if content type already exists
    if jq -e ".content_types.$content_type" "$CONFIG_FILE" > /dev/null 2>&1; then
        echo -e "${RED}❌ Content type '$content_type' already exists${NC}"
        return 1
    fi
    
    echo -e "${BLUE}➕ Adding new content type: $content_type${NC}"
    echo ""
    
    # Interactive input
    read -p "Name: " name
    read -p "Description: " description
    read -p "Tone: " tone
    read -p "Video Related (true/false): " video_related
    read -p "Requires Zodiac (true/false): " requires_zodiac
    
    echo ""
    echo "Enter hashtags (comma-separated):"
    read -p "Hashtags: " hashtags_input
    
    echo ""
    echo "Enter emojis (space-separated):"
    read -p "Emojis: " emojis_input
    
    echo ""
    echo "Enter prompts:"
    read -p "General prompt: " general_prompt
    
    # Convert inputs to JSON arrays
    hashtags_json=$(echo "$hashtags_input" | tr ',' '\n' | jq -R . | jq -s .)
    emojis_json=$(echo "$emojis_input" | tr ' ' '\n' | jq -R . | jq -s .)
    
    # Create new content type JSON
    new_content_type=$(jq -n \
        --arg name "$name" \
        --arg description "$description" \
        --arg tone "$tone" \
        --argjson video_related "$video_related" \
        --argjson requires_zodiac "$requires_zodiac" \
        --argjson hashtags "$hashtags_json" \
        --argjson emojis "$emojis_json" \
        --arg general_prompt "$general_prompt" \
        '{
            name: $name,
            description: $description,
            hashtags: $hashtags,
            emojis: $emojis,
            tone: $tone,
            video_related: $video_related,
            requires_zodiac: $requires_zodiac,
            prompts: {
                general: $general_prompt
            }
        }')
    
    # Add to config file
    jq ".content_types.$content_type = $new_content_type" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    
    echo -e "${GREEN}✅ Content type '$content_type' added successfully!${NC}"
}

remove_content_type() {
    local content_type="$1"
    
    if [[ -z "$content_type" ]]; then
        echo -e "${RED}❌ Please specify a content type to remove${NC}"
        return 1
    fi
    
    # Check if content type exists
    if ! jq -e ".content_types.$content_type" "$CONFIG_FILE" > /dev/null 2>&1; then
        echo -e "${RED}❌ Content type '$content_type' not found${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}⚠️ Are you sure you want to remove content type '$content_type'? (y/N)${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        jq "del(.content_types.$content_type)" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
        echo -e "${GREEN}✅ Content type '$content_type' removed successfully!${NC}"
    else
        echo -e "${BLUE}❌ Operation cancelled${NC}"
    fi
}

validate_config() {
    echo -e "${BLUE}🔍 Validating configuration...${NC}"
    
    # Check JSON syntax
    if jq empty "$CONFIG_FILE" 2>/dev/null; then
        echo -e "${GREEN}✅ JSON syntax is valid${NC}"
    else
        echo -e "${RED}❌ JSON syntax is invalid${NC}"
        return 1
    fi
    
    # Check required fields
    required_fields=("content_types" "zodiac_signs" "settings")
    for field in "${required_fields[@]}"; do
        if jq -e ".$field" "$CONFIG_FILE" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Required field '$field' exists${NC}"
        else
            echo -e "${RED}❌ Required field '$field' missing${NC}"
            return 1
        fi
    done
    
    # Check content types
    content_types=$(jq -r '.content_types | keys[]' "$CONFIG_FILE" 2>/dev/null)
    if [[ -n "$content_types" ]]; then
        echo -e "${GREEN}✅ Found $(echo "$content_types" | wc -l) content types${NC}"
    else
        echo -e "${RED}❌ No content types found${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Configuration is valid!${NC}"
}

backup_config() {
    local backup_file="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$CONFIG_FILE" "$backup_file"
    echo -e "${GREEN}✅ Backup created: $backup_file${NC}"
}

restore_config() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        echo -e "${RED}❌ Please specify a backup file${NC}"
        return 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        echo -e "${RED}❌ Backup file not found: $backup_file${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}⚠️ Are you sure you want to restore from '$backup_file'? (y/N)${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        cp "$backup_file" "$CONFIG_FILE"
        echo -e "${GREEN}✅ Configuration restored from: $backup_file${NC}"
    else
        echo -e "${BLUE}❌ Operation cancelled${NC}"
    fi
}

# Main script logic
case "${1:-help}" in
    "list")
        list_content_types
        ;;
    "show")
        show_content_type "$2"
        ;;
    "add")
        add_content_type "$2"
        ;;
    "remove")
        remove_content_type "$2"
        ;;
    "validate")
        validate_config
        ;;
    "backup")
        backup_config
        ;;
    "restore")
        restore_config "$2"
        ;;
    "help"|*)
        show_help
        ;;
esac 