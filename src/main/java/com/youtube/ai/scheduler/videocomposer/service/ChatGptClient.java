package com.youtube.ai.scheduler.videocomposer.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.youtube.ai.scheduler.videocomposer.config.VideoComposerProperties;
import com.youtube.ai.scheduler.videocomposer.model.Scene;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

@Component
public class ChatGptClient {
    private final RestTemplate restTemplate;
    private final ObjectMapper mapper;
    private final VideoComposerProperties properties;
    private final String apiKey;
    private final String apiUrl;

    public ChatGptClient(RestTemplateBuilder builder,
                         ObjectMapper mapper,
                         VideoComposerProperties properties,
                         @Value("${openai.api.url:https://api.openai.com/v1/chat/completions}") String apiUrl) {
        this.restTemplate = builder.build();
        this.mapper = mapper;
        this.properties = properties;
        this.apiKey = System.getenv("OPENAI_API_KEY");
        this.apiUrl = apiUrl;
    }

    public List<Scene> generateScenes(String title, int totalDuration) {
        if (apiKey == null || apiKey.isEmpty()) {
            return List.of(new Scene("Story about " + title, "A related scene", totalDuration));
        }
        try {
            String prompt = "Create a JSON array where each element has 'narration', 'imagePrompt', 'durationSeconds'. " +
                    "The total duration should be " + totalDuration + " seconds for a video titled '" + title + "'.";
            Map<String, Object> body = Map.of(
                    "model", properties.getOpenaiModel(),
                    "messages", List.of(Map.of("role", "user", "content", prompt))
            );
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);
            ResponseEntity<Map> response = restTemplate.postForEntity(apiUrl, entity, Map.class);
            Map<String, Object> responseBody = response.getBody();
            List<Map<String, Object>> choices = (List<Map<String, Object>>) responseBody.get("choices");
            String content = (String) ((Map) choices.get(0).get("message")).get("content");
            return Arrays.asList(mapper.readValue(content, Scene[].class));
        } catch (Exception e) {
            return List.of(new Scene("Failed to generate story: " + e.getMessage(), "Error", totalDuration));
        }
    }
}
