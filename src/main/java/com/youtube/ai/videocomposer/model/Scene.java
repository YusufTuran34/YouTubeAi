package com.youtube.ai.videocomposer.model;

/**
 * Represents a single scene in the generated story.
 */
public class Scene {
    private int index;
    private String text;
    private String visualPrompt;

    public Scene() {
    }

    public Scene(int index, String text, String visualPrompt) {
        this.index = index;
        this.text = text;
        this.visualPrompt = visualPrompt;
    }

    public int getIndex() {
        return index;
    }

    public void setIndex(int index) {
        this.index = index;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    public String getVisualPrompt() {
        return visualPrompt;
    }

    public void setVisualPrompt(String visualPrompt) {
        this.visualPrompt = visualPrompt;
    }
}
