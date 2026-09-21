-- ==========================================================
--  init-db.sql
--  Duoc PostgreSQL tu dong chay MOT LAN DUY NHAT, khi thu muc
--  du lieu (volume db-data) con RONG.
--  Da sua file nay? Phai: docker compose down -v && docker compose up -d
-- ==========================================================

CREATE USER quickbite_user WITH PASSWORD 'quickbite_user';
CREATE DATABASE quickbite_user_db OWNER quickbite_user;
GRANT ALL PRIVILEGES ON DATABASE quickbite_user_db TO quickbite_user;

-- --- Chuan bi san cho Bai tap 1 (restaurant-service, Java 21) ---
CREATE USER quickbite_restaurant WITH PASSWORD 'quickbite_restaurant';
CREATE DATABASE quickbite_restaurant_db OWNER quickbite_restaurant;
GRANT ALL PRIVILEGES ON DATABASE quickbite_restaurant_db TO quickbite_restaurant;
