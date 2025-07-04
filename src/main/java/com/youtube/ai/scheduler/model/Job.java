
package com.youtube.ai.scheduler.model;

import jakarta.persistence.*;

@Entity
public class Job {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String scriptPath;
    private String scriptParams;
    private String channel;
    private String cronExpression;
    private String nextScript1;
    private String nextScript2;
    private boolean active;
    private Integer sequence;

    @Column(length = 2000)
    private String lastLog;
    private Integer lastExitCode;

    // Getter / Setter
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getScriptPath() { return scriptPath; }
    public void setScriptPath(String scriptPath) { this.scriptPath = scriptPath; }

    public String getScriptParams() { return scriptParams; }
    public void setScriptParams(String scriptParams) { this.scriptParams = scriptParams; }

    public String getChannel() { return channel; }
    public void setChannel(String channel) { this.channel = channel; }

    public String getCronExpression() { return cronExpression; }
    public void setCronExpression(String cronExpression) { this.cronExpression = cronExpression; }

    public String getNextScript1() { return nextScript1; }
    public void setNextScript1(String nextScript1) { this.nextScript1 = nextScript1; }

    public String getNextScript2() { return nextScript2; }
    public void setNextScript2(String nextScript2) { this.nextScript2 = nextScript2; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public String getLastLog() { return lastLog; }
    public void setLastLog(String lastLog) { this.lastLog = lastLog; }

    public Integer getLastExitCode() { return lastExitCode; }
    public void setLastExitCode(Integer lastExitCode) { this.lastExitCode = lastExitCode; }

    public Integer getSequence() { return sequence; }
    public void setSequence(Integer sequence) { this.sequence = sequence; }
}
