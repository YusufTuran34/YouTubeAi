package com.youtube.ai.scheduler.videocomposer.service;

import com.youtube.ai.scheduler.videocomposer.dto.StoryVideoRequest;
import com.youtube.ai.scheduler.videocomposer.dto.StoryVideoResponse;

public interface VideoComposerService {
    StoryVideoResponse composeStoryVideo(StoryVideoRequest request);
}
