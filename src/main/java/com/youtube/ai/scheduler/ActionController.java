package com.youtube.ai.scheduler;

import com.youtube.ai.scheduler.model.ActionCatalog;
import com.youtube.ai.scheduler.model.ActionCatalog.ActionDefinition;
import com.youtube.ai.scheduler.model.ActionCatalog.ActionCategory;
import com.youtube.ai.scheduler.model.Job;
import com.youtube.ai.scheduler.service.JobService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.concurrent.CompletableFuture;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.file.Paths;
import java.util.*;
import java.util.stream.Collectors;

@Controller
@RequestMapping("/actions")
public class ActionController {

    @Autowired
    private JobService jobService;

    @GetMapping
    public String listActions(Model model) {
        List<ActionDefinition> allActions = ActionCatalog.getAllActions();
        
        // Group actions by category
        Map<ActionCategory, List<ActionDefinition>> actionsByCategory = 
            allActions.stream().collect(Collectors.groupingBy(ActionDefinition::getCategory));
        
        model.addAttribute("actionsByCategory", actionsByCategory);
        model.addAttribute("categories", ActionCatalog.getAllCategories());
        
        return "actions";
    }

    @GetMapping("/quick")
    public String quickActions(Model model) {
        // Get frequently used actions for quick access
        List<ActionDefinition> quickActions = ActionCatalog.getAllActions().stream()
            .filter(action -> isQuickAction(action.getId()))
            .collect(Collectors.toList());
        
        model.addAttribute("quickActions", quickActions);
        return "quick-actions";
    }

    @GetMapping("/run/{actionId}")
    public String showActionForm(@PathVariable String actionId, Model model) {
        Optional<ActionDefinition> actionOpt = ActionCatalog.getActionById(actionId);
        
        if (actionOpt.isEmpty()) {
            model.addAttribute("error", "Action not found: " + actionId);
            return "error";
        }
        
        ActionDefinition action = actionOpt.get();
        model.addAttribute("action", action);
        
        return "action-form";
    }

    @PostMapping("/execute")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> executeAction(
            @RequestBody Map<String, Object> request) {
        
        String actionId = (String) request.get("actionId");
        Map<String, String> parameters = (Map<String, String>) request.getOrDefault("parameters", new HashMap<>());
        
        Optional<ActionDefinition> actionOpt = ActionCatalog.getActionById(actionId);
        
        if (actionOpt.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", "Action not found: " + actionId
            ));
        }
        
        ActionDefinition action = actionOpt.get();
        
        try {
            // Execute the action asynchronously
            CompletableFuture<Map<String, Object>> future = CompletableFuture.supplyAsync(() -> {
                return executeActionScripts(action, parameters);
            });
            
            // For now, return immediately with job submission confirmation
            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Action '" + action.getDisplayName() + "' başlatıldı",
                "actionId", actionId,
                "parameters", parameters
            ));
            
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of(
                "success", false,
                "message", "Error executing action: " + e.getMessage()
            ));
        }
    }

    @PostMapping("/execute-quick")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> executeQuickAction(
            @RequestBody Map<String, Object> request) {
        
        String actionId = (String) request.get("actionId");
        Map<String, String> parameters = (Map<String, String>) request.getOrDefault("parameters", new HashMap<>());
        
        // Add execution tracking
        System.out.println("🚀 Executing quick action: " + actionId);
        System.out.println("📋 Parameters: " + parameters);
        
        Optional<ActionDefinition> actionOpt = ActionCatalog.getActionById(actionId);
        
        if (actionOpt.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", "Action not found: " + actionId,
                "actionId", actionId
            ));
        }
        
        ActionDefinition action = actionOpt.get();
        
        try {
            // Execute action immediately for quick actions
            Map<String, Object> result = executeActionScripts(action, parameters);
            
            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Action '" + action.getDisplayName() + "' tamamlandı",
                "actionId", actionId,
                "parameters", parameters,
                "result", result
            ));
            
        } catch (Exception e) {
            System.err.println("❌ Error executing quick action: " + e.getMessage());
            e.printStackTrace();
            
            return ResponseEntity.internalServerError().body(Map.of(
                "success", false,
                "message", "Error executing action: " + e.getMessage(),
                "actionId", actionId,
                "error", e.getClass().getSimpleName()
            ));
        }
    }

    @PostMapping("/execute-workflow")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> executeWorkflow(
            @RequestBody Map<String, Object> request) {
        
        String workflowType = (String) request.get("workflow_type");
        String channel = (String) request.getOrDefault("channel", "default");
        String contentType = (String) request.getOrDefault("content_type", "lofi");
        Map<String, String> additionalParams = (Map<String, String>) request.getOrDefault("additional_params", new HashMap<>());
        
        System.out.println("🔄 Executing workflow: " + workflowType);
        System.out.println("📡 Channel: " + channel);
        System.out.println("🎵 Content Type: " + contentType);
        
        try {
            // Build command for orchestrator
            List<String> command = new ArrayList<>();
            command.add("sh");
            command.add("sh_scripts/orchestrators/run_workflow.sh");
            command.add(workflowType);
            command.add(channel);
            command.add(contentType);
            
            // Add additional parameters
            for (Map.Entry<String, String> param : additionalParams.entrySet()) {
                command.add(param.getKey() + "=" + param.getValue());
            }
            
            ProcessBuilder pb = new ProcessBuilder(command);
            pb.directory(Paths.get(".").toFile());
            pb.redirectErrorStream(true);
            
            Process process = pb.start();
            
            // Read output
            StringBuilder output = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    output.append(line).append("\n");
                }
            }
            
            int exitCode = process.waitFor();
            
            return ResponseEntity.ok(Map.of(
                "success", exitCode == 0,
                "message", exitCode == 0 ? "Workflow completed successfully" : "Workflow failed with exit code " + exitCode,
                "workflow_type", workflowType,
                "channel", channel,
                "content_type", contentType,
                "exit_code", exitCode,
                "output", output.toString()
            ));
            
        } catch (Exception e) {
            System.err.println("❌ Error executing workflow: " + e.getMessage());
            e.printStackTrace();
            
            return ResponseEntity.internalServerError().body(Map.of(
                "success", false,
                "message", "Error executing workflow: " + e.getMessage(),
                "workflow_type", workflowType,
                "error", e.getClass().getSimpleName()
            ));
        }
    }

    private boolean isQuickAction(String actionId) {
        // Define which actions are considered "quick actions"
        Set<String> quickActionIds = Set.of(
            "quick_social_post",
            "full_pipeline_workflow", 
            "video_upload_workflow",
            "social_only_workflow",
            "post_twitter_direct",
            "generate_tweet",
            "cleanup_system",
            "test_architecture"
        );
        return quickActionIds.contains(actionId);
    }

    private Map<String, Object> executeActionScripts(ActionDefinition action, Map<String, String> parameters) {
        List<String> scriptPaths = action.getScriptPaths();
        Map<String, Object> results = new HashMap<>();
        
        System.out.println("🎬 Executing action: " + action.getDisplayName());
        System.out.println("📜 Scripts: " + scriptPaths);
        System.out.println("📋 Parameters: " + parameters);
        
        for (String scriptPath : scriptPaths) {
            try {
                Map<String, Object> scriptResult = executeScript(scriptPath, parameters);
                results.put(scriptPath, scriptResult);
                
                // If any script fails, stop execution
                if (!(Boolean) scriptResult.getOrDefault("success", false)) {
                    break;
                }
                
            } catch (Exception e) {
                System.err.println("❌ Error executing script " + scriptPath + ": " + e.getMessage());
                results.put(scriptPath, Map.of(
                    "success", false,
                    "error", e.getMessage()
                ));
                break;
            }
        }
        
        return results;
    }

    private Map<String, Object> executeScript(String scriptPath, Map<String, String> parameters) {
        try {
            List<String> command = new ArrayList<>();
            
            // Determine script execution method
            if (scriptPath.endsWith(".py")) {
                command.add("python3");
                command.add("sh_scripts/" + scriptPath);
            } else if (scriptPath.endsWith(".sh")) {
                command.add("sh");
                command.add("sh_scripts/" + scriptPath);
            } else {
                // Assume shell script without extension
                command.add("sh");
                command.add("sh_scripts/" + scriptPath);
            }
            
            // Add parameters as arguments
            for (Map.Entry<String, String> param : parameters.entrySet()) {
                if (param.getValue() != null && !param.getValue().isEmpty()) {
                    command.add(param.getValue());
                }
            }
            
            System.out.println("🚀 Executing command: " + String.join(" ", command));
            
            ProcessBuilder pb = new ProcessBuilder(command);
            pb.directory(Paths.get(".").toFile());
            pb.redirectErrorStream(true);
            
            // Set environment variables for parameters
            Map<String, String> env = pb.environment();
            for (Map.Entry<String, String> param : parameters.entrySet()) {
                env.put(param.getKey().toUpperCase(), param.getValue());
            }
            
            Process process = pb.start();
            
            // Read output
            StringBuilder output = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    output.append(line).append("\n");
                    System.out.println("📟 " + line); // Real-time logging
                }
            }
            
            int exitCode = process.waitFor();
            boolean success = exitCode == 0;
            
            System.out.println(success ? "✅ Script completed successfully" : "❌ Script failed with exit code " + exitCode);
            
            return Map.of(
                "success", success,
                "exit_code", exitCode,
                "output", output.toString().trim(),
                "script_path", scriptPath
            );
            
        } catch (Exception e) {
            System.err.println("💥 Exception executing script " + scriptPath + ": " + e.getMessage());
            e.printStackTrace();
            
            return Map.of(
                "success", false,
                "error", e.getMessage(),
                "script_path", scriptPath
            );
        }
    }
} 