package com.youtube.ai.scheduler.model;

import java.util.*;

public class ActionCatalog {
    
    public enum ActionCategory {
        VIDEO_PRODUCTION("🎬 Video Production"),
        SOCIAL_MEDIA("📱 Social Media"),
        STREAMING("📺 Streaming"),
        CONTENT_MANAGEMENT("📄 Content Management"),
        UTILITIES("🔧 Utilities"),
        WORKFLOWS("🔄 Workflows");
        
        private final String displayName;
        
        ActionCategory(String displayName) {
            this.displayName = displayName;
        }
        
        public String getDisplayName() {
            return displayName;
        }
    }
    
    public static class ActionDefinition {
        private String id;
        private String displayName;
        private String description;
        private ActionCategory category;
        private List<String> scriptPaths;
        private List<ActionParameter> parameters;
        private String iconEmoji;
        
        public ActionDefinition(String id, String displayName, String description, 
                              ActionCategory category, List<String> scriptPaths, 
                              List<ActionParameter> parameters, String iconEmoji) {
            this.id = id;
            this.displayName = displayName;
            this.description = description;
            this.category = category;
            this.scriptPaths = scriptPaths != null ? scriptPaths : new ArrayList<>();
            this.parameters = parameters != null ? parameters : new ArrayList<>();
            this.iconEmoji = iconEmoji;
        }
        
        // Getters
        public String getId() { return id; }
        public String getDisplayName() { return displayName; }
        public String getDescription() { return description; }
        public ActionCategory getCategory() { return category; }
        public List<String> getScriptPaths() { return scriptPaths; }
        public List<ActionParameter> getParameters() { return parameters; }
        public String getIconEmoji() { return iconEmoji; }
    }
    
    public static class ActionParameter {
        private String name;
        private String displayName;
        private ParameterType type;
        private boolean required;
        private List<String> options; // For SELECT type
        private String defaultValue;
        
        public ActionParameter(String name, String displayName, ParameterType type, boolean required) {
            this.name = name;
            this.displayName = displayName;
            this.type = type;
            this.required = required;
            this.options = new ArrayList<>();
        }
        
        public ActionParameter withOptions(List<String> options) {
            this.options = options;
            return this;
        }
        
        public ActionParameter withDefault(String defaultValue) {
            this.defaultValue = defaultValue;
            return this;
        }
        
        // Getters
        public String getName() { return name; }
        public String getDisplayName() { return displayName; }
        public ParameterType getType() { return type; }
        public boolean isRequired() { return required; }
        public List<String> getOptions() { return options; }
        public String getDefaultValue() { return defaultValue; }
    }
    
    public enum ParameterType {
        TEXT, SELECT, BOOLEAN, NUMBER
    }
    
    private static final List<ActionDefinition> ACTIONS = Arrays.asList(
        // WORKFLOW ACTIONS (NEW ARCHITECTURE)
        new ActionDefinition(
            "video_upload_workflow",
            "🎬 Video Upload Workflow",
            "Tam video üretimi ve YouTube upload workflow'ını çalıştır",
            ActionCategory.WORKFLOWS,
            Arrays.asList("orchestrators/run_workflow.sh"),
            Arrays.asList(
                new ActionParameter("workflow_type", "Workflow", ParameterType.SELECT, false)
                    .withOptions(Arrays.asList("video_upload"))
                    .withDefault("video_upload"),
                new ActionParameter("channel", "Kanal", ParameterType.SELECT, false)
                    .withOptions(Arrays.asList("default", "youtube_only", "test_channel"))
                    .withDefault("default"),
                new ActionParameter("content_type", "İçerik Türü", ParameterType.SELECT, false)
                    .withOptions(Arrays.asList("lofi", "meditation", "horoscope"))
                    .withDefault("lofi")
            ),
            "🎬"
        ),
        
        new ActionDefinition(
            "social_only_workflow",
            "📱 Social Media Workflow",
            "Sadece sosyal medya içerik üretimi ve paylaşımı",
            ActionCategory.WORKFLOWS,
            Arrays.asList("orchestrators/run_workflow.sh"),
            Arrays.asList(
                new ActionParameter("workflow_type", "Workflow", ParameterType.SELECT, false)
                    .withOptions(Arrays.asList("social_only"))
                    .withDefault("social_only"),
                new ActionParameter("channel", "Kanal", ParameterType.SELECT, false)
                    .withOptions(Arrays.asList("minimal", "social_only", "default"))
                    .withDefault("minimal"),
                new ActionParameter("content_type", "İçerik Türü", ParameterType.SELECT, false)
                    .withOptions(Arrays.asList("lofi", "meditation", "horoscope"))
                    .withDefault("lofi")
            ),
            "📱"
        ),
        
        new ActionDefinition(
            "full_pipeline_workflow",
            "🚀 Full Pipeline Workflow",
            "Komple içerik pipeline'ı - video üretimi ve tüm platform paylaşımı",
            ActionCategory.WORKFLOWS,
            Arrays.asList("orchestrators/run_workflow.sh"),
            Arrays.asList(
                new ActionParameter("workflow_type", "Workflow", ParameterType.SELECT, false)
                    .withOptions(Arrays.asList("full_pipeline"))
                    .withDefault("full_pipeline"),
                new ActionParameter("channel", "Kanal", ParameterType.SELECT, false)
                    .withOptions(Arrays.asList("default", "youtube_only"))
                    .withDefault("default"),
                new ActionParameter("content_type", "İçerik Türü", ParameterType.SELECT, false)
                    .withOptions(Arrays.asList("lofi", "meditation", "horoscope"))
                    .withDefault("lofi")
            ),
            "🚀"
        ),
        
        new ActionDefinition(
            "quick_social_post",
            "⚡ Hızlı Sosyal Medya",
            "Hızlı tweet üretimi ve paylaşımı",
            ActionCategory.WORKFLOWS,
            Arrays.asList("orchestrators/quick_social_post.sh"),
            Arrays.asList(
                new ActionParameter("content_type", "İçerik Türü", ParameterType.SELECT, true)
                    .withOptions(Arrays.asList("lofi", "meditation", "horoscope"))
                    .withDefault("lofi"),
                new ActionParameter("zodiac_sign", "Burç (Horoscope için)", ParameterType.SELECT, false)
                    .withOptions(Arrays.asList("aries", "taurus", "gemini", "cancer", "leo", "virgo", 
                                             "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces"))
                    .withDefault("aries")
            ),
            "⚡"
        ),
        
        // VIDEO PRODUCTION
        new ActionDefinition(
            "generate_video",
            "🎥 Video Üret",
            "AI ile arkaplan videosu üret",
            ActionCategory.VIDEO_PRODUCTION,
            Arrays.asList("generators/generate_video.sh"),
            Arrays.asList(
                new ActionParameter("content_type", "İçerik Türü", ParameterType.SELECT, false)
                    .withOptions(Arrays.asList("lofi", "meditation", "horoscope"))
                    .withDefault("lofi")
            ),
            "🎥"
        ),
        
        new ActionDefinition(
            "generate_ai_background",
            "🎨 AI Background Üret",
            "ChatGPT + DALL-E ile configuratif video background üret",
            ActionCategory.VIDEO_PRODUCTION,
            Arrays.asList("generators/generate_ai_video_background.sh"),
            Arrays.asList(
                new ActionParameter("content_type", "İçerik Türü", ParameterType.SELECT, true)
                    .withOptions(Arrays.asList("lofi", "meditation", "horoscope"))
                    .withDefault("lofi")
            ),
            "🎨"
        ),
        
        // SOCIAL MEDIA
        new ActionDefinition(
            "generate_tweet",
            "📝 Tweet Üret",
            "AI ile tweet içeriği üret",
            ActionCategory.SOCIAL_MEDIA,
            Arrays.asList("generators/generate_tweet_advanced.sh"),
            Arrays.asList(
                new ActionParameter("content_type", "İçerik Türü", ParameterType.SELECT, true)
                    .withOptions(Arrays.asList("lofi", "meditation", "horoscope"))
                    .withDefault("lofi"),
                new ActionParameter("zodiac_sign", "Burç (Horoscope için)", ParameterType.SELECT, false)
                    .withOptions(Arrays.asList("aries", "taurus", "gemini", "cancer", "leo", "virgo", 
                                             "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces"))
                    .withDefault("aries")
            ),
            "📝"
        ),
        
        new ActionDefinition(
            "post_tweet",
            "🐦 Tweet Gönder",
            "Üretilen tweet'i Twitter'a gönder",
            ActionCategory.SOCIAL_MEDIA,
            Arrays.asList("publishers/twitter/post_tweet.sh"),
            Arrays.asList(
                new ActionParameter("tweet_content", "Tweet İçeriği", ParameterType.TEXT, false)
                    .withDefault("")
            ),
            "🐦"
        ),
        
        new ActionDefinition(
            "post_twitter_direct",
            "🐦 Direkt Twitter Post",
            "Python ile direkt Twitter posting",
            ActionCategory.SOCIAL_MEDIA,
            Arrays.asList("publishers/twitter/post_to_twitter_simple.py"),
            Arrays.asList(
                new ActionParameter("content_type", "İçerik Türü", ParameterType.SELECT, true)
                    .withOptions(Arrays.asList("lofi", "meditation", "horoscope"))
                    .withDefault("lofi"),
                new ActionParameter("zodiac_sign", "Burç (Horoscope için)", ParameterType.SELECT, false)
                    .withOptions(Arrays.asList("aries", "taurus", "gemini", "cancer", "leo", "virgo", 
                                             "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces"))
                    .withDefault("aries")
            ),
            "🐦"
        ),
        
        new ActionDefinition(
            "post_instagram_story",
            "📱 Instagram Story",
            "Instagram story paylaş",
            ActionCategory.SOCIAL_MEDIA,
            Arrays.asList("publishers/instagram/post_instagram_story.sh"),
            new ArrayList<>(),
            "📱"
        ),
        
        // STREAMING
        new ActionDefinition(
            "upload_video",
            "⬆️ YouTube Upload",
            "Video'yu YouTube'a upload et",
            ActionCategory.STREAMING,
            Arrays.asList("publishers/youtube/upload_video.sh"),
            new ArrayList<>(),
            "⬆️"
        ),
        
        new ActionDefinition(
            "start_stream",
            "🔴 YouTube Stream",
            "YouTube canlı yayını başlat",
            ActionCategory.STREAMING,
            Arrays.asList("publishers/youtube/upload_and_stream.sh"),
            new ArrayList<>(),
            "🔴"
        ),
        
        // CONTENT MANAGEMENT
        new ActionDefinition(
            "generate_title",
            "📄 Başlık Üret",
            "AI ile video başlığı üret",
            ActionCategory.CONTENT_MANAGEMENT,
            Arrays.asList("generators/generate_title.sh"),
            new ArrayList<>(),
            "📄"
        ),
        
        new ActionDefinition(
            "generate_description",
            "📝 Açıklama Üret",
            "AI ile video açıklaması üret",
            ActionCategory.CONTENT_MANAGEMENT,
            Arrays.asList("generators/generate_description.sh"),
            new ArrayList<>(),
            "📝"
        ),
        
        new ActionDefinition(
            "generate_thumbnail",
            "🖼️ Thumbnail Üret",
            "Videodan thumbnail üret",
            ActionCategory.CONTENT_MANAGEMENT,
            Arrays.asList("generators/generate_thumbnail_from_video.sh"),
            new ArrayList<>(),
            "🖼️"
        ),
        
        // UTILITIES
        new ActionDefinition(
            "test_architecture",
            "🧪 Architecture Test",
            "Yeni shell script architecture'ını test et",
            ActionCategory.UTILITIES,
            Arrays.asList("utilities/test_architecture.sh"),
            Arrays.asList(
                new ActionParameter("test_type", "Test Türü", ParameterType.SELECT, false)
                    .withOptions(Arrays.asList("all", "deps", "config", "core", "workflows"))
                    .withDefault("all")
            ),
            "🧪"
        ),
        
        new ActionDefinition(
            "cleanup_system",
            "🧹 Sistem Temizliği",
            "Chrome processes ve temp files temizliği",
            ActionCategory.UTILITIES,
            Arrays.asList("utilities/auto_cleanup.sh"),
            new ArrayList<>(),
            "🧹"
        ),
        
        new ActionDefinition(
            "quick_test",
            "⚡ Hızlı Test",
            "Sistem componentlerini hızlı test et",
            ActionCategory.UTILITIES,
            Arrays.asList("utilities/quick_test.sh"),
            Arrays.asList(
                new ActionParameter("test_type", "Test Türü", ParameterType.SELECT, false)
                    .withOptions(Arrays.asList("all", "config", "tweet", "horoscope", "lofi"))
                    .withDefault("all")
            ),
            "⚡"
        )
    );
    
    public static List<ActionDefinition> getAllActions() {
        return new ArrayList<>(ACTIONS);
    }
    
    public static List<ActionDefinition> getActionsByCategory(ActionCategory category) {
        return ACTIONS.stream()
                .filter(action -> action.getCategory() == category)
                .collect(ArrayList::new, ArrayList::add, ArrayList::addAll);
    }
    
    public static Optional<ActionDefinition> getActionById(String id) {
        return ACTIONS.stream()
                .filter(action -> action.getId().equals(id))
                .findFirst();
    }
    
    public static List<ActionCategory> getAllCategories() {
        return Arrays.asList(ActionCategory.values());
    }
} 