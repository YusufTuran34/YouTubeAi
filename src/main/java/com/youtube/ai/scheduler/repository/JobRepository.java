
package com.youtube.ai.scheduler.repository;

import com.youtube.ai.scheduler.model.Job;
import org.springframework.data.jpa.repository.JpaRepository;

public interface JobRepository extends JpaRepository<Job, Long> {
}
