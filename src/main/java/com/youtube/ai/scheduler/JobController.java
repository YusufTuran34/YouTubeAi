
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
        return "list";
    }

    @GetMapping("/new")
    public String newJob(Model model) {
        model.addAttribute("job", new Job());
        return "form";
    }

    @PostMapping
    public String saveJob(@ModelAttribute Job job) {
        jobService.save(job);
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
