# 🏗️ Shell Script Architecture Design
## YouTubeAI Project - Systematik SH Yapısı

### 📋 **Design Principles**

1. **Separation of Concerns**: Her script tek bir sorumluluğa sahip
2. **Channel Abstraction**: Multi-channel support için esnek yapı  
3. **Interface Standardization**: Tutarlı input/output formatları
4. **Pipeline Architecture**: Modüler workflow management
5. **Convention over Configuration**: Naming convention ile davranış belirleme

---

## 📁 **Yeni Dizin Yapısı**

```
sh_scripts/
├── core/                           # Core sistem fonksiyonları
│   ├── common.sh                   # Ortak fonksiyonlar (mevcut)
│   ├── channel_manager.sh          # Channel abstraction layer
│   ├── pipeline_manager.sh         # Pipeline orchestration
│   └── error_handler.sh           # Centralized error handling
│
├── generators/                     # Content generation (return output)
│   ├── generate_video.sh          # Video generation
│   ├── generate_title.sh          # Title generation  
│   ├── generate_description.sh    # Description generation
│   ├── generate_tweet.sh          # Tweet generation
│   ├── generate_thumbnail.sh      # Thumbnail generation
│   └── generate_ai_background.sh  # AI background generation
│
├── processors/                    # Data transformation & processing
│   ├── process_video.sh           # Video processing/encoding
│   ├── process_audio.sh           # Audio processing
│   ├── process_content.sh         # Content optimization
│   └── process_metadata.sh       # Metadata processing
│
├── publishers/                    # Platform publishing
│   ├── youtube/
│   │   ├── upload_video.sh        # YouTube video upload
│   │   └── start_stream.sh        # YouTube live stream
│   ├── twitter/
│   │   ├── post_tweet.sh          # Twitter posting
│   │   └── post_thread.sh         # Twitter thread
│   ├── instagram/
│   │   ├── post_story.sh          # Instagram story
│   │   └── post_feed.sh           # Instagram feed
│   └── tiktok/                    # Future: TikTok support
│       └── post_video.sh
│
├── orchestrators/                 # Workflow management (run_ scripts)
│   ├── run_full_pipeline.sh       # Complete content pipeline
│   ├── run_video_workflow.sh      # Video-only workflow
│   ├── run_social_workflow.sh     # Social media only
│   ├── run_upload_workflow.sh     # Upload workflows
│   └── run_stream_workflow.sh     # Streaming workflows
│
├── utilities/                     # Helper scripts
│   ├── cleanup.sh                 # System cleanup
│   ├── health_check.sh           # System health check
│   ├── backup_manager.sh         # Backup operations
│   └── monitoring.sh             # Performance monitoring
│
├── channel_configs/               # Channel-specific configurations
│   ├── default/                   # Default channel overrides
│   ├── youtube_only/              # YouTube-only channel
│   ├── social_only/               # Social media only channel  
│   └── minimal/                   # Minimal feature set
│
└── legacy/                       # Mevcut script'lerin taşınması
    ├── [mevcut script'ler]
    └── migration_guide.md
```

---

## 🔧 **Interface Standardization**

### **Generator Interface** (generate_*.sh)
```bash
#!/bin/bash
# Standard Generator Interface

# Input: Standardized parameters
# Output: Generated content to stdout + file
# Exit Codes: 0=success, 1=error, 2=warning

function generate_content() {
    local content_type="$1"
    local channel="$2" 
    local additional_params="$3"
    
    # Generation logic
    local output="generated_content"
    
    # Return to stdout (for pipeline)
    echo "$output"
    
    # Save to file (for persistence)
    echo "$output" > "${SCRIPT_DIR}/generated_${content_type}.txt"
    
    return 0
}
```

### **Publisher Interface** (publishers/*/post_*.sh)
```bash
#!/bin/bash
# Standard Publisher Interface

# Input: Content from generator + channel config
# Output: Published URL/ID + metadata
# Exit Codes: 0=success, 1=error, 2=partial_success

function publish_content() {
    local content_file="$1"
    local channel="$2"
    local platform="$3"
    
    # Validate channel capabilities
    validate_channel_capability "$channel" "$platform"
    
    # Publishing logic
    local result_url="published_url"
    
    # Return result
    echo "$result_url"
    return 0
}
```

### **Orchestrator Interface** (orchestrators/run_*.sh)
```bash
#!/bin/bash
# Standard Orchestrator Interface

# Input: Workflow parameters + channel
# Output: Pipeline execution summary
# Exit Codes: 0=success, 1=error, 2=partial_success

function run_workflow() {
    local workflow_type="$1"
    local channel="$2"
    local params="$3"
    
    # Load channel capabilities
    load_channel_capabilities "$channel"
    
    # Execute pipeline steps
    execute_pipeline_steps "$workflow_type" "$channel" "$params"
    
    return $?
}
```

---

## 🌐 **Channel Capability Matrix**

### **channel_configs.json** (Enhanced)
```json
{
  "channels": {
    "default": {
      "name": "Main Channel",
      "capabilities": ["youtube", "twitter", "instagram"],
      "generators": {
        "video": true,
        "tweet": true, 
        "story": true,
        "thumbnail": true
      },
      "publishers": {
        "youtube_upload": true,
        "youtube_stream": true,
        "twitter_post": true,
        "instagram_story": true
      },
      "processors": {
        "video_encoding": "high_quality",
        "audio_processing": true,
        "ai_enhancement": true
      }
    },
    "youtube_only": {
      "name": "YouTube Only Channel",
      "capabilities": ["youtube", "twitter"],
      "generators": {
        "video": true,
        "tweet": true,
        "story": false,
        "thumbnail": true
      },
      "publishers": {
        "youtube_upload": true,
        "youtube_stream": true,
        "twitter_post": true,
        "instagram_story": false
      }
    },
    "social_only": {
      "name": "Social Media Only",
      "capabilities": ["twitter", "instagram"],
      "generators": {
        "video": false,
        "tweet": true,
        "story": true,
        "thumbnail": false
      },
      "publishers": {
        "youtube_upload": false,
        "youtube_stream": false,
        "twitter_post": true,
        "instagram_story": true
      }
    }
  }
}
```

---

## 🔄 **Pipeline Architecture**

### **Pipeline Flow Example**
```
[Generator] → [Processor] → [Publisher] → [Monitor]
     ↓              ↓            ↓           ↓
[Raw Content] → [Processed] → [Published] → [Analytics]
```

### **Dynamic Pipeline Construction**
```bash
# orchestrators/run_full_pipeline.sh
#!/bin/bash

CHANNEL="${1:-default}"
CONTENT_TYPE="${2:-lofi}"

# Load channel capabilities
source "core/channel_manager.sh"
load_channel_capabilities "$CHANNEL"

# Build dynamic pipeline based on capabilities
PIPELINE_STEPS=()

# Step 1: Content Generation
if has_capability "$CHANNEL" "video_generation"; then
    PIPELINE_STEPS+=("generators/generate_video.sh")
fi

if has_capability "$CHANNEL" "tweet_generation"; then
    PIPELINE_STEPS+=("generators/generate_tweet.sh")
fi

# Step 2: Processing
if has_capability "$CHANNEL" "video_processing"; then
    PIPELINE_STEPS+=("processors/process_video.sh")
fi

# Step 3: Publishing  
if has_capability "$CHANNEL" "youtube_upload"; then
    PIPELINE_STEPS+=("publishers/youtube/upload_video.sh")
fi

if has_capability "$CHANNEL" "twitter_post"; then
    PIPELINE_STEPS+=("publishers/twitter/post_tweet.sh")
fi

# Execute pipeline
execute_pipeline "${PIPELINE_STEPS[@]}"
```

---

## 🔧 **Core System Components**

### **channel_manager.sh**
```bash
#!/bin/bash
# Channel capability management

function load_channel_capabilities() {
    local channel="$1"
    
    # Load from JSON config
    CHANNEL_CONFIG=$(jq ".channels.$channel" "$CONFIG_DIR/channel_configs.json")
    
    if [[ "$CHANNEL_CONFIG" == "null" ]]; then
        echo "❌ Channel not found: $channel"
        return 1
    fi
    
    export CHANNEL_CAPABILITIES="$CHANNEL_CONFIG"
    return 0
}

function has_capability() {
    local channel="$1"
    local capability="$2"
    
    local result=$(echo "$CHANNEL_CAPABILITIES" | jq -r ".capabilities | contains([\"$capability\"])")
    [[ "$result" == "true" ]]
}

function get_publisher_config() {
    local channel="$1"
    local publisher="$2"
    
    echo "$CHANNEL_CAPABILITIES" | jq -r ".publishers.$publisher"
}
```

### **pipeline_manager.sh**
```bash
#!/bin/bash
# Pipeline execution management

function execute_pipeline() {
    local steps=("$@")
    local pipeline_id=$(date +%s)
    
    echo "🚀 Pipeline $pipeline_id başlatılıyor..."
    
    for step in "${steps[@]}"; do
        echo "⚡ Executing: $step"
        
        if ! execute_step "$step"; then
            echo "❌ Pipeline failed at: $step"
            return 1
        fi
    done
    
    echo "✅ Pipeline $pipeline_id completed successfully"
    return 0
}

function execute_step() {
    local script="$1"
    local start_time=$(date +%s)
    
    # Execute with timeout and logging
    timeout 600 bash "$script" 2>&1 | tee "logs/pipeline_${pipeline_id}_${script//\//_}.log"
    local exit_code=$?
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo "📊 Step completed in ${duration}s with exit code $exit_code"
    return $exit_code
}
```

---

## 🚀 **Migration Plan**

### **Phase 1: Core Infrastructure**
1. `core/` sistem componentlerini oluştur
2. `channel_manager.sh` ve `pipeline_manager.sh` implement et  
3. Enhanced `channel_configs.json` hazırla

### **Phase 2: Script Reorganization**
1. Mevcut script'leri yeni kategorilere taşı
2. Interface standardization uygula
3. Error handling centralize et

### **Phase 3: Pipeline Implementation** 
1. `orchestrators/` workflow'ları implement et
2. Dynamic pipeline construction
3. Channel capability validation

### **Phase 4: Testing & Optimization**
1. Multi-channel testing
2. Performance optimization  
3. Documentation update

---

## 💡 **Immediate Benefits**

1. **🔧 Maintainability**: Clear separation of concerns
2. **🌐 Scalability**: Easy addition of new channels/platforms
3. **🧪 Testability**: Isolated components for unit testing
4. **📊 Monitoring**: Centralized logging and error handling
5. **🔄 Flexibility**: Dynamic pipeline construction based on channel capabilities

Bu mimari ile hem mevcut sistem stability'nizi koruyacak hem de gelecekteki channel expansion'larınız için güçlü bir foundation oluşturacaksınız! 