package com.quickbite.order;

import feign.RequestInterceptor;
import org.slf4j.MDC;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Chuyen tiep trace.id sang cac service khac.
 * Khong co doan nay thi moi service tu sinh mot trace.id rieng
 * va Kibana khong noi duoc chuoi log thanh mot hanh trinh.
 */
@Configuration
public class FeignTraceConfig {

    @Bean
    public RequestInterceptor traceIdForwarder() {
        return template -> {
            String traceId = MDC.get(TraceIdFilter.MDC_KEY);
            if (traceId != null) {
                template.header(TraceIdFilter.HEADER, traceId);
            }
        };
    }
}
