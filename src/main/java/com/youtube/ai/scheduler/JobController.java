
package com.youtube.ai.scheduler;

import com.youtube.ai.scheduler.model.Job;
import com.youtube.ai.scheduler.service.JobService;
import com.youtube.ai.scheduler.repository.JobRunRepository;
import com.youtube.ai.scheduler.model.JobRun;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/jobs")
public class JobController {

    private final JobService jobService;
    private final JobRunRepository jobRunRepository;

    public JobController(JobService jobService, JobRunRepository jobRunRepository) {
        this.jobService = jobService;
        this.jobRunRepository = jobRunRepository;
    }

    @GetMapping
    public String listJobs(Model model) {
        model.addAttribute("jobs", jobService.listJobs());
        model.addAttribute("scripts", jobService.listScripts());
        model.addAttribute("channels", jobService.listChannels());
        return "list";
    }

    @GetMapping("/new")
    public String newJob(Model model, @RequestParam(value = "cron", required = false) String cron) {
        Job job = new Job();
        if (cron != null) job.setCronExpression(cron);
        model.addAttribute("job", job);
        return "form";
    }

    @PostMapping
    public String saveJob(@ModelAttribute Job job,
                          @RequestParam(value = "returnTo", required = false) String returnTo) {
        jobService.save(job);
        if (returnTo != null && !returnTo.isBlank()) {
            return "redirect:" + returnTo;
        }
        return "redirect:/jobs";
    }

    @GetMapping("/run/{id}")
    public String runJob(@PathVariable Long id) {
        jobService.runNow(id);
        return "redirect:/jobs";
    }

    @GetMapping("/delete/{id}")
    public String delete(@PathVariable Long id) {
        jobService.delete(id);
        return "redirect:/jobs";
    }

    @GetMapping("/logs/{id}")
    public String logs(@PathVariable Long id, Model model) {
        Job job = jobService.get(id).orElseThrow();
        model.addAttribute("job", job);
        model.addAttribute("runs", jobRunRepository.findByJobIdOrderByRunTimeDesc(id));
        return "logs";
    }

    @GetMapping("/schedule")
    public String schedulePage(Model model) {
        model.addAttribute("jobs", jobService.listJobs());
        return "schedule";
    }

    @GetMapping("/manual")
    public String manualPage(Model model) {
        model.addAttribute("scripts", jobService.listScripts());
        model.addAttribute("channels", jobService.listChannels());
        return "manual";
    }

    @PostMapping("/manual")
    public String runManual(@RequestParam String script,
                            @RequestParam String channel,
                            @RequestParam(required = false) String params) {
        Job job = new Job();
        job.setName("manual");
        job.setScriptPath(script);
        job.setScriptParams(params);
        job.setChannel(channel);
        try {
            jobService.runJob(job);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return "redirect:/jobs";
    }

    @GetMapping("/calendar")
    public String calendar(Model model) {
        model.addAttribute("entries", jobService.getWeeklySchedule());
        java.time.LocalDateTime start = java.time.LocalDate.now().atStartOfDay();
        model.addAttribute("startDate", start);
        java.util.List<String> channels = jobService.listChannels();
        java.util.Map<String, String> colors = new java.util.HashMap<>();
        String[] palette = {"red","blue","green","orange","purple","brown","teal"};
        for (int i=0;i<channels.size();i++) {
            colors.put(channels.get(i), palette[i % palette.length]);
        }
        model.addAttribute("channelColors", colors);
        return "calendar";
    }

    @PostMapping("/schedule")
    public String saveOrder(@RequestParam String order) {
        String[] ids = order.split(",");
        int idx = 1;
        for (String idStr : ids) {
            if (idStr.isBlank()) continue;
            Long id = Long.valueOf(idStr);
            Job job = jobService.get(id).orElse(null);
            if (job != null) {
                job.setSequence(idx);
                jobService.save(job);
            }
            idx++;
        }
        return "redirect:/jobs";
    }
}
