package com.youtube.ai.scheduler.videocomposer;

import com.youtube.ai.scheduler.videocomposer.dto.StoryVideoRequest;
import com.youtube.ai.scheduler.videocomposer.dto.StoryVideoResponse;
import com.youtube.ai.scheduler.videocomposer.model.Scene;
import com.youtube.ai.scheduler.videocomposer.service.VideoComposerService;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(VideoComposerController.class)
class VideoComposerControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private VideoComposerService videoComposerService;

    @Test
    void composeStoryVideoReturnsPlan() throws Exception {
        Scene scene = new Scene("Once", "forest", 10);
        StoryVideoResponse response = new StoryVideoResponse("Test", 10, List.of(scene), "/tmp/test.mp4");
        Mockito.when(videoComposerService.composeStoryVideo(any(StoryVideoRequest.class))).thenReturn(response);

        String body = "{\"title\":\"Test\",\"durationSeconds\":10}";
        mockMvc.perform(post("/video-composer/story").contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.title").value("Test"))
            .andExpect(jsonPath("$.scenes[0].imagePrompt").value("forest"));
    }
}
