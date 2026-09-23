CREATE TABLE IF NOT EXISTS restaurants (
    id        BIGSERIAL    PRIMARY KEY,
    name      VARCHAR(150) NOT NULL UNIQUE,
    menu_item VARCHAR(150) NOT NULL,
    price     BIGINT       NOT NULL,
    is_open   BOOLEAN      NOT NULL DEFAULT TRUE
);
