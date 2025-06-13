package com.youtube.ai.scheduler.repository;

import com.youtube.ai.scheduler.model.JobRun;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface JobRunRepository extends JpaRepository<JobRun, Long> {
    List<JobRun> findByJobIdOrderByRunTimeDesc(Long jobId);
}
