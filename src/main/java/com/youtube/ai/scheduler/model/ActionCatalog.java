package com.youtube.ai.scheduler.model;

import java.util.*;

public class ActionCatalog {
    
    public enum ActionCategory {
        VIDEO_PRODUCTION("🎬 Video Production"),
        SOCIAL_MEDIA("📱 Social Media"),
        STREAMING("📺 Streaming"),
        CONTENT_MANAGEMENT("📄 Content Management"),
        UTILITIES("🔧 Utilities");
        
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
        // VIDEO PRODUCTION
        new ActionDefinition(
            "generate_lofi_video",
            "🎵 LOFI Video Üret",
            "Rastgele bir LOFI müzik videosu üret ve YouTube'a yükle",
            ActionCategory.VIDEO_PRODUCTION,
            Arrays.asList("sh_scripts/run_pipeline_and_upload.sh"),
            Arrays.asList(
                new ActionParameter("content_type", "İçerik Türü", ParameterType.SELECT, false)
                    .withOptions(Arrays.asList("lofi", "meditation", "nature", "ambient"))
                    .withDefault("lofi")
            ),
            "🎵"
        ),
        
        new ActionDefinition(
            "generate_video_stream",
            "📺 Video Üret ve Stream Et",
            "Video üret ve doğrudan stream olarak yayınla",
            ActionCategory.VIDEO_PRODUCTION,
            Arrays.asList("sh_scripts/run_pipeline_and_stream.sh"),
            Arrays.asList(
                new ActionParameter("content_type", "İçerik Türü", ParameterType.SELECT, false)
                    .withOptions(Arrays.asList("lofi", "meditation", "nature", "ambient"))
                    .withDefault("lofi")
            ),
            "📺"
        ),
        
        // SOCIAL MEDIA
        new ActionDefinition(
            "post_zodiac_tweet",
            "♈ Burç Tweeti At",
            "Seçilen burç için özel tweet üret ve paylaş",
            ActionCategory.SOCIAL_MEDIA,
            Arrays.asList("sh_scripts/generate_tweet_advanced.sh", "sh_scripts/post_to_twitter_simple.py"),
            Arrays.asList(
                new ActionParameter("zodiac_sign", "Burç", ParameterType.SELECT, true)
                    .withOptions(Arrays.asList("aries", "taurus", "gemini", "cancer", "leo", "virgo", 
                                             "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces"))
            ),
            "♈"
        ),
        
        new ActionDefinition(
            "post_general_tweet",
            "🐦 Genel Tweet At",
            "Belirtilen konu için tweet üret ve paylaş",
            ActionCategory.SOCIAL_MEDIA,
            Arrays.asList("sh_scripts/generate_tweet_advanced.sh", "sh_scripts/post_to_twitter_simple.py"),
            Arrays.asList(
                new ActionParameter("content_type", "İçerik Türü", ParameterType.SELECT, true)
                    .withOptions(Arrays.asList("motivation", "productivity", "mindfulness", "lofi", "general"))
            ),
            "🐦"
        ),
        
        new ActionDefinition(
            "post_instagram_story",
            "📱 Instagram Story Paylaş",
            "Hazırlanan içeriği Instagram story olarak paylaş",
            ActionCategory.SOCIAL_MEDIA,
            Arrays.asList("sh_scripts/post_instagram_story.sh"),
            new ArrayList<>(),
            "📱"
        ),
        
        // STREAMING
        new ActionDefinition(
            "start_remote_stream",
            "🔴 Uzaktan Stream Başlat",
            "Uzaktan streaming oturumu başlat",
            ActionCategory.STREAMING,
            Arrays.asList("sh_scripts/remote_stream.sh"),
            new ArrayList<>(),
            "🔴"
        ),
        
        new ActionDefinition(
            "upload_and_stream",
            "⬆️ Upload ve Stream",
            "Video upload et ve stream et",
            ActionCategory.STREAMING,
            Arrays.asList("sh_scripts/upload_and_stream.sh"),
            new ArrayList<>(),
            "⬆️"
        ),
        
        // CONTENT MANAGEMENT
        new ActionDefinition(
            "generate_thumbnail",
            "🖼️ Thumbnail Üret",
            "Videodan otomatik thumbnail üret",
            ActionCategory.CONTENT_MANAGEMENT,
            Arrays.asList("sh_scripts/generate_thumbnail_from_video.sh"),
            new ArrayList<>(),
            "🖼️"
        ),
        
        new ActionDefinition(
            "generate_title",
            "📝 Başlık Üret",
            "AI ile catchy video başlığı üret",
            ActionCategory.CONTENT_MANAGEMENT,
            Arrays.asList("sh_scripts/generate_title.sh"),
            Arrays.asList(
                new ActionParameter("topic", "Konu", ParameterType.TEXT, false)
                    .withDefault("lofi music")
            ),
            "📝"
        ),
        
        new ActionDefinition(
            "generate_description",
            "📄 Açıklama Üret",
            "Video için SEO-optimized açıklama üret",
            ActionCategory.CONTENT_MANAGEMENT,
            Arrays.asList("sh_scripts/generate_description.sh"),
            new ArrayList<>(),
            "📄"
        ),
        
        // UTILITIES
        new ActionDefinition(
            "cleanup_outputs",
            "🧹 Dosyaları Temizle",
            "Geçici dosyaları ve çıktıları temizle",
            ActionCategory.UTILITIES,
            Arrays.asList("sh_scripts/cleanup_outputs.sh"),
            new ArrayList<>(),
            "🧹"
        ),
        
        new ActionDefinition(
            "setup_stream_env",
            "⚙️ Stream Ortamını Hazırla",
            "Streaming için gerekli ortamı hazırla",
            ActionCategory.UTILITIES,
            Arrays.asList("sh_scripts/setup_stream_environment.sh"),
            new ArrayList<>(),
            "⚙️"
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