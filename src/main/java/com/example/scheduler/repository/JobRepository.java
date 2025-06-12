
package com.example.scheduler.repository;

import com.example.scheduler.model.Job;
import org.springframework.data.jpa.repository.JpaRepository;

public interface JobRepository extends JpaRepository<Job, Long> {
}
