package com.youtube.ai.scheduler;

import com.youtube.ai.scheduler.model.ActionCatalog;
import com.youtube.ai.scheduler.model.ActionCatalog.ActionDefinition;
import com.youtube.ai.scheduler.model.ActionCatalog.ActionCategory;
import com.youtube.ai.scheduler.model.Job;
import com.youtube.ai.scheduler.service.JobService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.HashMap;

@Controller
@RequestMapping("/actions")
public class ActionController {

    private final JobService jobService;

    public ActionController(JobService jobService) {
        this.jobService = jobService;
    }

    @GetMapping
    public String listActions(Model model) {
        List<ActionCategory> categories = ActionCatalog.getAllCategories();
        Map<ActionCategory, List<ActionDefinition>> actionsByCategory = new HashMap<>();
        
        for (ActionCategory category : categories) {
            actionsByCategory.put(category, ActionCatalog.getActionsByCategory(category));
        }
        
        model.addAttribute("categories", categories);
        model.addAttribute("actionsByCategory", actionsByCategory);
        return "actions";
    }

    @GetMapping("/run/{actionId}")
    public String showActionForm(@PathVariable String actionId, Model model) {
        ActionDefinition action = ActionCatalog.getActionById(actionId)
                .orElseThrow(() -> new RuntimeException("Action not found: " + actionId));
        
        model.addAttribute("action", action);
        model.addAttribute("channels", jobService.listChannels());
        return "action-form";
    }

    @PostMapping("/execute/{actionId}")
    public String executeAction(@PathVariable String actionId, 
                               @RequestParam Map<String, String> parameters,
                               @RequestParam(value = "channel", required = false) String channel) {
        
        ActionDefinition action = ActionCatalog.getActionById(actionId)
                .orElseThrow(() -> new RuntimeException("Action not found: " + actionId));
        
        // Create a temporary job to execute the action
        Job tempJob = new Job();
        tempJob.setName("Action: " + action.getDisplayName());
        tempJob.setActive(false);
        
        // Set primary script
        if (!action.getScriptPaths().isEmpty()) {
            tempJob.setScriptPath(action.getScriptPaths().get(0));
        }
        
        // Set additional scripts
        if (action.getScriptPaths().size() > 1) {
            tempJob.setNextScript1(action.getScriptPaths().get(1));
        }
        if (action.getScriptPaths().size() > 2) {
            tempJob.setNextScript2(action.getScriptPaths().get(2));
        }
        
        // Build script parameters from form data
        StringBuilder scriptParams = new StringBuilder();
        for (Map.Entry<String, String> entry : parameters.entrySet()) {
            if (entry.getValue() != null && !entry.getValue().trim().isEmpty()) {
                scriptParams.append(entry.getKey()).append("=").append(entry.getValue()).append(" ");
            }
        }
        
        tempJob.setScriptParams(scriptParams.toString().trim());
        tempJob.setChannel(channel);
        
        // Save and run the job
        Job savedJob = jobService.save(tempJob);
        jobService.runNow(savedJob.getId());
        
        return "redirect:/jobs/logs/" + savedJob.getId();
    }

    @GetMapping("/quick")
    public String quickActions(Model model) {
        // Most commonly used actions for quick access
        List<ActionDefinition> quickActions = List.of(
            ActionCatalog.getActionById("generate_lofi_video").orElse(null),
            ActionCatalog.getActionById("post_zodiac_tweet").orElse(null),
            ActionCatalog.getActionById("post_general_tweet").orElse(null),
            ActionCatalog.getActionById("start_remote_stream").orElse(null)
        );
        
        model.addAttribute("quickActions", quickActions);
        return "quick-actions";
    }
} 