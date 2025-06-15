package com.youtube.ai.scheduler.model;

import java.time.LocalDateTime;

public class ScheduleEntry {
    private String jobName;
    private String channel;
    private LocalDateTime time;

    public ScheduleEntry() {}
    public ScheduleEntry(String jobName, String channel, LocalDateTime time) {
        this.jobName = jobName;
        this.channel = channel;
        this.time = time;
    }

    public String getJobName() { return jobName; }
    public void setJobName(String jobName) { this.jobName = jobName; }

    public String getChannel() { return channel; }
    public void setChannel(String channel) { this.channel = channel; }

    public LocalDateTime getTime() { return time; }
    public void setTime(LocalDateTime time) { this.time = time; }
}
