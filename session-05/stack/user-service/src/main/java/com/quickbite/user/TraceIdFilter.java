package com.quickbite.user;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

/**
 * Doc header X-Trace-Id cua moi request. Khong co thi tu sinh mot ma moi.
 * Dat vao MDC duoi khoa "trace.id" -> EcsEncoder in ra thanh field trace.id.
 * Nho co day ma Kibana loc duoc toan bo log cua CUNG MOT request.
 */
@Component
public class TraceIdFilter extends OncePerRequestFilter {

    public static final String HEADER  = "X-Trace-Id";
    public static final String MDC_KEY = "trace.id";

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String traceId = request.getHeader(HEADER);
        if (traceId == null || traceId.isBlank()) {
            traceId = "auto-" + UUID.randomUUID().toString().substring(0, 8);
        }
        MDC.put(MDC_KEY, traceId);
        response.setHeader(HEADER, traceId);
        try {
            chain.doFilter(request, response);
        } finally {
            MDC.remove(MDC_KEY);   // thread duoc tai su dung -> phai don MDC
        }
    }
}
