-- Chay tu dong boi Spring Boot (spring.sql.init.mode=always) khi app khoi dong.
-- IF NOT EXISTS => chay lai bao nhieu lan cung khong loi.
CREATE TABLE IF NOT EXISTS users (
    id         BIGSERIAL    PRIMARY KEY,
    full_name  VARCHAR(100) NOT NULL,
    email      VARCHAR(150) NOT NULL UNIQUE,
    created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);
