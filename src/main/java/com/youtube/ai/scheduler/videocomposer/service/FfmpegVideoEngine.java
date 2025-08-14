package com.youtube.ai.scheduler.videocomposer.service;

import com.youtube.ai.scheduler.videocomposer.model.Scene;
import java.util.List;
import org.springframework.stereotype.Component;

@Component
public class FfmpegVideoEngine {

    public String composeVideo(List<Scene> scenes, String title) {
        String fileName = title.toLowerCase().replaceAll("[^a-z0-9]+", "_") + ".mp4";
        // TODO: Implement real ffmpeg composition based on scenes
        return "/tmp/" + fileName;
    }
}
