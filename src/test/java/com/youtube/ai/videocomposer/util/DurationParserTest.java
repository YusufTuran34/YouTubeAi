package com.youtube.ai.videocomposer.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

public class DurationParserTest {

    @Test
    void parsesMinutes() {
        assertEquals(600, DurationParser.parseToSeconds("10m"));
    }

    @Test
    void parsesHours() {
        assertEquals(3600, DurationParser.parseToSeconds("1h"));
    }

    @Test
    void parsesSeconds() {
        assertEquals(10, DurationParser.parseToSeconds("10s"));
    }

    @Test
    void parsesNumeric() {
        assertEquals(300, DurationParser.parseToSeconds("300"));
    }

    @Test
    void invalidFormatThrows() {
        assertThrows(IllegalArgumentException.class, () -> DurationParser.parseToSeconds("abc"));
    }
}
