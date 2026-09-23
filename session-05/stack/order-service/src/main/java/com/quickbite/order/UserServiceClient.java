package com.quickbite.order;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.Map;

/**
 * Goi sang user-service NHU GOI HAM JAVA THONG THUONG.
 * url dung TEN SERVICE "user-service" - DNS noi bo cua Docker phan giai thanh IP
 * tai thoi diem chay. Khong bao gio ghi cung dia chi IP o day.
 */
@FeignClient(name = "user-service", url = "${services.user.url}")
public interface UserServiceClient {

    @PostMapping("/users/{id}/wallet/deduct")
    Map<String, Object> deductWallet(@PathVariable("id") Long id, @RequestParam("amount") long amount);

    @PostMapping("/users/{id}/wallet/refund")
    Map<String, Object> refundWallet(@PathVariable("id") Long id, @RequestParam("amount") long amount);
}
