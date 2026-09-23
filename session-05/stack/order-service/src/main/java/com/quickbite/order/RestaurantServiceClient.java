package com.quickbite.order;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;

import java.util.Map;

@FeignClient(name = "restaurant-service", url = "${services.restaurant.url}")
public interface RestaurantServiceClient {

    @GetMapping("/restaurants/{id}")
    Map<String, Object> getRestaurant(@PathVariable("id") Long id);

    @PostMapping("/restaurants/{id}/accept-order")
    Map<String, Object> acceptOrder(@PathVariable("id") Long id);
}
