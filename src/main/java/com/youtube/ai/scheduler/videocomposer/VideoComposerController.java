package com.youtube.ai.scheduler.videocomposer;

import com.youtube.ai.scheduler.videocomposer.dto.StoryVideoRequest;
import com.youtube.ai.scheduler.videocomposer.dto.StoryVideoResponse;
import com.youtube.ai.scheduler.videocomposer.service.VideoComposerService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/video-composer")
public class VideoComposerController {
    private final VideoComposerService videoComposerService;

    public VideoComposerController(VideoComposerService videoComposerService) {
        this.videoComposerService = videoComposerService;
    }

    @PostMapping("/story")
    public StoryVideoResponse createStoryVideo(@RequestBody StoryVideoRequest request) {
        return videoComposerService.composeStoryVideo(request);
    }
}
