package com.quickbite.order;

import feign.FeignException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * order-service: dieu phoi toan bo luong dat hang.
 * Day la noi the hien SAGA PATTERN + GIAO DICH BU.
 */
@RestController
@RequestMapping("/orders")
public class OrderController {

    private static final Logger log = LoggerFactory.getLogger(OrderController.class);

    private final JdbcTemplate jdbc;
    private final UserServiceClient userClient;
    private final RestaurantServiceClient restaurantClient;
    private final NotificationServiceClient notificationClient;

    public OrderController(JdbcTemplate jdbc,
                           UserServiceClient userClient,
                           RestaurantServiceClient restaurantClient,
                           NotificationServiceClient notificationClient) {
        this.jdbc = jdbc;
        this.userClient = userClient;
        this.restaurantClient = restaurantClient;
        this.notificationClient = notificationClient;
    }

    @GetMapping("/info")
    public Map<String, Object> info() {
        return Map.of("service", "order-service",
                      "javaVersion", System.getProperty("java.version"),
                      "hostname", System.getenv().getOrDefault("HOSTNAME", "?"));
    }

    @GetMapping
    public List<Map<String, Object>> findAll() {
        return jdbc.queryForList(
            "SELECT id, user_id, restaurant_id, restaurant_name, menu_item, price, status, note " +
            "FROM orders ORDER BY id DESC LIMIT 20");
    }

    /**
     * Dat hang - luong 6 buoc theo slide.
     * POST /orders?userId=1&restaurantId=1
     */
    @PostMapping
    public Map<String, Object> placeOrder(@RequestParam Long userId,
                                          @RequestParam Long restaurantId) {

        // --- BUOC 2: tao don o trang thai PENDING ---
        Map<String, Object> r = restaurantClient.getRestaurant(restaurantId);
        String restaurantName = String.valueOf(r.get("name"));
        String menuItem       = String.valueOf(r.get("menu_item"));
        long   price          = ((Number) r.get("price")).longValue();

        // SNAPSHOT PATTERN: chup lai ten nha hang, ten mon, gia TAI THOI DIEM DAT.
        // Sau nay nha hang doi gia hay doi ten thi hoa don cu van dung.
        Long orderId = jdbc.queryForObject(
            "INSERT INTO orders (user_id, restaurant_id, restaurant_name, menu_item, price, status) " +
            "VALUES (?,?,?,?,?, 'PENDING') RETURNING id",
            Long.class, userId, restaurantId, restaurantName, menuItem, price);
        log.info("[BUOC 2] Tao don #{} PENDING - {} / {} / {}d", orderId, restaurantName, menuItem, price);

        // --- BUOC 3: tru tien vi (goi user-service) ---
        try {
            userClient.deductWallet(userId, price);
            log.info("[BUOC 3] Da tru {}d cua user #{}", price, userId);
        } catch (FeignException e) {
            jdbc.update("UPDATE orders SET status='CANCELLED', note=? WHERE id=?",
                        "Tru tien that bai: " + shortMsg(e), orderId);
            log.warn("[BUOC 3] THAT BAI - huy don #{}", orderId);
            return result(orderId, "CANCELLED", "Khong tru duoc tien vi: " + shortMsg(e), false);
        }

        // --- BUOC 4: bao nha hang chuan bi mon ---
        try {
            restaurantClient.acceptOrder(restaurantId);
            log.info("[BUOC 4] Nha hang {} da nhan don #{}", restaurantName, orderId);
        } catch (FeignException e) {
            // ===== GIAO DICH BU (COMPENSATING TRANSACTION) =====
            // Tien da bi tru o buoc 3 nhung nha hang tu choi o buoc 4.
            // Hai database nam o hai service khac nhau => KHONG co rollback tu dong.
            // Phai TU TAY goi sang user-service de hoan tien.
            log.warn("[BUOC 4] Nha hang TU CHOI don #{} -> chay giao dich bu (hoan tien)", orderId);
            userClient.refundWallet(userId, price);
            jdbc.update("UPDATE orders SET status='CANCELLED', note=? WHERE id=?",
                        "Nha hang tu choi - da hoan " + price + "d", orderId);
            notificationClient.send(userId, "Don #" + orderId + " bi huy. Da hoan " + price + "d vao vi.");
            return result(orderId, "CANCELLED",
                          "Nha hang tu choi. Da HOAN LAI " + price + "d vao vi (giao dich bu).", true);
        }

        // --- BUOC 5 + 6: hoan tat, gui thong bao ---
        jdbc.update("UPDATE orders SET status='CONFIRMED', note='Da xac nhan' WHERE id=?", orderId);
        notificationClient.send(userId, "Don #" + orderId + " da duoc xac nhan. Tai xe dang den lay mon.");
        log.info("[BUOC 5-6] Don #{} CONFIRMED, da gui thong bao", orderId);

        return result(orderId, "CONFIRMED", "Dat hang thanh cong", false);
    }

    private Map<String, Object> result(Long id, String status, String msg, boolean refunded) {
        return Map.of("orderId", id, "status", status, "message", msg, "refunded", refunded);
    }

    private String shortMsg(FeignException e) {
        String body = e.contentUTF8();
        return body == null || body.isBlank() ? ("HTTP " + e.status()) : body;
    }
}
