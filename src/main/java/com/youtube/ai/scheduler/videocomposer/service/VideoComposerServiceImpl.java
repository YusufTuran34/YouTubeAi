package com.youtube.ai.scheduler.videocomposer.service;

import com.youtube.ai.scheduler.videocomposer.config.VideoComposerProperties;
import com.youtube.ai.scheduler.videocomposer.dto.StoryVideoRequest;
import com.youtube.ai.scheduler.videocomposer.dto.StoryVideoResponse;
import com.youtube.ai.scheduler.videocomposer.model.Scene;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class VideoComposerServiceImpl implements VideoComposerService {

    private final ChatGptClient chatGptClient;
    private final FfmpegVideoEngine ffmpegVideoEngine;
    private final VideoComposerProperties properties;

    public VideoComposerServiceImpl(ChatGptClient chatGptClient,
                                    FfmpegVideoEngine ffmpegVideoEngine,
                                    VideoComposerProperties properties) {
        this.chatGptClient = chatGptClient;
        this.ffmpegVideoEngine = ffmpegVideoEngine;
        this.properties = properties;
    }

    @Override
    public StoryVideoResponse composeStoryVideo(StoryVideoRequest request) {
        int duration = request.getDurationSeconds();
        if (duration > properties.getMaxDurationSeconds()) {
            throw new IllegalArgumentException("Duration exceeds allowed maximum");
        }
        List<Scene> scenes = chatGptClient.generateScenes(request.getTitle(), duration);
        String videoPath = ffmpegVideoEngine.composeVideo(scenes, request.getTitle());
        return new StoryVideoResponse(request.getTitle(), duration, scenes, videoPath);
    }
}
