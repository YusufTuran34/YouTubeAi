package com.youtube.ai.scheduler;

import com.youtube.ai.scheduler.model.Job;
import com.youtube.ai.scheduler.repository.JobRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class JobControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    JobRepository repository;

    @TempDir
    Path tempDir;

    private Job createJob() throws Exception {
        Path script = tempDir.resolve("c.sh");
        Files.write(script, List.of("#!/bin/bash", "echo controller"));
        script.toFile().setExecutable(true);

        Job job = new Job();
        job.setName("controller");
        job.setScriptPath(script.toString());
        job.setScriptParams("p1");
        job.setCronExpression("* * * * *");
        job.setActive(false);
        return repository.save(job);
    }

    @Test
    void listJobsPageWorks() throws Exception {
        createJob();
        mockMvc.perform(get("/jobs"))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("controller")));
    }
}
