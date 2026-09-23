package com.quickbite.notification;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/** notification-service: nhan va luu thong bao gui toi khach hang. */
@RestController
@RequestMapping("/notifications")
public class NotificationController {

    private final JdbcTemplate jdbc;
    public NotificationController(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    @GetMapping("/info")
    public Map<String, Object> info() {
        return Map.of("service", "notification-service",
                      "javaVersion", System.getProperty("java.version"),
                      "hostname", System.getenv().getOrDefault("HOSTNAME", "?"));
    }

    @GetMapping
    public List<Map<String, Object>> findAll() {
        return jdbc.queryForList(
            "SELECT id, user_id, message, created_at FROM notifications ORDER BY id DESC LIMIT 20");
    }

    /** BUOC 6 cua luong dat hang: gui thong bao trang thai don. */
    @PostMapping
    public Map<String, Object> send(@RequestParam Long userId, @RequestParam String message) {
        jdbc.update("INSERT INTO notifications (user_id, message) VALUES (?, ?)", userId, message);
        return Map.of("sent", true, "userId", userId, "message", message);
    }
}
