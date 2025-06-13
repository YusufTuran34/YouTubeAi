package com.youtube.ai.scheduler;

import com.youtube.ai.scheduler.model.Job;
import com.youtube.ai.scheduler.repository.JobRepository;
import com.youtube.ai.scheduler.service.JobService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@org.springframework.transaction.annotation.Transactional
class JobServiceTest {

    @Autowired
    private JobService jobService;
    @Autowired
    private JobRepository jobRepository;

    @TempDir
    Path tempDir;

    private Path createScript(String name) throws Exception {
        Path script = tempDir.resolve(name);
        Files.write(script, List.of("#!/bin/bash", "echo test"));
        script.toFile().setExecutable(true);
        return script;
    }

    @Test
    void saveAndRunJob() throws Exception {
        Path script = createScript("run.sh");

        Job job = new Job();
        job.setName("test");
        job.setScriptPath(script.toString());
        job.setScriptParams("foo bar");
        job.setCronExpression("0 0 1 * * *");
        job.setActive(false);

        jobService.save(job);

        List<Job> jobs = jobService.listJobs();
        assertEquals(1, jobs.size());

        jobService.runJob(jobs.get(0));
    }

    @Test
    void deleteJob() throws Exception {
        Path script = createScript("delete.sh");

        Job job = new Job();
        job.setName("del");
        job.setScriptPath(script.toString());
        job.setScriptParams("baz");
        job.setCronExpression("0 0 1 * * *");
        job.setActive(false);

        Job saved = jobService.save(job);
        assertFalse(jobService.listJobs().isEmpty());

        jobService.delete(saved.getId());
        assertTrue(jobService.listJobs().isEmpty());
    }
}
