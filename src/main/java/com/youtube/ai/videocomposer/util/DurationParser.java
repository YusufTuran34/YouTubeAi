package com.youtube.ai.videocomposer.util;

import java.time.Duration;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Utility for parsing human readable duration strings.
 * Supports formats like "10m", "1h", "5m30s", "600" (seconds) or "10s".
 */
public class DurationParser {

    private static final Pattern PATTERN = Pattern.compile("(?:(\\d+)h)?(?:(\\d+)m)?(?:(\\d+)s)?");

    private DurationParser() {
        // utility
    }

    /**
     * Parse duration string to seconds.
     *
     * @param input duration string
     * @return seconds represented by the input
     * @throws IllegalArgumentException if the input cannot be parsed
     */
    public static long parseToSeconds(String input) {
        if (input == null || input.isBlank()) {
            throw new IllegalArgumentException("Duration cannot be blank");
        }
        input = input.trim().toLowerCase();

        // If purely numeric treat as seconds
        if (input.matches("\\d+")) {
            return Long.parseLong(input);
        }

        Matcher m = PATTERN.matcher(input);
        if (m.matches()) {
            long hours = m.group(1) != null ? Long.parseLong(m.group(1)) : 0L;
            long minutes = m.group(2) != null ? Long.parseLong(m.group(2)) : 0L;
            long seconds = m.group(3) != null ? Long.parseLong(m.group(3)) : 0L;
            Duration d = Duration.ofHours(hours).plusMinutes(minutes).plusSeconds(seconds);
            if (d.isZero()) {
                throw new IllegalArgumentException("Duration cannot be zero");
            }
            return d.getSeconds();
        }
        throw new IllegalArgumentException("Invalid duration format: " + input);
    }
}
