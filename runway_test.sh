#!/bin/bash
# runway_test.sh - Runway ML API Test

echo "🚀 RUNWAY ML API TEST"
echo "===================="

cd sh_scripts

echo "1️⃣ Environment Check..."
source common.sh
load_channel_config "default"

echo "📋 Runway API Key: ${RUNWAY_API_KEY:0:20}..."
echo "📋 OpenAI API Key: ${OPENAI_API_KEY:0:20}..."

echo ""
echo "2️⃣ JSON Config Check..."
echo "📊 Runway enabled: $(jq -r '.video_generation.runway.enabled' content_configs.json)"
echo "📊 Use runway API: $(jq -r '.video_generation.use_runway_api' content_configs.json)"
echo "📊 AI generation: $(jq -r '.video_generation.use_ai_generation' content_configs.json)"

echo ""
echo "3️⃣ Activating Runway Mode..."
jq '.video_generation.use_runway_api = true' content_configs.json > temp.json && mv temp.json content_configs.json
echo "✅ Runway API activated!"

echo ""
echo "4️⃣ Testing Runway API Connection..."
curl -s -X GET "https://api.dev.runwayml.com/v1/models" \
  -H "Authorization: Bearer $RUNWAY_API_KEY" \
  -H "Content-Type: application/json" | head -200

echo ""
echo "5️⃣ Testing AI Video Generation with Runway..."
echo "🎬 Starting video generation test..."
./generate_ai_video_background.sh lofi 2>&1 | head -20

echo ""
echo "6️⃣ Final Config Status..."
echo "📊 Current use_runway_api: $(jq -r '.video_generation.use_runway_api' content_configs.json)"
echo "📊 Runway model: $(jq -r '.video_generation.runway.model' content_configs.json)"
echo "📊 Runway duration: $(jq -r '.video_generation.runway.duration' content_configs.json)"

echo ""
echo "�� TEST COMPLETED!" 