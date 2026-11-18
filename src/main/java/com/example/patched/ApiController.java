package com.example.patched;

import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class ApiController {

    @GetMapping("/hello")
    public Map<String, String> hello() {
        return Map.of("message", "Hello from Spring Boot on a patched Corretto 21 runtime.");
    }

    /**
     * Reports the JVM this process is actually running on, so anyone can
     * confirm a deployment picked up the patched Corretto build.
     * A patched deployment reports java.version 21.0.13.1 or later
     * and implementor version Corretto-21.0.13.1.2 or later.
     */
    @GetMapping("/runtime")
    public Map<String, String> runtime() {
        Map<String, String> info = new LinkedHashMap<>();
        info.put("java.version", System.getProperty("java.version"));
        info.put("java.version.date", System.getProperty("java.version.date", ""));
        info.put("java.vendor", System.getProperty("java.vendor"));
        info.put("java.vm.name", System.getProperty("java.vm.name"));
        info.put("java.vm.version", System.getProperty("java.vm.version"));
        info.put("os.arch", System.getProperty("os.arch"));
        return info;
    }
}
