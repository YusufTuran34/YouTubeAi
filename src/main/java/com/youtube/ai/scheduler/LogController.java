package com.youtube.ai.scheduler;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import com.youtube.ai.scheduler.service.JobService;
import com.youtube.ai.scheduler.model.Job;

@Controller
@RequestMapping("/logs")
public class LogController {

    private final JobService jobService;

    public LogController(JobService jobService) {
        this.jobService = jobService;
    }

    @GetMapping("/realtime/{jobId}")
    public String realtimeLogs(@PathVariable Long jobId, Model model) {
        Job job = jobService.get(jobId)
                .orElseThrow(() -> new RuntimeException("Job not found"));
        
        model.addAttribute("job", job);
        return "real-time-logs";
    }
} 