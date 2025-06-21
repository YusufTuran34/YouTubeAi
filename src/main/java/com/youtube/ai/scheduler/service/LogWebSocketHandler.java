package com.youtube.ai.scheduler.service;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.*;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;
import java.util.Map;
import java.util.Set;

@Component
public class LogWebSocketHandler extends TextWebSocketHandler {

    private static final Logger logger = LoggerFactory.getLogger(LogWebSocketHandler.class);
    
    // Job ID -> Set of sessions listening to that job
    private final Map<Long, CopyOnWriteArraySet<WebSocketSession>> jobSessions = new ConcurrentHashMap<>();
    
    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        String path = session.getUri().getPath();
        Long jobId = extractJobIdFromPath(path);
        
        if (jobId != null) {
            jobSessions.computeIfAbsent(jobId, k -> new CopyOnWriteArraySet<>()).add(session);
            logger.info("WebSocket connected for job {}, session: {}", jobId, session.getId());
        } else {
            logger.warn("Invalid WebSocket path: {}", path);
            session.close();
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        String path = session.getUri().getPath();
        Long jobId = extractJobIdFromPath(path);
        
        if (jobId != null) {
            Set<WebSocketSession> sessions = jobSessions.get(jobId);
            if (sessions != null) {
                sessions.remove(session);
                if (sessions.isEmpty()) {
                    jobSessions.remove(jobId);
                }
            }
            logger.info("WebSocket disconnected for job {}, session: {}", jobId, session.getId());
        }
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {
        logger.error("WebSocket transport error for session: {}", session.getId(), exception);
    }

    public void broadcastToJob(Long jobId, String message) {
        Set<WebSocketSession> sessions = jobSessions.get(jobId);
        if (sessions != null) {
            sessions.removeIf(session -> {
                try {
                    if (session.isOpen()) {
                        session.sendMessage(new TextMessage(message));
                        return false;
                    } else {
                        return true; // Remove closed sessions
                    }
                } catch (Exception e) {
                    logger.error("Failed to send message to session: {}", session.getId(), e);
                    return true; // Remove problematic sessions
                }
            });
        }
    }

    private Long extractJobIdFromPath(String path) {
        try {
            // Path format: /ws/logs/{jobId}
            String[] parts = path.split("/");
            if (parts.length >= 4 && "ws".equals(parts[1]) && "logs".equals(parts[2])) {
                return Long.parseLong(parts[3]);
            }
        } catch (NumberFormatException e) {
            logger.warn("Invalid job ID in path: {}", path);
        }
        return null;
    }
} 