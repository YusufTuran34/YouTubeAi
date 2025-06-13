package com.youtube.ai.scheduler.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
public class JobRun {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    private Job job;

    private LocalDateTime runTime;

    @Column(length = 2000)
    private String log;

    private Integer exitCode;

    // getters and setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Job getJob() { return job; }
    public void setJob(Job job) { this.job = job; }

    public LocalDateTime getRunTime() { return runTime; }
    public void setRunTime(LocalDateTime runTime) { this.runTime = runTime; }

    public String getLog() { return log; }
    public void setLog(String log) { this.log = log; }

    public Integer getExitCode() { return exitCode; }
    public void setExitCode(Integer exitCode) { this.exitCode = exitCode; }
}
