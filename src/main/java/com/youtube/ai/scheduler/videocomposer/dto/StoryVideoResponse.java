package com.youtube.ai.scheduler.videocomposer.dto;

import com.youtube.ai.scheduler.videocomposer.model.Scene;
import java.util.List;

public class StoryVideoResponse {
    private String title;
    private int durationSeconds;
    private List<Scene> scenes;
    private String videoPath;

    public StoryVideoResponse() {
    }

    public StoryVideoResponse(String title, int durationSeconds, List<Scene> scenes, String videoPath) {
        this.title = title;
        this.durationSeconds = durationSeconds;
        this.scenes = scenes;
        this.videoPath = videoPath;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public int getDurationSeconds() {
        return durationSeconds;
    }

    public void setDurationSeconds(int durationSeconds) {
        this.durationSeconds = durationSeconds;
    }

    public List<Scene> getScenes() {
        return scenes;
    }

    public void setScenes(List<Scene> scenes) {
        this.scenes = scenes;
    }

    public String getVideoPath() {
        return videoPath;
    }

    public void setVideoPath(String videoPath) {
        this.videoPath = videoPath;
    }
}
