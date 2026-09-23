CREATE TABLE IF NOT EXISTS orders (
    id              BIGSERIAL    PRIMARY KEY,
    user_id         BIGINT       NOT NULL,
    restaurant_id   BIGINT       NOT NULL,
    -- 4 cot duoi la SNAPSHOT: chup lai du lieu tai thoi diem dat hang,
    -- KHONG tham chieu dong sang restaurant-service.
    restaurant_name VARCHAR(150) NOT NULL,
    menu_item       VARCHAR(150) NOT NULL,
    price           BIGINT       NOT NULL,
    status          VARCHAR(20)  NOT NULL,
    note            VARCHAR(300),
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);
