package com.youtube.ai.scheduler.videocomposer.model;

public class Scene {
    private String narration;
    private String imagePrompt;
    private int durationSeconds;

    public Scene() {
    }

    public Scene(String narration, String imagePrompt, int durationSeconds) {
        this.narration = narration;
        this.imagePrompt = imagePrompt;
        this.durationSeconds = durationSeconds;
    }

    public String getNarration() {
        return narration;
    }

    public void setNarration(String narration) {
        this.narration = narration;
    }

    public String getImagePrompt() {
        return imagePrompt;
    }

    public void setImagePrompt(String imagePrompt) {
        this.imagePrompt = imagePrompt;
    }

    public int getDurationSeconds() {
        return durationSeconds;
    }

    public void setDurationSeconds(int durationSeconds) {
        this.durationSeconds = durationSeconds;
    }
}
