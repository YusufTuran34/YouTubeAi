package com.youtube.ai.videocomposer.model;

/**
 * Request payload for story generation.
 */
public class StoryRequest {
    private String title;
    private String duration; // e.g. "10m", "1h"

    public StoryRequest() {
    }

    public StoryRequest(String title, String duration) {
        this.title = title;
        this.duration = duration;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDuration() {
        return duration;
    }

    public void setDuration(String duration) {
        this.duration = duration;
    }
}
