package com.youtube.ai.videocomposer.model;

import java.util.List;

/**
 * Response structure for story generation.
 */
public class StoryResponse {
    private String title;
    private long durationSeconds;
    private List<Scene> scenes;

    public StoryResponse() {
    }

    public StoryResponse(String title, long durationSeconds, List<Scene> scenes) {
        this.title = title;
        this.durationSeconds = durationSeconds;
        this.scenes = scenes;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public long getDurationSeconds() {
        return durationSeconds;
    }

    public void setDurationSeconds(long durationSeconds) {
        this.durationSeconds = durationSeconds;
    }

    public List<Scene> getScenes() {
        return scenes;
    }

    public void setScenes(List<Scene> scenes) {
        this.scenes = scenes;
    }
}
