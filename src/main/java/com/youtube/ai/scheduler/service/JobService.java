
package com.youtube.ai.scheduler.service;

import com.youtube.ai.scheduler.model.Job;
import com.youtube.ai.scheduler.repository.JobRepository;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.TaskScheduler;
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;
import org.springframework.scheduling.support.CronTrigger;
import org.springframework.stereotype.Service;

import java.io.*;
import java.util.*;
import java.util.concurrent.ScheduledFuture;

@Service
public class JobService {

    private static final Logger logger = LoggerFactory.getLogger(JobService.class);

    private final JobRepository jobRepository;
    private final TaskScheduler scheduler;
    private final Map<Long, ScheduledFuture<?>> scheduledTasks = new HashMap<>();

    public JobService(JobRepository jobRepository) {
        this.jobRepository = jobRepository;
        ThreadPoolTaskScheduler taskScheduler = new ThreadPoolTaskScheduler();
        taskScheduler.initialize();
        this.scheduler = taskScheduler;
    }

    @PostConstruct
    public void scheduleAll() {
        List<Job> jobs = jobRepository.findAll();
        jobs.stream().filter(Job::isActive).forEach(this::scheduleJob);
    }

    public void scheduleJob(Job job) {
        Runnable task = () -> {
            logger.info("Scheduled job '{}' triggered", job.getName());
            try {
                runJob(job);
            } catch (Exception e) {
                logger.error("Error executing job '{}'", job.getName(), e);
            }
        };
        ScheduledFuture<?> future = scheduler.schedule(task, new CronTrigger(job.getCronExpression()));
        scheduledTasks.put(job.getId(), future);
    }

    public void runJob(Job job) throws IOException, InterruptedException {
        List<String> scripts = new ArrayList<>();
        scripts.add(job.getScriptPath());
        if (job.getNextScript1() != null) scripts.add(job.getNextScript1());
        if (job.getNextScript2() != null) scripts.add(job.getNextScript2());

        logger.info("Starting job '{}' with scripts {}", job.getName(), scripts);

        for (String script : scripts) {
            logger.info("Running script {} for job {}", script, job.getName());
            ProcessBuilder pb = new ProcessBuilder("bash", script);
            pb.redirectErrorStream(true);
            Process proc = pb.start();
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(proc.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    System.out.println("[JOB-" + job.getId() + "] " + line);
                }
            }
            int exitCode = proc.waitFor();
            logger.info("Script {} completed for job {} with exit code {}", script, job.getName(), exitCode);
        }
    }

    public void runNow(Long jobId) {
        jobRepository.findById(jobId).ifPresent(job -> {
            try {
                runJob(job);
            } catch (Exception e) {
                e.printStackTrace();
            }
        });
    }

    public List<Job> listJobs() {
        return jobRepository.findAll();
    }

    public Job save(Job job) {
        Job saved = jobRepository.save(job);
        if (job.isActive()) scheduleJob(saved);
        return saved;
    }

    public void delete(Long id) {
        scheduledTasks.get(id).cancel(true);
        scheduledTasks.remove(id);
        jobRepository.deleteById(id);
    }

    public Optional<Job> get(Long id) {
        return jobRepository.findById(id);
    }
}
