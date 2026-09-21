package com.quickbite.restaurant;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class RestaurantController {

    private final JdbcTemplate jdbc;

    public RestaurantController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @GetMapping("/info")
    public Map<String, Object> info() {
        return Map.of(
                "service", "restaurant-service",
                "javaVersion", System.getProperty("java.version"),   // se in ra 21.x
                "hostname", System.getenv().getOrDefault("HOSTNAME", "unknown"),
                "dbHost", System.getenv().getOrDefault("DB_HOST", "(chua set)")
        );
    }

    @GetMapping("/restaurants")
    public List<Map<String, Object>> findAll() {
        return jdbc.queryForList(
                "SELECT id, name, address, rating FROM restaurants ORDER BY id");
    }
}
