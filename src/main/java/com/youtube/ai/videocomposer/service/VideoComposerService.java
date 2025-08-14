package com.youtube.ai.videocomposer.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.youtube.ai.videocomposer.model.Scene;
import com.youtube.ai.videocomposer.model.StoryRequest;
import com.youtube.ai.videocomposer.model.StoryResponse;
import com.youtube.ai.videocomposer.util.DurationParser;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class VideoComposerService {

    @Value("${story.words-per-second:2.0}")
    private double wordsPerSecond;

    @Value("${openai.model:gpt-4o-mini}")
    private String model;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper mapper = new ObjectMapper();

    public StoryResponse generateStory(StoryRequest request) {
        long duration = DurationParser.parseToSeconds(request.getDuration());
        int targetWords = (int) Math.round(duration * wordsPerSecond);

        String prompt = buildPrompt(request.getTitle(), targetWords);

        Map<String, Object> body = Map.of(
                "model", model,
                "messages", List.of(
                        Map.of("role", "system", "content", "You are a helpful assistant that writes video stories."),
                        Map.of("role", "user", "content", prompt)
                )
        );

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        String apiKey = System.getenv("OPENAI_API_KEY");
        if (apiKey != null) {
            headers.setBearerAuth(apiKey);
        }

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);
        ResponseEntity<JsonNode> response = restTemplate.postForEntity(
                "https://api.openai.com/v1/chat/completions", entity, JsonNode.class);

        String content = response.getBody()
                .path("choices").get(0)
                .path("message")
                .path("content").asText();

        try {
            JsonNode node = mapper.readTree(content);
            List<Scene> scenes = new ArrayList<>();
            for (JsonNode sceneNode : node.path("scenes")) {
                Scene scene = new Scene(
                        sceneNode.path("index").asInt(),
                        sceneNode.path("text").asText(),
                        sceneNode.path("visual_prompt").asText()
                );
                scenes.add(scene);
            }
            return new StoryResponse(request.getTitle(), duration, scenes);
        } catch (Exception e) {
            // Fallback to raw content
            Scene scene = new Scene(1, content, "");
            return new StoryResponse(request.getTitle(), duration, List.of(scene));
        }
    }

    private String buildPrompt(String title, int words) {
        return "Write a story titled '" + title + "' around " + words + " words. " +
                "Return JSON with field 'scenes', an array where each item has 'index', 'text', and 'visual_prompt'. " +
                "Visual prompt describes the scene for a video.";
    }
}
