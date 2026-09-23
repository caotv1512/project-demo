package com.quickbite.order;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.Map;

@FeignClient(name = "notification-service", url = "${services.notification.url}")
public interface NotificationServiceClient {

    @PostMapping("/notifications")
    Map<String, Object> send(@RequestParam("userId") Long userId,
                             @RequestParam("message") String message);
}
