package com.quickbite.restaurant;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;

/** restaurant-service: quan ly nha hang va thuc don. */
@RestController
@RequestMapping("/restaurants")
public class RestaurantController {

    private static final Logger log = LoggerFactory.getLogger(RestaurantController.class);

    private final JdbcTemplate jdbc;
    public RestaurantController(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    @GetMapping("/info")
    public Map<String, Object> info() {
        return Map.of("service", "restaurant-service",
                      "javaVersion", System.getProperty("java.version"),
                      "hostname", System.getenv().getOrDefault("HOSTNAME", "?"));
    }

    @GetMapping
    public List<Map<String, Object>> findAll() {
        return jdbc.queryForList(
            "SELECT id, name, menu_item, price, is_open FROM restaurants ORDER BY id");
    }

    @GetMapping("/{id}")
    public Map<String, Object> findOne(@PathVariable Long id) {
        var rows = jdbc.queryForList(
            "SELECT id, name, menu_item, price, is_open FROM restaurants WHERE id = ?", id);
        if (rows.isEmpty()) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Khong co nha hang id=" + id);
        return rows.get(0);
    }

    /** order-service goi sang day o BUOC 4: bao nha hang chuan bi mon. */
    @PostMapping("/{id}/accept-order")
    public Map<String, Object> acceptOrder(@PathVariable Long id) {
        var r = findOne(id);
        boolean open = Boolean.TRUE.equals(r.get("is_open"));
        if (!open) {
            log.warn("[NHA HANG] {} DONG CUA - tu choi don", r.get("name"));
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                "Nha hang '" + r.get("name") + "' dang DONG CUA, tu choi don");
        }
        log.info("[NHA HANG] {} da nhan don - mon {}", r.get("name"), r.get("menu_item"));
        return Map.of("restaurantId", id, "name", r.get("name"), "accepted", true);
    }

    /** Dung de DEMO Saga: bat/tat nha hang nhan don. */
    @PostMapping("/{id}/toggle-open")
    public Map<String, Object> toggleOpen(@PathVariable Long id, @RequestParam boolean open) {
        jdbc.update("UPDATE restaurants SET is_open = ? WHERE id = ?", open, id);
        log.info("[NHA HANG] Doi trang thai nha hang #{} thanh is_open={}", id, open);
        return Map.of("restaurantId", id, "isOpen", open);
    }
}
