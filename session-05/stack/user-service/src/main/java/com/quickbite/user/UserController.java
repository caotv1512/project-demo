package com.quickbite.user;

import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

/** user-service: quan ly tai khoan va VI TIEN. */
@RestController
@RequestMapping("/users")
public class UserController {

    private final JdbcTemplate jdbc;
    public UserController(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    @GetMapping("/info")
    public Map<String, Object> info() {
        return Map.of("service", "user-service",
                      "javaVersion", System.getProperty("java.version"),
                      "hostname", System.getenv().getOrDefault("HOSTNAME", "?"));
    }

    @GetMapping
    public List<Map<String, Object>> findAll() {
        return jdbc.queryForList("SELECT id, full_name, email, wallet_balance FROM users ORDER BY id");
    }

    @GetMapping("/{id}")
    public Map<String, Object> findOne(@PathVariable Long id) {
        var rows = jdbc.queryForList(
            "SELECT id, full_name, email, wallet_balance FROM users WHERE id = ?", id);
        if (rows.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Khong co user id=" + id);
        return rows.get(0);
    }

    /** Tru tien vi. order-service goi sang day o BUOC 3 cua luong dat hang. */
    @PostMapping("/{id}/wallet/deduct")
    public Map<String, Object> deduct(@PathVariable Long id, @RequestParam long amount) {
        Long balance = jdbc.queryForObject(
            "SELECT wallet_balance FROM users WHERE id = ?", Long.class, id);
        if (balance == null) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Khong co user id=" + id);
        if (balance < amount)
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                "So du khong du: co " + balance + ", can " + amount);
        jdbc.update("UPDATE users SET wallet_balance = wallet_balance - ? WHERE id = ?", amount, id);
        return Map.of("userId", id, "deducted", amount, "newBalance", balance - amount);
    }

    /** Hoan tien - GIAO DICH BU (compensating transaction) cua Saga Pattern. */
    @PostMapping("/{id}/wallet/refund")
    public Map<String, Object> refund(@PathVariable Long id, @RequestParam long amount) {
        jdbc.update("UPDATE users SET wallet_balance = wallet_balance + ? WHERE id = ?", amount, id);
        Long balance = jdbc.queryForObject(
            "SELECT wallet_balance FROM users WHERE id = ?", Long.class, id);
        return Map.of("userId", id, "refunded", amount, "newBalance", balance);
    }
}
