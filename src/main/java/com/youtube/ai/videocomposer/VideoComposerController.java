package com.youtube.ai.videocomposer;

import com.youtube.ai.videocomposer.model.StoryRequest;
import com.youtube.ai.videocomposer.model.StoryResponse;
import com.youtube.ai.videocomposer.service.VideoComposerService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/video-composer")
public class VideoComposerController {

    private final VideoComposerService service;

    public VideoComposerController(VideoComposerService service) {
        this.service = service;
    }

    @PostMapping("/story")
    public StoryResponse composeStory(@RequestBody StoryRequest request) {
        return service.generateStory(request);
    }
}
