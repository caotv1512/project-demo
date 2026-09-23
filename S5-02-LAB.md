# LAB SESSION 05 — BẢNG LỆNH THỰC HÀNH
# Multi-container System & API Gateway · Dự án QuickBite

> **Cách dùng:** làm tuần tự BÀI 1 → BÀI 7. Mỗi bài: **lệnh cần gõ** → **kết quả phải thấy** → **thí nghiệm gây lỗi** để hiểu vì sao.

---

# A · CHUẨN BỊ

## A1. Session 05 chạy SONG SONG với Session 04 — đừng nhầm lẫn

Hai buổi học là **hai hệ thống hoàn toàn riêng biệt**, chạy được cùng lúc trên một máy:

| | Session 04 | Session 05 |
|---|---|---|
| Thư mục | `quickbite-demo/quickbite-db`, `quickbite-backend` | `quickbite-demo/session-05` |
| Tên container | `quickbite-db`, `quickbite-user` … | `quickbite5-db`, `quickbite5-user` … |
| Mạng ảo | `quickbite-net` | `quickbite5-net` |
| Cổng Postgres | `5432` | `5433` |
| Cổng vào hệ thống | `8081` (user-service) | `8000` (gateway) |

> ⚠️ **Đây là nguồn nhầm lẫn số 1.** Nếu gõ `curl localhost:8081` mà thấy có dữ liệu, đó là **Session 04** đang trả lời, không phải Session 05. Nhìn tiền tố tên container: `quickbite5-` là buổi này.

**Xem cả hai hệ cùng lúc:**
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**Nếu muốn tắt Session 04 cho gọn:**
```bash
cd ~/Downloads/quickbite-demo && ./stop-all.sh
```

## A2. Đường dẫn và quy tắc thư mục

Tài liệu giả sử project ở `~/Downloads/quickbite-demo/session-05`. Máy bạn khác thì thay đoạn đó.

```
session-05/                    ← THƯ MỤC GỐC: chỉ chạy được SCRIPT (.sh)
│                                KHÔNG có docker-compose.yml ở đây
├── build-all.sh  start-all.sh  stop-all.sh  check.sh  reset-demo.sh
│
├── quickbite5-db/             ← có docker-compose.yml  (Database, bật TRƯỚC)
│   ├── docker-compose.yml
│   └── init-db.sql
│
└── stack/                     ← có docker-compose.yml  (4 service + gateway)
    ├── docker-compose.yml
    ├── .env  .env.example  .gitignore
    ├── api-gateway/           Spring Cloud Gateway · cổng 8080
    ├── user-service/          Java 17 · cổng 8081 · ví tiền
    ├── restaurant-service/    Java 17 · cổng 8082 · thực đơn
    ├── order-service/         Java 17 · cổng 8083 · Feign + Saga
    └── notification-service/  Java 17 · cổng 8084 · thông báo
```

| Đứng ở | Chạy được | KHÔNG chạy được |
|---|---|---|
| `session-05/` | `./check.sh` `./start-all.sh` … | `docker compose …` |
| `session-05/stack/` | `docker compose …` | `./check.sh` |

> 💡 Chạy script từ bất cứ đâu bằng đường dẫn đầy đủ:
> ```bash
> ~/Downloads/quickbite-demo/session-05/check.sh
> ```

## A3. Cổng cần trống: `5433`, `8000`

```bash
lsof -i :5433 -i :8000
```
```powershell
netstat -ano | findstr ":5433 :8000"
```

**Không có kết quả = tốt.**

> 💡 **Vì sao gateway dùng cổng 8000 mà không phải 8080?**
> Trên máy soạn tài liệu này, cổng 8080 đã bị ứng dụng khác chiếm. File `.env` khai báo `GATEWAY_HOST_PORT=8000`, ánh xạ thành `"8000:8080"` — bên ngoài gõ `8000`, bên trong container vẫn là `8080`. Máy bạn trống cổng 8080 thì đổi biến đó về `8080` cũng được.

## A4. Lệnh theo hệ điều hành

Mọi lệnh `docker` giống nhau trên cả 3 hệ. Chỉ lệnh của OS mới khác:

| Việc | macOS · Ubuntu · Git Bash | Windows PowerShell |
|---|---|---|
| Gọi API | `curl -s <url>` | `curl.exe -s <url>` |
| Gửi POST | `curl -X POST "<url>"` | `curl.exe -X POST "<url>"` |
| Lọc chữ | `… \| grep x` | `… \| Select-String x` |
| Xem file ẩn | `ls -la` | `ls -Force` |
| Tìm cổng bận | `lsof -i :8000` | `netstat -ano \| findstr :8000` |
| Chạy script `.sh` | `./x.sh` | dùng **Git Bash** |

> 💡 **Không có curl cũng được** — với các lệnh `GET`, mở trình duyệt và dán địa chỉ vào. Riêng `POST` thì cần curl hoặc Postman.

---

# B · KHỞI ĐỘNG NHANH

```bash
cd ~/Downloads/quickbite-demo/session-05
```
```bash
./start-all.sh
```
```bash
./check.sh
```
**Phải thấy:** `KET QUA: 22 pass / 0 fail`

Thử ngay:
```bash
curl http://localhost:8000/api/v1/users
```

---

# BÀI 1 — DATABASE-PER-SERVICE

**Mục tiêu:** thấy được 4 database logic trong **một** container Postgres, và sự cô lập giữa chúng.

```bash
cd ~/Downloads/quickbite-demo/session-05/quickbite5-db
```

### 1.1 · Xem script khởi tạo

```bash
cat init-db.sql
```
**Phải thấy:** 4 cặp `CREATE USER` + `CREATE DATABASE`

### 1.2 · Bật database

```bash
docker compose up -d
```
```bash
docker exec quickbite5-db pg_isready -U postgres
```
**Phải thấy:** `accepting connections`

### 1.3 · Chứng minh có đúng 4 database

```bash
docker exec quickbite5-db psql -U postgres -c "\l"
```
**Phải thấy:** `quickbite_user_db`, `quickbite_restaurant_db`, `quickbite_order_db`, `quickbite_notification_db`

```bash
docker exec quickbite5-db psql -U postgres -c "\du"
```
**Phải thấy:** 4 user tương ứng

> **Vì sao một container mà nhiều database:** tiết kiệm tài nguyên (1 tiến trình Postgres thay vì 4), nhưng mỗi service có user riêng nên vẫn **cô lập** được dữ liệu. Đây là mô hình dùng ở môi trường dev.

---

## 🧪 Thí nghiệm 1 — Service này có đọc được database của service kia không?

```bash
docker exec quickbite5-db psql -U quickbite_user -d quickbite_order_db -c "SELECT 1;"
```

**Sẽ thấy:**
```
FATAL:  permission denied for database "quickbite_order_db"
```

**Vì sao:** `quickbite_user` chỉ sở hữu `quickbite_user_db`. Đây chính là **cô lập dữ liệu** — dù nằm chung một container Postgres, service này **không** chạm được vào dữ liệu của service kia.

Đăng nhập đúng database của mình thì được:
```bash
docker exec quickbite5-db psql -U quickbite_user -d quickbite_user_db -c "SELECT COUNT(*) FROM users;"
```

---

# BÀI 2 — CHẠY 4 SERVICE + GATEWAY

**Mục tiêu:** dựng cả cụm và hiểu file `.env` tiền tố hoá.

```bash
cd ~/Downloads/quickbite-demo/session-05/stack
```

### 2.1 · Đọc file `.env`

```bash
cat .env
```

**Chú ý cách đặt tên biến:**
```dotenv
USER_DB_NAME=quickbite_user_db
RESTAURANT_DB_NAME=quickbite_restaurant_db
ORDER_DB_NAME=quickbite_order_db
NOTIFICATION_DB_NAME=quickbite_notification_db
```

> **Vì sao phải có tiền tố:** cả 4 service đều cần một biến tên "database name". Nếu để chung là `DB_NAME`, chúng **ghi đè lẫn nhau**. Tiền tố là cách rẻ nhất giữ không gian tên tách biệt mà vẫn chỉ quản lý một file.

### 2.2 · Xem Compose sau khi thay biến

```bash
docker compose config | grep -E "SPRING_DATASOURCE_URL|container_name"
```
**Phải thấy:** mỗi service trỏ vào một database khác nhau

### 2.3 · Build JAR và khởi chạy

```bash
cd ~/Downloads/quickbite-demo/session-05 && ./build-all.sh
```
> Script chạy Gradle **trong Docker** nên không cần cài JDK. Lần đầu mất vài phút, các lần sau rất nhanh nhờ cache.

```bash
cd ~/Downloads/quickbite-demo/session-05/stack && docker compose up -d --build
```

### 2.4 · Xem kết quả

```bash
docker compose ps
```
**Phải thấy:** 5 container `Up`

### 2.5 · Đợi hệ thống sẵn sàng rồi mới gọi API

```bash
until curl -fsS http://localhost:8000/actuator/health >/dev/null 2>&1; do sleep 2; done && echo "San sang!"
```

> ⚠️ **Trạng thái `Up` chưa có nghĩa là gọi được API.** `docker compose up -d` trả về ngay, nhưng Spring Boot cần thêm ~15 giây mới nghe được cổng. Gọi sớm hơn sẽ nhận `Connection refused` và dễ tưởng nhầm là hỏng.

---

# BÀI 3 — INTERNAL PORTS (BẢO MẬT CỔNG MẠNG)

**Mục tiêu:** hiểu vì sao chỉ gateway được mở cổng ra ngoài.

### 3.1 · Nhìn cột PORTS — bài học nằm ở đây

```bash
docker ps --filter name=quickbite5 --format "table {{.Names}}\t{{.Ports}}"
```

**Phải thấy:**
```
quickbite5-gateway        0.0.0.0:8000->8080/tcp     ← có mũi tên = mở ra máy thật
quickbite5-user           8081/tcp                   ← không mũi tên = chỉ nội bộ
quickbite5-restaurant     8082/tcp
quickbite5-order          8083/tcp
quickbite5-notification   8084/tcp
```

> **Cách đọc:** có dạng `0.0.0.0:X->Y` nghĩa là **mở ra máy thật**. Chỉ có `Y/tcp` nghĩa là cổng **chỉ tồn tại bên trong mạng ảo**.

### 3.2 · Xem file compose

```bash
grep -A3 -E "api-gateway:|user-service:" ~/Downloads/quickbite-demo/session-05/stack/docker-compose.yml
```

Chỉ `api-gateway` có khối `ports:`. Các service khác **không có**.

---

## 🧪 Thí nghiệm 2 — Gọi thẳng vào service nội bộ

> ⚠️ **Tắt Session 04 trước**, nếu không container của buổi 4 đang giữ cổng 8081 sẽ trả lời thay và kết quả sai:
> ```bash
> cd ~/Downloads/quickbite-demo && ./stop-all.sh
> ```

```bash
curl -m 3 http://localhost:8082/restaurants
```
**Sẽ thấy:** `Connection refused` ❌

```bash
curl -m 3 http://localhost:8083/orders
```
**Sẽ thấy:** `Connection refused` ❌

Nhưng qua gateway thì được:
```bash
curl http://localhost:8000/api/v1/restaurants
```
**Phải thấy:** danh sách nhà hàng ✅

**Vì sao:** service **vẫn đang chạy và vẫn nghe cổng 8082** — chỉ là không có cửa ra máy thật. Chứng minh bằng cách gọi từ **bên trong** mạng ảo:

```bash
docker exec quickbite5-order wget -qO- http://restaurant-service:8082/restaurants
```
**Phải thấy:** có dữ liệu → service sống khoẻ, chỉ là bị giấu khỏi bên ngoài.

> 💡 **Đây chính là bài `EXPOSE` vs `-p` của Session 04**, nay dùng cho mục đích **bảo mật**: thu hẹp bề mặt tấn công, ép mọi request đi qua gateway.

---

# BÀI 4 — SPRING CLOUD GATEWAY

**Mục tiêu:** hiểu Predicate, Filter và `StripPrefix`.

### 4.1 · Đọc cấu hình định tuyến

```bash
cat ~/Downloads/quickbite-demo/session-05/stack/api-gateway/src/main/resources/application.yml
```

```yaml
routes:
  - id: user_route
    uri: http://user-service:8081      # đích đến — dùng TÊN SERVICE
    predicates:
      - Path=/api/v1/users/**          # điều kiện khớp
    filters:
      - StripPrefix=2                  # bỏ 2 đoạn đầu: /api/v1
```

### 4.2 · Xem bảng định tuyến đang chạy

```bash
curl http://localhost:8000/actuator/gateway/routes
```

**Phải thấy:** 4 route — `user_route`, `restaurant_route`, `order_route`, `notification_route`

> **Đây là lệnh debug quan trọng nhất của gateway.** Khi bị 404, gõ nó trước tiên để xem route có được nạp không và path khớp là gì.

### 4.3 · Thử cả 4 route

```bash
curl http://localhost:8000/api/v1/users
```
```bash
curl http://localhost:8000/api/v1/restaurants
```
```bash
curl http://localhost:8000/api/v1/orders
```
```bash
curl http://localhost:8000/api/v1/notifications
```
**Phải thấy:** cả 4 đều trả JSON

### 4.4 · Hiểu `StripPrefix=2`

```
Client gọi:       /api/v1/users/1
                   └┬─┘ └┬┘ └──┬──┘
                    1    2   giữ lại
StripPrefix=2  ──►  /users/1
Gateway gửi tới:  http://user-service:8081/users/1
```

```bash
curl http://localhost:8000/api/v1/users/1
```
**Phải thấy:** thông tin user #1 kèm `wallet_balance`

---

## 🧪 Thí nghiệm 3 — Path không khớp Predicate

```bash
curl -i -m 5 http://localhost:8000/api/v1/khong-ton-tai
```
**Sẽ thấy:** `HTTP/1.1 404 Not Found`

```bash
curl -i -m 5 http://localhost:8000/users
```
**Sẽ thấy:** `HTTP/1.1 404 Not Found`

**Vì sao:** không có route nào có Predicate khớp. `/users` thiếu tiền tố `/api/v1` nên không khớp `Path=/api/v1/users/**`.

> 💡 **Quy tắc chẩn đoán 404 ở gateway:**
> 1. Route có được nạp không? → `curl http://localhost:8000/actuator/gateway/routes`
> 2. Path gọi có khớp Predicate không? → so từng ký tự
> 3. `StripPrefix` đúng số chưa? → đếm số đoạn cần bỏ
>
> Đặt `StripPrefix=1` thay vì `2` sẽ gửi `/v1/users/1` xuống service → service trả 404. Lỗi này rất hay gặp.

---

# BÀI 5 — OPENFEIGN: GỌI SERVICE KHÁC

**Mục tiêu:** hiểu cách `order-service` gọi sang 3 service còn lại.

### 5.1 · Đọc Feign Client

```bash
cat ~/Downloads/quickbite-demo/session-05/stack/order-service/src/main/java/com/quickbite/order/RestaurantServiceClient.java
```

```java
@FeignClient(name = "restaurant-service", url = "${services.restaurant.url}")
public interface RestaurantServiceClient {
    @GetMapping("/restaurants/{id}")
    Map<String, Object> getRestaurant(@PathVariable("id") Long id);
}
```

> **Ba điều bắt buộc:**
> 1. `@EnableFeignClients` trên lớp Application — thiếu là lỗi `NoSuchBeanDefinition`
> 2. Dependency `spring-cloud-starter-openfeign` **và** BOM `spring-cloud-dependencies`
> 3. Host trong `url` phải là **tên service** khớp `docker-compose.yml`

### 5.2 · Xem URL thật được truyền vào

```bash
docker exec quickbite5-order env | grep SERVICE_URL
```
**Phải thấy:**
```
USER_SERVICE_URL=http://user-service:8081
RESTAURANT_SERVICE_URL=http://restaurant-service:8082
NOTIFICATION_SERVICE_URL=http://notification-service:8084
```

> Toàn là **tên service**, không có một địa chỉ IP nào. DNS nội bộ của Docker phân giải lúc chạy.

### 5.3 · Kiểm chứng DNS hoạt động

```bash
docker exec quickbite5-order ping -c 2 restaurant-service
```
**Phải thấy:** `PING restaurant-service (172.x.x.x)` và có trả lời

---

## 🧪 Thí nghiệm 4 — Feign gọi sai tên service

```bash
cd ~/Downloads/quickbite-demo/session-05/stack
```
```bash
cp docker-compose.yml docker-compose.yml.backup
```
```bash
sed -i '' 's|RESTAURANT_SERVICE_URL=http://restaurant-service:8082|RESTAURANT_SERVICE_URL=http://restaurant-svc:8082|' docker-compose.yml
```
```bash
docker compose up -d order-service && sleep 16
```
```bash
curl -m 10 -X POST "http://localhost:8000/api/v1/orders?userId=1&restaurantId=1"
```
**Sẽ thấy:** `"status":500,"error":"Internal Server Error"`

```bash
docker logs quickbite5-order 2>&1 | grep UnknownHost | tail -1
```
**Sẽ thấy:**
```
java.net.UnknownHostException: restaurant-svc
```

**Vì sao:** DNS của Docker chỉ biết những tên **được khai báo làm tên service** trong `docker-compose.yml`. `restaurant-svc` không tồn tại.

**Khôi phục:**
```bash
cp docker-compose.yml.backup docker-compose.yml && rm docker-compose.yml.backup
```
```bash
docker compose up -d order-service && sleep 16
```
```bash
curl -X POST "http://localhost:8000/api/v1/orders?userId=1&restaurantId=1"
```
**Phải thấy:** `"status":"CONFIRMED"` — đặt hàng trở lại bình thường

> ⚠️ **Đừng bỏ `sleep 16`.** Lệnh `docker compose up -d` trả về **ngay lập tức**, nhưng Spring Boot cần khoảng 15 giây mới nghe được cổng. Gọi API sớm hơn sẽ nhận `500` và tưởng nhầm là chưa sửa xong. Đây là lỗi rất hay gặp khi làm lab.

---

# BÀI 6 — LUỒNG ĐẶT HÀNG 6 BƯỚC

**Mục tiêu:** thấy một request kéo theo 4 service làm việc.

### 6.1 · Xem trạng thái ban đầu

```bash
curl http://localhost:8000/api/v1/users/1
```
**Phải thấy:** `"wallet_balance":500000`

```bash
curl http://localhost:8000/api/v1/restaurants/1
```
**Phải thấy:** `Pho Thin` · `"price":75000` · `"is_open":true`

### 6.2 · Đặt hàng

```bash
curl -X POST "http://localhost:8000/api/v1/orders?userId=1&restaurantId=1"
```
**Phải thấy:** `{"status":"CONFIRMED","message":"Dat hang thanh cong",...}`

### 6.3 · Xem log 6 bước

```bash
docker logs quickbite5-order 2>&1 | grep BUOC
```
**Phải thấy:**
```
[BUOC 2] Tao don #1 PENDING - Pho Thin / Pho bo tai lan / 75000d
[BUOC 3] Da tru 75000d cua user #1
[BUOC 4] Nha hang Pho Thin da nhan don #1
[BUOC 5-6] Don #1 CONFIRMED, da gui thong bao
```

### 6.4 · Kiểm chứng kết quả ở từng service

```bash
curl http://localhost:8000/api/v1/users/1
```
**Phải thấy:** `500000 - 75000 = 425000`

```bash
curl http://localhost:8000/api/v1/notifications
```
**Phải thấy:** thông báo "Don #1 da duoc xac nhan"

```bash
curl http://localhost:8000/api/v1/orders
```
**Phải thấy:** đơn `#1` trạng thái `CONFIRMED`

> **Điểm cần chốt:** một lệnh `curl` duy nhất đã làm **bốn service** cùng làm việc và ghi vào **ba database khác nhau**.

---

## 🧪 Thí nghiệm 5 — Snapshot Pattern giữ đúng lịch sử

Nhà hàng đổi giá và đổi tên:

```bash
docker exec quickbite5-db psql -U quickbite_restaurant -d quickbite_restaurant_db \
  -c "UPDATE restaurants SET price=99000, name='Pho Thin (DA DOI TEN)' WHERE id=1;"
```

```bash
curl http://localhost:8000/api/v1/restaurants/1
```
**Phải thấy:** tên mới, giá `99000`

```bash
curl http://localhost:8000/api/v1/orders
```
**Phải thấy:** hoá đơn cũ **vẫn là `Pho Thin` và `75000`**

**Vì sao:** bảng `orders` lưu **bản sao tĩnh** của tên nhà hàng, tên món và giá tại thời điểm đặt — không tham chiếu động sang `restaurant-service`. Nhờ vậy hoá đơn cũ không bao giờ bị sai lệch.

**Khôi phục:**
```bash
docker exec quickbite5-db psql -U quickbite_restaurant -d quickbite_restaurant_db \
  -c "UPDATE restaurants SET price=75000, name='Pho Thin' WHERE id=1;"
```

---

## 🧪 Thí nghiệm 6 — SAGA PATTERN: giao dịch bù

> Đây là thí nghiệm quan trọng nhất của buổi học.

**Bước 1 — cho nhà hàng #2 đóng cửa:**
```bash
curl -X POST "http://localhost:8000/api/v1/restaurants/2/toggle-open?open=false"
```

**Bước 2 — ghi lại số dư ví:**
```bash
curl http://localhost:8000/api/v1/users/1
```
**Ghi lại con số `wallet_balance`.**

**Bước 3 — đặt hàng ở nhà hàng đang đóng cửa (món 60.000đ):**
```bash
curl -X POST "http://localhost:8000/api/v1/orders?userId=1&restaurantId=2"
```
**Sẽ thấy:**
```json
{"status":"CANCELLED","refunded":true,
 "message":"Nha hang tu choi. Da HOAN LAI 60000d vao vi (giao dich bu)."}
```

**Bước 4 — kiểm tra lại số dư:**
```bash
curl http://localhost:8000/api/v1/users/1
```
**Phải thấy:** số dư **y hệt bước 2** — tiền đã được hoàn lại đầy đủ.

**Bước 5 — xem log giao dịch bù:**
```bash
docker logs quickbite5-order 2>&1 | grep BUOC | tail -3
```
**Phải thấy:**
```
[BUOC 3] Da tru 60000d cua user #1
[BUOC 4] Nha hang TU CHOI don #2 -> chay giao dich bu (hoan tien)
```

**Bước 6 — xem đơn hàng:**
```bash
curl http://localhost:8000/api/v1/orders
```
**Phải thấy:** đơn `CANCELLED` với ghi chú `Nha hang tu choi - da hoan 60000d`

### Vì sao phải làm thủ công như vậy?

Tiền nằm ở `quickbite_user_db`, đơn hàng nằm ở `quickbite_order_db`. **Hai database khác nhau** → không có `ROLLBACK` nào bao trùm được cả hai. Lập trình viên phải **tự tay viết mã hoàn tác**:

```java
try {
    restaurantClient.acceptOrder(restaurantId);       // bước 4
} catch (FeignException e) {
    userClient.refundWallet(userId, price);           // ← GIAO DỊCH BÙ
    jdbc.update("UPDATE orders SET status='CANCELLED' WHERE id=?", orderId);
}
```

> ⚠️ **Ba điều phải hiểu:**
> 1. Có một **khoảnh khắc** tiền đã bị trừ mà đơn chưa xác nhận → nhất quán *cuối cùng*, không phải *tức thời*
> 2. **Giao dịch bù cũng có thể thất bại** — nếu `user-service` chết đúng lúc hoàn tiền thì sao? Sản phẩm thật cần retry và log đối soát
> 3. Đây là **cái giá cố hữu** của microservices, không phải do làm sai

**Khôi phục nhà hàng #2:**
```bash
curl -X POST "http://localhost:8000/api/v1/restaurants/2/toggle-open?open=true"
```

---

## 🧪 Thí nghiệm 7 — Ví không đủ tiền

User #3 chỉ có 30.000đ, món Phở Thìn giá 75.000đ:

```bash
curl -X POST "http://localhost:8000/api/v1/orders?userId=3&restaurantId=1"
```
**Sẽ thấy:** `"status":"CANCELLED"` với thông báo `So du khong du`

```bash
curl http://localhost:8000/api/v1/users/3
```
**Phải thấy:** vẫn đúng `30000` — **không bị trừ đồng nào**

**Vì sao khác Thí nghiệm 6:** ở đây lỗi xảy ra **ngay tại bước 3**, tiền chưa kịp bị trừ → chỉ cần huỷ đơn, **không cần giao dịch bù**. Giao dịch bù chỉ cần khi đã có thao tác thành công cần hoàn tác.

---

# BÀI 7 — TÌM LỖI

### Bước 1 — Container nào chết?

```bash
docker ps -a --filter name=quickbite5 --format "table {{.Names}}\t{{.Status}}"
```

### Bước 2 — Service báo lỗi gì?

```bash
docker logs --tail=50 quickbite5-order
```
```bash
docker logs quickbite5-order 2>&1 | grep "Caused by" | tail -2
```
> Đọc dòng `Caused by:` **cuối cùng** — đó mới là nguyên nhân gốc.

### Bước 3 — Gateway định tuyến đúng chưa?

```bash
curl http://localhost:8000/actuator/gateway/routes
```
```bash
docker logs --tail=30 quickbite5-gateway
```

### Bước 4 — Biến môi trường thật là gì?

```bash
docker exec quickbite5-order env | grep -E "SPRING_DATASOURCE|SERVICE_URL"
```

### Bước 5 — Mạng có thông không?

```bash
docker network inspect quickbite5-net | grep -E '"Name"'
```
**Phải thấy:** đủ 6 container

```bash
docker exec quickbite5-order ping -c 2 user-service
```

### Bước 6 — Database ổn không?

```bash
docker exec quickbite5-db pg_isready -U postgres
```
```bash
docker exec quickbite5-db psql -U postgres -c "\l"
```

---

## 🧪 Thí nghiệm 8 — Chạy stack service trước database

```bash
cd ~/Downloads/quickbite-demo/session-05/stack && docker compose down
```
```bash
cd ~/Downloads/quickbite-demo/session-05/quickbite5-db && docker compose down
```
```bash
cd ~/Downloads/quickbite-demo/session-05/stack && docker compose up -d
```

**Sẽ thấy:**
```
network quickbite5-net declared as external, but could not be found
```

**Vì sao:** stack database là bên **tạo ra** mạng `quickbite5-net`. Stack service chỉ **dùng nhờ** (`external: true`).

**Sửa — dùng script để không bao giờ sai thứ tự:**
```bash
cd ~/Downloads/quickbite-demo/session-05 && ./start-all.sh
```

---

## 🧪 Thí nghiệm 9 — Gateway cache DNS sau khi rebuild service

> Lỗi này rất hay gặp khi sinh viên sửa code rồi rebuild riêng một service.

```bash
cd ~/Downloads/quickbite-demo/session-05/stack
```
```bash
docker compose up -d --force-recreate notification-service && sleep 15
```
```bash
curl -m 8 http://localhost:8000/api/v1/notifications
```
**Có thể thấy:** `"status":500` — và trong log gateway là `Connection refused`

```bash
docker logs quickbite5-gateway 2>&1 | grep -i "connection refused" | tail -1
```

**Vì sao:** gateway chạy trên Netty, mà Netty **cache kết quả phân giải DNS**. Container vừa tạo lại có IP mới, nhưng gateway vẫn gọi vào IP cũ.

**Sửa:**
```bash
docker compose restart api-gateway && sleep 15
```
```bash
curl http://localhost:8000/api/v1/notifications
```
**Phải thấy:** dữ liệu trở lại bình thường

> 💡 **Quy tắc nhớ:** rebuild service nào cũng được, nhưng **restart gateway sau đó**. Script `./start-all.sh` đã tự làm bước này.

---

## 🧪 Thí nghiệm 10 — File `data.sql` rỗng làm service chết

```bash
cd ~/Downloads/quickbite-demo/session-05/stack/notification-service
```
```bash
touch src/main/resources/data.sql
```
```bash
cd ~/Downloads/quickbite-demo/session-05 && ./build-all.sh notification-service
```
```bash
cd ~/Downloads/quickbite-demo/session-05/stack && docker compose up -d --build notification-service && sleep 15
```
```bash
docker logs quickbite5-notification 2>&1 | grep "Caused by" | tail -1
```

**Sẽ thấy:**
```
java.lang.IllegalArgumentException: 'script' must not be null or empty
```

**Vì sao:** `spring.sql.init.mode=always` yêu cầu Spring chạy `data.sql` nếu file tồn tại. File **rỗng** không phải là script hợp lệ → crash lúc khởi động.

**Sửa — xoá hẳn file, đừng để rỗng:**
```bash
rm ~/Downloads/quickbite-demo/session-05/stack/notification-service/src/main/resources/data.sql
```
```bash
cd ~/Downloads/quickbite-demo/session-05 && ./build-all.sh notification-service && ./start-all.sh
```

---

# PHỤ LỤC 1 · RESET KHI HỎNG

### Reset mềm — tắt bật lại, giữ dữ liệu

```bash
cd ~/Downloads/quickbite-demo/session-05 && ./stop-all.sh && ./start-all.sh
```

### Reset cứng — xoá sạch, dựng lại từ đầu

```bash
cd ~/Downloads/quickbite-demo/session-05 && ./reset-demo.sh
```
Gõ `yes`, rồi:
```bash
cd ~/Downloads/quickbite-demo/session-05 && ./start-all.sh && ./check.sh
```

### Nếu vẫn hỏng — build lại toàn bộ JAR

```bash
cd ~/Downloads/quickbite-demo/session-05 && ./reset-demo.sh
```
```bash
cd ~/Downloads/quickbite-demo/session-05 && ./build-all.sh && ./start-all.sh && ./check.sh
```

> ⚠️ Script chỉ chạy được ở **thư mục gốc** `session-05/`. Đứng ở `stack/` thì dùng đường dẫn đầy đủ:
> ```bash
> ~/Downloads/quickbite-demo/session-05/check.sh
> ```

---

# PHỤ LỤC 2 · BẢNG TRA NHANH

### Vận hành

| Việc | Lệnh |
|---|---|
| Bật cả hệ đúng thứ tự | `./start-all.sh` |
| Tắt cả hệ | `./stop-all.sh` |
| Kiểm tra 22 mục | `./check.sh` |
| Xoá sạch làm lại | `./reset-demo.sh` |
| Build lại JAR (không cần JDK) | `./build-all.sh [tên-service]` |
| Xem 6 container | `docker ps --filter name=quickbite5` |
| Xem cổng nào mở ra ngoài | `docker ps --format "table {{.Names}}\t{{.Ports}}"` |

### Gọi API (mọi thứ qua cổng 8000)

| Việc | Lệnh |
|---|---|
| Danh sách user + ví tiền | `curl http://localhost:8000/api/v1/users` |
| Một user | `curl http://localhost:8000/api/v1/users/1` |
| Danh sách nhà hàng | `curl http://localhost:8000/api/v1/restaurants` |
| Danh sách đơn hàng | `curl http://localhost:8000/api/v1/orders` |
| Thông báo | `curl http://localhost:8000/api/v1/notifications` |
| **Đặt hàng** | `curl -X POST "http://localhost:8000/api/v1/orders?userId=1&restaurantId=1"` |
| Mở/đóng cửa nhà hàng | `curl -X POST "http://localhost:8000/api/v1/restaurants/2/toggle-open?open=false"` |

### Debug

| Việc | Lệnh |
|---|---|
| Bảng định tuyến gateway | `curl http://localhost:8000/actuator/gateway/routes` |
| Sức khoẻ gateway | `curl http://localhost:8000/actuator/health` |
| Log 6 bước đặt hàng | `docker logs quickbite5-order 2>&1 \| grep BUOC` |
| Nguyên nhân gốc | `docker logs <container> 2>&1 \| grep "Caused by" \| tail -2` |
| Biến môi trường thật | `docker exec quickbite5-order env \| grep SERVICE_URL` |
| Ai trong mạng ảo | `docker network inspect quickbite5-net` |
| Liệt kê 4 database | `docker exec quickbite5-db psql -U postgres -c "\l"` |
| Gọi service từ trong mạng | `docker exec quickbite5-order wget -qO- http://user-service:8081/users` |

---

# PHỤ LỤC 3 · BẢNG LỖI

### 10 thí nghiệm lỗi trong tài liệu này

| # | Thông báo | Nguyên nhân | Sửa |
|---|---|---|---|
| 1 | `permission denied for database` | Service truy cập DB của service khác | Dùng đúng user của mình — đây là tính năng, không phải lỗi |
| 2 | `Connection refused` trên cổng 8082–8084 | Service nội bộ không mở ra máy thật | Gọi qua gateway cổng 8000 — đây là thiết kế đúng |
| 3 | Gateway trả `404` | Path không khớp Predicate | Xem `/actuator/gateway/routes`, kiểm tra `StripPrefix` |
| 4 | `UnknownHostException: restaurant-svc` | Tên service trong Feign sai | Sửa cho khớp `docker-compose.yml` |
| 5 | Hoá đơn cũ đổi giá theo thực đơn | Thiếu Snapshot | Lưu bản sao tĩnh vào bảng `orders` |
| 6 | Tiền bị trừ nhưng đơn huỷ | Thiếu giao dịch bù | Thêm `catch` gọi `refundWallet` |
| 7 | `So du khong du` | Ví ít hơn giá món | Đúng nghiệp vụ — không cần giao dịch bù |
| 8 | `network quickbite5-net ... not found` | Chạy stack service trước DB | `./start-all.sh` |
| 9 | Gateway `Connection refused` sau rebuild | Netty cache DNS, service đổi IP | `docker compose restart api-gateway` |
| 10 | `'script' must not be null or empty` | File `data.sql` rỗng | Xoá hẳn file |

### Lỗi khác

| Triệu chứng | Sửa |
|---|---|
| `NoSuchBeanDefinition` cho Feign client | Thêm `@EnableFeignClients` vào lớp Application |
| `Could not find ...spring-cloud-starter-openfeign:` | Thêm BOM `spring-cloud-dependencies` vào `build.gradle` |
| `port is already allocated` cổng 8000 | Đổi `GATEWAY_HOST_PORT` trong `.env` |
| Gọi `localhost:8081` vẫn có dữ liệu | Đó là **Session 04** đang chạy — `cd ~/Downloads/quickbite-demo && ./stop-all.sh` |
| `no matching manifest for linux/arm64` | Mac Apple Silicon — đã có `platform: linux/amd64` sẵn trong compose |
| Windows: `curl` ra kết quả lạ | Dùng `curl.exe` |
| Windows: `./x.sh` báo `bad interpreter` | Lỗi CRLF — `sed -i 's/\r$//' *.sh` |

---

# ✅ CHECKLIST

- [ ] Phân biệt được container Session 04 (`quickbite-`) và Session 05 (`quickbite5-`)
- [ ] Liệt kê được 4 database logic trong một container Postgres
- [ ] **Thí nghiệm 1:** chứng minh service không đọc được DB của service khác
- [ ] Giải thích được vì sao biến `.env` phải có tiền tố
- [ ] **Thí nghiệm 2:** chứng minh service nội bộ không gọi được từ máy thật
- [ ] Đọc được bảng định tuyến bằng `/actuator/gateway/routes`
- [ ] Giải thích được `StripPrefix=2` biến đổi path như thế nào
- [ ] **Thí nghiệm 3:** biết 3 bước chẩn đoán khi gateway trả 404
- [ ] Đọc hiểu một `@FeignClient` và 3 điều bắt buộc khi dùng
- [ ] **Thí nghiệm 4:** hiểu vì sao sai tên service cho `UnknownHostException`
- [ ] Chạy được luồng đặt hàng và đọc log 6 bước
- [ ] **Thí nghiệm 5:** giải thích được Snapshot Pattern
- [ ] **Thí nghiệm 6:** giải thích được Saga và giao dịch bù
- [ ] **Thí nghiệm 7:** phân biệt lỗi ở bước 3 (không cần bù) và bước 4 (cần bù)
- [ ] **Thí nghiệm 9:** biết phải restart gateway sau khi rebuild service
- [ ] Biết 6 bước tìm lỗi ở BÀI 7
- [ ] Biết cách reset khi hỏng
