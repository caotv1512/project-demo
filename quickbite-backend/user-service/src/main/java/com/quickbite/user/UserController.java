package com.quickbite.user;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/**
 * Cac endpoint dung de DEMO trong buoi hoc.
 * Muc dich: chung minh container app that su ket noi duoc toi container database
 * thong qua ten service (Service Discovery), khong can biet dia chi IP.
 */
@RestController
@RequestMapping("/api")
public class UserController {

    private final JdbcTemplate jdbc;

    public UserController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** Thong tin nhan dang service - de phan biet khi chay nhieu container. */
    @GetMapping("/info")
    public Map<String, Object> info() {
        return Map.of(
                "service", "user-service",
                "javaVersion", System.getProperty("java.version"),
                "javaVendor", System.getProperty("java.vendor"),
                "hostname", System.getenv().getOrDefault("HOSTNAME", "unknown"),
                "dbHost", System.getenv().getOrDefault("DB_HOST", "(chua set)"),
                "serverPort", System.getenv().getOrDefault("SERVER_PORT", "(chua set)")
        );
    }

    /** Doc du lieu that tu PostgreSQL - bang chung ket noi DB thanh cong. */
    @GetMapping("/users")
    public List<Map<String, Object>> findAll() {
        return jdbc.queryForList(
                "SELECT id, full_name, email, created_at FROM users ORDER BY id");
    }

    /** Tra ve thong tin phien ban va ten database dang ket noi. */
    @GetMapping("/db-check")
    public Map<String, Object> dbCheck() {
        return Map.of(
                "currentDatabase", jdbc.queryForObject("SELECT current_database()", String.class),
                "currentUser",     jdbc.queryForObject("SELECT current_user", String.class),
                "serverAddress",   String.valueOf(jdbc.queryForObject(
                                      "SELECT COALESCE(inet_server_addr()::text, 'local')", String.class)),
                "postgresVersion", jdbc.queryForObject("SHOW server_version", String.class),
                "totalUsers",      jdbc.queryForObject("SELECT COUNT(*) FROM users", Integer.class)
        );
    }
}
