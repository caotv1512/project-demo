-- ==========================================================
--  Database-per-service: MOT container Postgres, BON database logic rieng.
--  Moi service co user rieng, chi truy cap duoc DB cua minh.
--  Chay tu dong MOT LAN khi volume con rong.
-- ==========================================================

CREATE USER quickbite_user WITH PASSWORD 'quickbite_user';
CREATE DATABASE quickbite_user_db OWNER quickbite_user;
GRANT ALL PRIVILEGES ON DATABASE quickbite_user_db TO quickbite_user;

CREATE USER quickbite_restaurant WITH PASSWORD 'quickbite_restaurant';
CREATE DATABASE quickbite_restaurant_db OWNER quickbite_restaurant;
GRANT ALL PRIVILEGES ON DATABASE quickbite_restaurant_db TO quickbite_restaurant;

CREATE USER quickbite_order WITH PASSWORD 'quickbite_order';
CREATE DATABASE quickbite_order_db OWNER quickbite_order;
GRANT ALL PRIVILEGES ON DATABASE quickbite_order_db TO quickbite_order;

CREATE USER quickbite_notification WITH PASSWORD 'quickbite_notification';
CREATE DATABASE quickbite_notification_db OWNER quickbite_notification;
GRANT ALL PRIVILEGES ON DATABASE quickbite_notification_db TO quickbite_notification;
