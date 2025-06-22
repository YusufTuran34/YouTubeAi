#!/bin/bash
# generate_ai_video_background.sh - Generate video background using AI with configurable tags

# Set PATH to ensure commands work
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTENT_TYPE="${1:-lofi}"
CONFIG_OVERRIDE="${2:-}"

# Load channel configuration to get OpenAI API key
if [ -f "$SCRIPT_DIR/common.sh" ]; then
    source "$SCRIPT_DIR/common.sh" 2>/dev/null || true
    load_channel_config "${CHANNEL:-default}" "$CONFIG_OVERRIDE" 2>/dev/null || true
fi

# JSON configuration file path
CONFIG_FILE="$SCRIPT_DIR/content_configs.json"

# Check if JSON config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Check if OpenAI API key is loaded
if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ OpenAI API key not found in configuration"
    exit 1
fi

# Validate content type using JSON
VALID_CONTENT_TYPES=$(jq -r '.content_types | keys | join(" ")' "$CONFIG_FILE")
if ! echo "$VALID_CONTENT_TYPES" | grep -q "$CONTENT_TYPE"; then
    echo "❌ Invalid content type: $CONTENT_TYPE"
    echo "✅ Available types: $VALID_CONTENT_TYPES"
    exit 1
fi

echo "🎬 AI Video Background Generation Starting..."
echo "🎯 Content Type: $CONTENT_TYPE"

# Check if video generation is enabled
VIDEO_GEN_ENABLED=$(jq -r '.video_generation.enabled' "$CONFIG_FILE")
USE_AI_GENERATION=$(jq -r '.video_generation.use_ai_generation' "$CONFIG_FILE")
USE_RUNWAY_API=$(jq -r '.video_generation.use_runway_api // false' "$CONFIG_FILE")

if [[ "$VIDEO_GEN_ENABLED" != "true" ]]; then
    echo "❌ Video generation is disabled in configuration"
    exit 1
fi

if [[ "$USE_AI_GENERATION" != "true" ]]; then
    echo "ℹ️ AI generation is disabled, falling back to Google Drive"
    exit 2  # Special exit code for fallback
fi

# Load content-specific video generation settings
VISUAL_TAGS=$(jq -r ".content_types.$CONTENT_TYPE.video_generation.visual_tags | join(\", \")" "$CONFIG_FILE")
BACKGROUND_PROMPT=$(jq -r ".content_types.$CONTENT_TYPE.video_generation.background_prompt" "$CONFIG_FILE")
ANIMATION_STYLE=$(jq -r ".content_types.$CONTENT_TYPE.video_generation.animation_style" "$CONFIG_FILE")
COLOR_PALETTE=$(jq -r ".content_types.$CONTENT_TYPE.video_generation.color_palette" "$CONFIG_FILE")
MOOD=$(jq -r ".content_types.$CONTENT_TYPE.video_generation.mood" "$CONFIG_FILE")

# Load global video generation settings
AI_MODEL=$(jq -r '.video_generation.ai_model' "$CONFIG_FILE")
FRAME_COUNT=$(jq -r '.video_generation.frame_count' "$CONFIG_FILE")
OUTPUT_FORMAT=$(jq -r '.video_generation.output_format' "$CONFIG_FILE")
RESOLUTION=$(jq -r '.video_generation.resolution' "$CONFIG_FILE")
QUALITY=$(jq -r '.video_generation.openai.quality' "$CONFIG_FILE")
STYLE=$(jq -r '.video_generation.openai.style' "$CONFIG_FILE")

echo "📝 Visual Tags: $VISUAL_TAGS"
echo "🎨 Background Prompt: $BACKGROUND_PROMPT"
echo "🎭 Animation Style: $ANIMATION_STYLE"
echo "🌈 Color Palette: $COLOR_PALETTE"
echo "💭 Mood: $MOOD"

# Check if Runway API should be used
if [[ "$USE_RUNWAY_API" == "true" && -n "$RUNWAY_API_KEY" ]]; then
    echo "🚀 Using Runway ML Gen-4 Turbo for REAL video generation..."
    
    # Create enhanced prompt for Runway
    RUNWAY_PROMPT="$BACKGROUND_PROMPT. $ANIMATION_STYLE animation with $COLOR_PALETTE colors, $MOOD mood. Visual elements: $VISUAL_TAGS. Create smooth, realistic motion with proper physics and coherent scene transitions."
    
    echo "🎬 Generating real video with Runway ML..."
    echo "📝 Prompt: $RUNWAY_PROMPT"
    
    # Create output filename with timestamp
    TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
    OUTPUT_FILE="$SCRIPT_DIR/runway_generated_background_${CONTENT_TYPE}_${TIMESTAMP}.mp4"
    
    # Generate a base image first with DALL-E for Runway
    BASE_IMAGE_RESPONSE=$(curl -s -X POST "https://api.openai.com/v1/images/generations" \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{
        \"model\": \"dall-e-3\",
        \"prompt\": \"$BACKGROUND_PROMPT\",
        \"n\": 1,
        \"size\": \"1024x1024\",
        \"quality\": \"standard\"
      }")
    
    BASE_IMAGE_URL=$(echo "$BASE_IMAGE_RESPONSE" | jq -r '.data[0].url')
    
    if [[ -z "$BASE_IMAGE_URL" || "$BASE_IMAGE_URL" == "null" ]]; then
        echo "❌ Failed to generate base image for Runway"
        echo "🔄 Falling back to DALL-E frame generation..."
        USE_RUNWAY_API="false"
    else
        echo "✅ Base image generated: ${BASE_IMAGE_URL:0:50}..."
        
        # Call Runway API for image-to-video generation (CORRECTED)
        RUNWAY_RESPONSE=$(curl -s -X POST "https://api.dev.runwayml.com/v1/image_to_video" \
          -H "Authorization: Bearer $RUNWAY_API_KEY" \
          -H "Content-Type: application/json" \
          -H "X-Runway-Version: 2024-11-06" \
          -d "{
            \"model\": \"gen3a_turbo\",
            \"promptImage\": \"$BASE_IMAGE_URL\",
            \"promptText\": \"$RUNWAY_PROMPT\",
            \"duration\": 5,
            \"ratio\": \"1280:768\"
          }")
    fi
    
    # Extract task ID
    TASK_ID=$(echo "$RUNWAY_RESPONSE" | jq -r '.id')
    
    if [[ -z "$TASK_ID" || "$TASK_ID" == "null" ]]; then
        echo "❌ Failed to start Runway video generation"
        echo "🔄 Falling back to DALL-E frame generation..."
        USE_RUNWAY_API="false"
    else
        echo "✅ Runway task started: $TASK_ID"
        echo "⏳ Waiting for video generation (30-60 seconds)..."
        
        # Poll for completion
        for i in {1..30}; do
            sleep 3
            STATUS_RESPONSE=$(curl -s -H "Authorization: Bearer $RUNWAY_API_KEY" \
                "https://api.dev.runwayml.com/v1/tasks/$TASK_ID")
            
            STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.status')
            
            if [[ "$STATUS" == "SUCCEEDED" ]]; then
                VIDEO_URL=$(echo "$STATUS_RESPONSE" | jq -r '.output[0]')
                echo "🎉 Runway video generation completed!"
                
                # Download the video
                curl -s -L "$VIDEO_URL" -o "$OUTPUT_FILE"
                
                if [[ -f "$OUTPUT_FILE" ]]; then
                    echo "✅ Real AI video created successfully: $OUTPUT_FILE"
                    echo "$OUTPUT_FILE"
                    exit 0
                else
                    echo "❌ Failed to download Runway video"
                fi
                break
            elif [[ "$STATUS" == "FAILED" ]]; then
                echo "❌ Runway video generation failed"
                break
            else
                echo "⏳ Status: $STATUS (attempt $i/30)"
            fi
        done
        
        echo "⚠️ Runway generation timeout or failed, falling back to DALL-E..."
        USE_RUNWAY_API="false"
    fi
fi

# Fallback to original DALL-E + FFmpeg system
if [[ "$USE_RUNWAY_API" != "true" ]]; then
    echo "🔄 Using DALL-E frame generation system..."
    
    # Create enhanced prompt for ChatGPT to generate detailed image descriptions
    CHATGPT_PROMPT="Based on the content type '$CONTENT_TYPE', create $FRAME_COUNT detailed image descriptions for video frames that will be used to create an animated background. Content Details: Visual Tags: $VISUAL_TAGS, Base Prompt: $BACKGROUND_PROMPT, Animation Style: $ANIMATION_STYLE, Color Palette: $COLOR_PALETTE, Mood: $MOOD. Requirements: 1. Each frame description should be detailed enough for DALL-E image generation 2. Frames should have subtle differences to create smooth animation when combined 3. Maintain consistent style and mood across all frames 4. Include lighting, composition, and visual elements 5. Each description should be 1-2 sentences maximum. Return ONLY the frame descriptions separated by '---', no additional text."

    echo "🤖 Generating detailed frame descriptions with ChatGPT..."

    # Call ChatGPT to generate frame descriptions
    CHATGPT_RESPONSE=$(curl -s -X POST "https://api.openai.com/v1/chat/completions" \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{
        \"model\": \"gpt-4\",
        \"messages\": [
          {
            \"role\": \"system\",
            \"content\": \"You are an expert at creating detailed visual descriptions for AI image generation. Create descriptions that will result in consistent, high-quality animated sequences.\"
          },
          {
            \"role\": \"user\",
            \"content\": \"$CHATGPT_PROMPT\"
          }
        ],
        \"max_tokens\": 800,
        \"temperature\": 0.7
      }")

    # Extract frame descriptions
    FRAME_DESCRIPTIONS=$(echo "$CHATGPT_RESPONSE" | jq -r '.choices[0].message.content' | tr -d '\n')

    if [[ -z "$FRAME_DESCRIPTIONS" || "$FRAME_DESCRIPTIONS" == "null" ]]; then
        echo "❌ Failed to generate frame descriptions with ChatGPT"
        exit 1
    fi

    echo "✅ Frame descriptions generated successfully"

    # Create temporary directory for frames
    TMP_DIR=$(mktemp -d)
    echo "📁 Working directory: $TMP_DIR"

    # Split frame descriptions and generate images
    IFS='---' read -ra DESCRIPTIONS <<< "$FRAME_DESCRIPTIONS"
    FRAME_FILES=()

    for i in "${!DESCRIPTIONS[@]}"; do
        FRAME_NUM=$((i + 1))
        DESCRIPTION="${DESCRIPTIONS[$i]}"
        DESCRIPTION=$(echo "$DESCRIPTION" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')  # Trim whitespace
        
        if [[ -z "$DESCRIPTION" ]]; then
            continue
        fi
        
        echo "🖼️ Generating frame $FRAME_NUM: $DESCRIPTION"
        
        # Generate image with DALL-E
        DALLE_RESPONSE=$(curl -s -X POST "https://api.openai.com/v1/images/generations" \
          -H "Authorization: Bearer $OPENAI_API_KEY" \
          -H "Content-Type: application/json" \
          -d "{
            \"model\": \"$AI_MODEL\",
            \"prompt\": \"$DESCRIPTION\",
            \"n\": 1,
            \"size\": \"$RESOLUTION\",
            \"quality\": \"$QUALITY\",
            \"style\": \"$STYLE\"
          }")
        
        # Extract image URL
        IMAGE_URL=$(echo "$DALLE_RESPONSE" | jq -r '.data[0].url')
        
        if [[ -z "$IMAGE_URL" || "$IMAGE_URL" == "null" ]]; then
            echo "❌ Failed to generate frame $FRAME_NUM"
            continue
        fi
        
        # Download image
        FRAME_FILE="$TMP_DIR/frame_$(printf "%03d" $FRAME_NUM).png"
        curl -s -L "$IMAGE_URL" -o "$FRAME_FILE"
        
        if [[ -f "$FRAME_FILE" ]]; then
            echo "✅ Frame $FRAME_NUM downloaded successfully"
            FRAME_FILES+=("$FRAME_FILE")
        else
            echo "❌ Failed to download frame $FRAME_NUM"
        fi
    done

    # Check if we have any frames
    if [[ ${#FRAME_FILES[@]} -eq 0 ]]; then
        echo "❌ No frames were generated successfully"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    echo "📹 Creating animated $(echo "$OUTPUT_FORMAT" | tr '[:lower:]' '[:upper:]') from ${#FRAME_FILES[@]} frames..."

    # Create output filename with timestamp
    TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
    OUTPUT_FILE="$SCRIPT_DIR/ai_generated_background_${CONTENT_TYPE}_${TIMESTAMP}.${OUTPUT_FORMAT}"

    # Create animation based on format (fallback to single frame if ffmpeg not available)
    if command -v ffmpeg >/dev/null 2>&1; then
        if [[ "$OUTPUT_FORMAT" == "gif" ]]; then
            # Create GIF
            echo "🔍 Creating GIF with ffmpeg..."
            ffmpeg -y -framerate 0.5 -pattern_type glob -i "$TMP_DIR/frame_*.png" \
                -vf "scale=512:512,fps=10" \
                "$OUTPUT_FILE" >/dev/null 2>&1
        elif [[ "$OUTPUT_FORMAT" == "mp4" ]]; then
            # Create MP4
            echo "🔍 Creating MP4 with ffmpeg..."
            ffmpeg -y -framerate 0.5 -pattern_type glob -i "$TMP_DIR/frame_*.png" \
                -vf "scale=512:512,fps=30" \
                -c:v libx264 -pix_fmt yuv420p \
                "$OUTPUT_FILE" >/dev/null 2>&1
        else
            echo "❌ Unsupported output format: $OUTPUT_FORMAT"
            rm -rf "$TMP_DIR"
            exit 1
        fi
    else
        echo "⚠️ FFmpeg not found, using single frame as fallback..."
        # Use the last frame as output
        LAST_FRAME=$(ls "$TMP_DIR"/frame_*.png | sort | tail -1)
        OUTPUT_FILE="${OUTPUT_FILE%.*}.png"  # Change extension to png
        cp "$LAST_FRAME" "$OUTPUT_FILE"
    fi

    # Clean up temporary files
    rm -rf "$TMP_DIR"

    # Check if output file was created successfully
    if [[ -f "$OUTPUT_FILE" ]]; then
        echo "✅ AI-generated video background created successfully: $OUTPUT_FILE"
        echo "$OUTPUT_FILE"  # Output the filename for use by other scripts
        exit 0
    else
        echo "❌ Failed to create animated video background"
        exit 1
    fi
fi 