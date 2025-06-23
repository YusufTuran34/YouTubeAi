package com.youtube.ai.scheduler.service;

import com.youtube.ai.scheduler.model.Job;
import com.youtube.ai.scheduler.repository.JobRepository;
import com.youtube.ai.scheduler.repository.JobRunRepository;
import com.youtube.ai.scheduler.model.JobRun;
import com.youtube.ai.scheduler.model.ScheduleEntry;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.scheduling.support.CronExpression;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.TaskScheduler;
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;
import org.springframework.scheduling.support.CronTrigger;
import org.springframework.stereotype.Service;

import java.io.*;
import java.util.*;
import java.util.regex.*;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class JobService {

    private static final Logger logger = LoggerFactory.getLogger(JobService.class);

    private final JobRepository jobRepository;
    private final TaskScheduler scheduler;
    private final JobRunRepository jobRunRepository;
    // private final LogWebSocketHandler logWebSocketHandler;
    private final Map<Long, ScheduledFuture<?>> scheduledTasks = new HashMap<>();
    private final Map<Long, StringBuilder> runningLogs = new ConcurrentHashMap<>();

    public JobService(JobRepository jobRepository, JobRunRepository jobRunRepository) {
        this.jobRepository = jobRepository;
        this.jobRunRepository = jobRunRepository;
        // this.logWebSocketHandler = logWebSocketHandler;
        ThreadPoolTaskScheduler taskScheduler = new ThreadPoolTaskScheduler();
        taskScheduler.initialize();
        this.scheduler = taskScheduler;
    }

    @PostConstruct
    public void scheduleAll() {
        List<Job> jobs = jobRepository.findAll();
        jobs.stream()
                .filter(Job::isActive)
                .sorted(Comparator.comparing(job -> Optional.ofNullable(job.getSequence()).orElse(Integer.MAX_VALUE)))
                .forEach(this::scheduleJob);
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
        StringBuilder logBuilder = new StringBuilder();
        runningLogs.put(job.getId(), new StringBuilder());
        int exitCode = 0;

        for (String script : scripts) {
            logger.info("Running script {} for job {}", script, job.getName());
            List<String> command = new ArrayList<>();
            
            // Remove sh_scripts/ prefix if present since we're running from sh_scripts directory
            String scriptFile = script.startsWith("sh_scripts/") ? script.substring("sh_scripts/".length()) : script;
            
            // Detect file type and use appropriate command
            if (script.endsWith(".py")) {
                // For Python scripts, use bash to activate virtual environment first
                command.add("bash");
                command.add("-c");
                // Build the complete command with parameters
                StringBuilder pythonCommand = new StringBuilder();
                pythonCommand.append("if [ -f .venv/bin/activate ]; then source .venv/bin/activate; fi && python3 ").append(scriptFile);
                
                // Add parameters to the python command
                if (job.getScriptParams() != null && !job.getScriptParams().isBlank()) {
                    pythonCommand.append(" ").append(job.getScriptParams());
                }
                
                command.add(pythonCommand.toString());
            } else {
                command.add("bash");
                command.add(scriptFile);
                
                // Add parameters for shell scripts
                if (job.getScriptParams() != null && !job.getScriptParams().isBlank()) {
                    String[] params = job.getScriptParams().split("\\s+");
                    command.addAll(Arrays.asList(params));
                }
            }
            ProcessBuilder pb = new ProcessBuilder(command);
            
            // Set channel environment variable
            if (job.getChannel() != null && !job.getChannel().isBlank()) {
                pb.environment().put("CHANNEL", job.getChannel());
            }
            
            // Load and set API keys from channels.env
            try {
                File channelsEnv = new File("sh_scripts/channels.env");
                if (channelsEnv.exists()) {
                    String envContent = new String(java.nio.file.Files.readAllBytes(channelsEnv.toPath()));
                    
                    // Parse CHANNEL_CONFIGS JSON
                    int idx = envContent.indexOf("CHANNEL_CONFIGS='");
                    if (idx >= 0) {
                        int start = idx + "CHANNEL_CONFIGS='".length();
                        int end = envContent.indexOf("'", start);
                        if (end > start) {
                            String jsonStr = envContent.substring(start, end);
                            ObjectMapper mapper = new ObjectMapper();
                            JsonNode configs = mapper.readTree(jsonStr);
                            
                            // Find the correct channel config
                            String channelName = job.getChannel() != null ? job.getChannel() : "default";
                            for (JsonNode config : configs) {
                                if (channelName.equals(config.get("name").asText())) {
                                    // Set OpenAI API key
                                    JsonNode openai = config.get("openai");
                                    if (openai != null && openai.get("API_KEY") != null) {
                                        String apiKey = openai.get("API_KEY").asText();
                                        pb.environment().put("OPENAI_API_KEY", apiKey);
                                        logger.info("Set OPENAI_API_KEY for job {} (length: {})", job.getName(), apiKey.length());
                                    }
                                    
                                    // Set Runway API key
                                    JsonNode runway = config.get("runway");
                                    if (runway != null && runway.get("API_KEY") != null) {
                                        String runwayKey = runway.get("API_KEY").asText();
                                        pb.environment().put("RUNWAY_API_KEY", runwayKey);
                                        logger.info("Set RUNWAY_API_KEY for job {} (length: {})", job.getName(), runwayKey.length());
                                    }
                                    
                                    // Set Twitter credentials
                                    JsonNode twitter = config.get("twitter");
                                    if (twitter != null) {
                                        if (twitter.get("USERNAME") != null) {
                                            pb.environment().put("TWITTER_USERNAME", twitter.get("USERNAME").asText());
                                        }
                                        if (twitter.get("PASSWORD") != null) {
                                            pb.environment().put("TWITTER_PASSWORD", twitter.get("PASSWORD").asText());
                                        }
                                        if (twitter.get("TWITTER_USERNAME") != null) {
                                            pb.environment().put("TWITTER_HANDLE", twitter.get("TWITTER_USERNAME").asText());
                                        }
                                    }
                                    break;
                                }
                            }
                        }
                    } else {
                        logger.warn("channels.env file not found for job {}", job.getName());
                    }
                }
            } catch (Exception e) {
                logger.warn("Failed to load environment from channels.env for job {}: {}", job.getName(), e.getMessage());
                // Fallback to hardcoded values for Twitter
                pb.environment().put("TWITTER_USERNAME", "yusuf.ai.2025.01@gmail.com");
                pb.environment().put("TWITTER_PASSWORD", "159357asd!");
                pb.environment().put("TWITTER_HANDLE", "LofiRadioAi");
            }
            
            pb.directory(new File("sh_scripts"));
            pb.redirectErrorStream(true);
            Process proc = pb.start();
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(proc.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    String prefixed = "[JOB-" + job.getId() + "] " + line;
                    System.out.println(prefixed);
                    logBuilder.append(prefixed).append("\n");
                    
                    // Real-time WebSocket broadcast (temporarily disabled)
                    // logWebSocketHandler.broadcastToJob(job.getId(), prefixed);
                    
                    StringBuilder live = runningLogs.get(job.getId());
                    if (live != null) {
                        live.append(prefixed).append("\n");
                        if (live.length() > 1000) {
                            live.delete(0, live.length() - 1000);
                        }
                    }
                }
            }
            exitCode = proc.waitFor();
            logger.info("Script {} completed for job {} with exit code {}", script, job.getName(), exitCode);
        }

        job.setLastExitCode(exitCode);
        String log = logBuilder.toString();
        if (log.length() > 1000) {
            log = log.substring(log.length() - 1000);
        }
        job.setLastLog(log);
        jobRepository.save(job);

        JobRun run = new JobRun();
        run.setJob(job);
        run.setRunTime(java.time.LocalDateTime.now());
        run.setLog(log);
        run.setExitCode(exitCode);
        jobRunRepository.save(run);
        runningLogs.remove(job.getId());
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
        List<Job> jobs = jobRepository.findAll();
        jobs.sort(Comparator.comparing(job -> Optional.ofNullable(job.getSequence()).orElse(Integer.MAX_VALUE)));
        return jobs;
    }

    public Job save(Job job) {
        Job saved = jobRepository.save(job);
        if (job.isActive()) scheduleJob(saved);
        return saved;
    }

    public void delete(Long id) {
        ScheduledFuture<?> future = scheduledTasks.get(id);
        if (future != null) {
            future.cancel(true);
            scheduledTasks.remove(id);
        }
        jobRunRepository.deleteAll(jobRunRepository.findByJobIdOrderByRunTimeDesc(id));
        jobRepository.deleteById(id);
    }

    public Optional<Job> get(Long id) {
        return jobRepository.findById(id);
    }

    public boolean isRunning(Long id) {
        return runningLogs.containsKey(id);
    }

    public String getCurrentLog(Long id) {
        StringBuilder sb = runningLogs.get(id);
        return sb == null ? "" : sb.toString();
    }

    public Set<Long> getRunningJobIds() {
        return runningLogs.keySet();
    }

    public List<String> listScripts() {
        File dir = new File("sh_scripts");
        if (!dir.exists()) return Collections.emptyList();
        String[] files = dir.list((d, name) -> name.endsWith(".sh") || name.endsWith(".py"));
        if (files == null) return Collections.emptyList();
        List<String> result = new ArrayList<>();
        for (String f : files) result.add(f);
        Collections.sort(result);
        return result;
    }

    public java.time.LocalDateTime getNextRunTime(Job job) {
        try {
            CronExpression cron = CronExpression.parse(job.getCronExpression());
            return cron.next(java.time.LocalDateTime.now());
        } catch (Exception e) {
            logger.warn("Invalid cron for job {}", job.getName(), e);
            return null;
        }
    }

    public List<String> listChannels() {
        File env = new File("sh_scripts/channels.env");
        if (!env.exists()) return List.of("default");
        try {
            String text = new String(java.nio.file.Files.readAllBytes(env.toPath()));
            int idx = text.indexOf("CHANNEL_CONFIGS='");
            if (idx >= 0) {
                int start = idx + "CHANNEL_CONFIGS='".length();
                int end = text.indexOf("'", start);
                if (end > start) {
                    String json = text.substring(start, end);
                    ObjectMapper mapper = new ObjectMapper();
                    JsonNode root = mapper.readTree(json);
                    List<String> names = new ArrayList<>();
                    for (JsonNode node : root) {
                        JsonNode name = node.get("name");
                        if (name != null) names.add(name.asText());
                    }
                    return names;
                }
            }
        } catch (Exception e) {
            logger.warn("Failed to parse channels", e);
        }
        return List.of("default");
    }

    private int parseDuration(String params) {
        if (params == null) return 1;
        java.util.regex.Matcher m = java.util.regex.Pattern.compile("\\b(\\d+)\\b").matcher(params);
        if (m.find()) {
            try {
                return Integer.parseInt(m.group(1));
            } catch (NumberFormatException ignored) {}
        }
        return 1;
    }

    public List<ScheduleEntry> getWeeklySchedule() {
        List<Job> jobs = listJobs();
        List<ScheduleEntry> entries = new ArrayList<>();
        java.time.LocalDateTime start = java.time.LocalDate.now().atStartOfDay();
        java.time.LocalDateTime end = start.plusWeeks(1);
        for (Job job : jobs) {
            try {
                CronExpression cron = CronExpression.parse(job.getCronExpression());
                java.time.LocalDateTime next = cron.next(start.minusSeconds(1));
                while (next != null && !next.isAfter(end)) {
                    boolean isVideo = job.getScriptPath() != null && job.getScriptPath().contains("upload");
                    boolean isStream = job.getScriptPath() != null && job.getScriptPath().contains("stream");
                    int duration = parseDuration(job.getScriptParams());
                    if (isStream || isVideo) {
                        for (int i = 0; i < duration; i++) {
                            java.time.LocalDateTime t = next.plusHours(i);
                            if (t.isAfter(end)) break;
                            entries.add(new ScheduleEntry(job.getName(), job.getChannel(), t, isVideo));
                        }
                    } else {
                        entries.add(new ScheduleEntry(job.getName(), job.getChannel(), next, false));
                    }
                    next = cron.next(next);
                }
            } catch (Exception e) {
                logger.warn("Invalid cron for job {}", job.getName(), e);
            }
        }
        return entries;
    }
}
