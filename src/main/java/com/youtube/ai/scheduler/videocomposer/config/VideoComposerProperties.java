package com.youtube.ai.scheduler.videocomposer.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "video-composer")
public class VideoComposerProperties {
    private int maxDurationSeconds = 3600;
    private int defaultSceneDuration = 10;
    private String openaiModel = "gpt-3.5-turbo";

    public int getMaxDurationSeconds() {
        return maxDurationSeconds;
    }

    public void setMaxDurationSeconds(int maxDurationSeconds) {
        this.maxDurationSeconds = maxDurationSeconds;
    }

    public int getDefaultSceneDuration() {
        return defaultSceneDuration;
    }

    public void setDefaultSceneDuration(int defaultSceneDuration) {
        this.defaultSceneDuration = defaultSceneDuration;
    }

    public String getOpenaiModel() {
        return openaiModel;
    }

    public void setOpenaiModel(String openaiModel) {
        this.openaiModel = openaiModel;
    }
}
