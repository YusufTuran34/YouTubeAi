
package com.example.scheduler;

import com.example.scheduler.model.Job;
import com.example.scheduler.service.JobService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/jobs")
public class JobController {

    private final JobService jobService;

    public JobController(JobService jobService) {
        this.jobService = jobService;
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
}
