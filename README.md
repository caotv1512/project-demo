# QuickBite — Mock Project demo Session 04

Project chạy được thật, dựng để **demo trực tiếp bảng lệnh thực hành** (`02-LAB-Cac-lenh-va-giai-thich.md`).
Mọi lệnh trong bảng lab đều đã được chạy thử và xác nhận hoạt động trên project này.

---

## ⚡ TL;DR — chạy demo trong 1 phút

```bash
cd quickbite
./start-all.sh          # bật DB → backend, đúng thứ tự
./check.sh              # kiểm tra 11 mục, phải 11/11 pass
```

Mở thử:
```bash
curl http://localhost:8081/actuator/health
curl http://localhost:8081/api/users
```

Kết thúc:
```bash
./stop-all.sh           # tắt, GIỮ dữ liệu
./reset-demo.sh         # xoá sạch, về trạng thái ban đầu (hỏi xác nhận)
```

---

## 📁 Cấu trúc

```
quickbite/
├── start-all.sh                  Bật hệ thống đúng thứ tự (DB trước, backend sau)
├── stop-all.sh                   Tắt đúng thứ tự ngược lại
├── reset-demo.sh                 Xoá sạch để demo lại từ đầu (có xác nhận)
├── check.sh                      Tự kiểm tra 11 mục trước khi lên lớp
├── build-jar.sh                  Build JAR không cần cài JDK trên máy
│
├── lab0-test/                    LAB 0.4 — file Compose tối giản
│   └── docker-compose.yml
│
├── quickbite-db/                 STACK 1 — Database (bật TRƯỚC)
│   ├── docker-compose.yml
│   └── init-db.sql
│
├── quickbite-backend/            STACK 2 — Backend (bật SAU)
│   ├── docker-compose.yml
│   ├── .env                      (đã có sẵn để demo chạy ngay)
│   ├── .env.example
│   ├── .gitignore
│   └── user-service/             Spring Boot 3.3.5 · Java 17 · cổng 8081
│       ├── Dockerfile
│       ├── build.gradle
│       ├── gradlew  gradle/
│       └── src/main/…
│
└── bai-tap-1-restaurant/         LỜI GIẢI Bài tập 1 (tuỳ chọn)
    ├── docker-compose.yml
    └── restaurant-service/       Spring Boot 3.3.5 · Java 21 · cổng 8082
```

---

## 🔌 Yêu cầu

- Docker Desktop đang chạy (đã test trên Docker 29.7.2 / Compose v5.5.0)
- **Ba cổng phải trống:** `5432`, `8081`, `8082`
- **Không cần cài JDK hay Gradle** — file JAR đã build sẵn trong `build/libs/`

Kiểm tra cổng trống:
```bash
lsof -i :5432 -i :8081 -i :8082
```

---

## ⚠️ MỘT ĐIỂM PHẢI BIẾT TRƯỚC KHI LÊN LỚP

**`eclipse-temurin:17-jre-alpine` (image trong slide) KHÔNG có bản arm64.**

Máy Mac Apple Silicon (M1/M2/M3/M4) chạy lệnh trong slide sẽ **fail cứng**:

```
no matching manifest for linux/arm64/v8 in the manifest list entries
```

Project này đã xử lý bằng một dòng trong `quickbite-backend/docker-compose.yml`:

```yaml
platform: linux/amd64
```

| Máy của sinh viên | Ảnh hưởng |
|---|---|
| Windows / Linux / Mac Intel | Đây là kiến trúc gốc — không tốn gì |
| Mac Apple Silicon | Chạy qua Rosetta — **đã đo: Spring Boot khởi động 4.2s**, không đáng kể |

> 💡 **Đây là một teaching moment rất tốt.** Nếu lớp có sinh viên dùng Mac M-series, hãy để họ gặp lỗi này rồi giải thích: một *tag* image không đảm bảo có đủ mọi kiến trúc CPU. Kiểm tra bằng:
> ```bash
> docker manifest inspect eclipse-temurin:17-jre-alpine | grep architecture
> ```
>
> **Đối chiếu:** `restaurant-service` dùng `eclipse-temurin:21-jre-alpine` — bản **21 CÓ arm64**, nên compose của nó *không cần* dòng `platform`. Hai service cạnh nhau, một cần một không — minh hoạ trực quan.

---

## 🗺️ BẢN ĐỒ: lệnh trong bảng lab ↔ chạy ở đâu

| LAB | Nội dung | Thư mục | Ghi chú |
|---|---|---|---|
| 0.1–0.3 | Kiểm tra môi trường | bất kỳ | |
| 0.4 | Compose tối giản `java -version` | `lab0-test/` | |
| 1 | Đọc Dockerfile | `quickbite-backend/user-service/Dockerfile` | Giống hệt slide |
| 2.1 | `./gradlew bootJar` | `quickbite-backend/user-service/` | Cần JDK 17. Không có → `./build-jar.sh` |
| 2.2–2.6 | `docker build` / `run` / `logs` thủ công | `quickbite-backend/user-service/` | |
| 3 | Stack database | `quickbite-db/` | |
| 4 | `.env` + compose backend | `quickbite-backend/` | |
| 5 | Chạy stack backend | `quickbite-backend/` | |
| 6 | Vòng đời `up/stop/down` | cả hai stack | |
| 7 | Bộ lệnh debug | cả hai stack | |

---

## 🎬 KỊCH BẢN DEMO THEO TRÌNH TỰ BUỔI DẠY

### Trước giờ lên lớp

```bash
cd quickbite
./check.sh              # phải 11/11 pass
./reset-demo.sh         # rồi reset về sạch để demo từ đầu
```
Mục đích: pull sẵn toàn bộ image, để trên lớp không phải đợi mạng.

---

### Phần 1 — Vấn đề của `docker run` (slide 5–6)

Cho sinh viên thấy IP là **động** — đây là khoảnh khắc "à-ha" của phần 1:

```bash
cd quickbite-db && docker compose up -d
docker inspect quickbite-db -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
docker compose restart
docker inspect quickbite-db -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
```

> Hai lần in ra **có thể khác nhau**. Nếu trùng, giải thích: Docker cấp lại IP theo thứ tự, trùng là may — không có gì đảm bảo. Xoá mạng rồi tạo lại (`down` + `up`) sẽ thấy đổi rõ.

---

### Phần 1 — Dockerfile và build (LAB 1–2)

> ⚠️ **Trước khi demo phần này, phải tắt stack backend** — nếu không, container `quickbite-user`
> đang giữ cổng 8081 sẽ trả lời thay và demo "EXPOSE không mở cổng" sẽ cho kết quả sai:
> ```bash
> cd quickbite-backend && docker compose down
> ```

```bash
cd quickbite-backend/user-service
cat Dockerfile

docker build --platform linux/amd64 -t quickbite-user-service:v1 .

# --- Chứng minh EXPOSE 8081 KHÔNG tự mở cổng ---
# Container chạy HOÀN TOÀN BÌNH THƯỜNG (có network, có DB), chỉ thiếu mỗi cờ -p:
docker run -d --name demo-noport --network quickbite-net \
  -e DB_HOST=quickbite-db quickbite-user-service:v1
sleep 10
docker logs demo-noport | grep Started          # app ĐÃ khởi động thành công ✅
curl http://localhost:8081/actuator/health      # nhưng host vẫn KHÔNG vào được ❌
docker rm -f demo-noport

# --- Thêm -p, cùng một image, vào được ngay ---
docker run -d -p 8081:8081 --name demo-port --network quickbite-net \
  -e DB_HOST=quickbite-db quickbite-user-service:v1
sleep 10 && curl -s http://localhost:8081/actuator/health   # → {"status":"UP"} ✅
docker rm -f demo-port
```

---

### Phần 3 — Database tự khởi tạo (LAB 3)

```bash
cd ../../quickbite-db
docker compose up -d
docker exec quickbite-db pg_isready -U postgres

# Bằng chứng init-db.sql đã chạy:
docker compose exec quickbite-db psql -U postgres -c "\l"
docker compose exec quickbite-db psql -U postgres -c "\du"
```

**Demo cái bẫy "script chỉ chạy một lần"** — rất đáng làm:

```bash
# Thêm 1 dòng vào init-db.sql
echo "CREATE DATABASE demo_them_moi;" >> init-db.sql

docker compose restart
docker compose exec quickbite-db psql -U postgres -c "\l" | grep demo_them_moi   # KHÔNG thấy ❌

docker compose down -v && docker compose up -d && sleep 8
docker compose exec quickbite-db psql -U postgres -c "\l" | grep demo_them_moi   # THẤY ✅

# Dọn lại
sed -i '' '/demo_them_moi/d' init-db.sql
docker compose down -v && docker compose up -d
```

---

### Phần 4–5 — `.env`, Service Discovery (LAB 4–5)

```bash
cd ../quickbite-backend
cat .env
docker compose config | head -30      # xem sau khi Compose đã thay hết ${...}

docker compose up -d --build
docker compose ps
curl -s http://localhost:8081/actuator/health
curl -s http://localhost:8081/api/users
curl -s http://localhost:8081/api/db-check
```

**Chứng minh Service Discovery** — điểm khép vòng của bài giảng:

```bash
docker compose exec quickbite-user ping -c 3 quickbite-db
docker compose exec quickbite-user env | grep DB_
```

> `/api/db-check` trả về `serverAddress` chính là IP mà `ping` phân giải ra.
> Nhấn mạnh: **con số IP đó ta không cần biết và không nên quan tâm** — đúng bài toán đặt ra ở đầu buổi học.

**Chứng minh `localhost` bên trong container ≠ máy host:**

```bash
docker compose exec quickbite-user ping -c 2 localhost      # → trả về chính nó (127.0.0.1)
```

---

### Điểm nhấn mạnh nhất: Java 17 và Java 21 chạy song song

```bash
cd ../bai-tap-1-restaurant && docker compose up -d --build && sleep 10
curl -s http://localhost:8081/api/info     # javaVersion: 17.0.20
curl -s http://localhost:8082/api/info     # javaVersion: 21.0.12
```

Hai container, hai phiên bản Java, **cùng nối một PostgreSQL**, không hề xung đột.
Trên một máy vật lý truyền thống việc này phải đổi `JAVA_HOME` qua lại.

---

### Phần 6 — Vòng đời và bảng an toàn dữ liệu (LAB 6)

Demo `down` **không** mất dữ liệu:

```bash
cd ../quickbite-backend
curl -s http://localhost:8081/api/users | grep -o '"id":[0-9]*' | wc -l    # 3 bản ghi

cd ../quickbite-db
docker compose down          # KHÔNG có -v
docker compose up -d && sleep 8
docker compose exec quickbite-db psql -U quickbite_user -d quickbite_user_db \
  -c "SELECT COUNT(*) FROM users;"                                          # vẫn 3 ✅
```

Rồi cho thấy `-v` xoá sạch:

```bash
docker compose down -v && docker compose up -d && sleep 8
docker compose exec quickbite-db psql -U quickbite_user -d quickbite_user_db \
  -c "SELECT COUNT(*) FROM users;"        # lỗi: bảng chưa tồn tại — dữ liệu đã mất ⚠️
```

---

### Phần 7 — Demo các lỗi kinh điển

**Lỗi: chạy backend trước database**
```bash
cd ../quickbite-db && docker compose down
cd ../quickbite-backend && docker compose up -d
# → network quickbite-net declared as external, but could not be found
```

**Lỗi: quên `--build` sau khi sửa code**
```bash
# Sửa chuỗi trong UserController.java, rồi:
./build-jar.sh                              # hoặc ./gradlew bootJar
docker compose up -d                         # KHÔNG có --build → vẫn image cũ ❌
docker compose up -d --build                 # có --build → thấy thay đổi ✅
```

**Lỗi: trùng cổng**
```bash
docker run -d -p 8081:8081 --name conflict nginx
# → Bind for 0.0.0.0:8081 failed: port is already allocated
docker rm -f conflict
```

---

## 🧪 API dùng để demo

| Endpoint | Trả về | Dùng để chứng minh |
|---|---|---|
| `GET /actuator/health` | `{"status":"UP","components":{"db":{"status":"UP"...` | App sống **và** kết nối DB thành công |
| `GET /api/info` | service, javaVersion, hostname, dbHost | Phân biệt Java 17 vs 21; thấy biến môi trường đã vào container |
| `GET /api/users` | 3 bản ghi từ PostgreSQL | Dữ liệu thật đọc qua mạng container |
| `GET /api/db-check` | currentDatabase, currentUser, serverAddress, postgresVersion | Đúng DB, đúng user, và IP khớp với `ping` |

---

## 🛠️ Khi không có JDK trên máy

Bảng lab dạy `./gradlew bootJar` — lệnh này cần JDK 17 trên host.
Nếu máy chưa cài JDK, dùng script thay thế, **kết quả ra y hệt**:

```bash
./build-jar.sh                        # build user-service
./build-jar.sh restaurant-service     # build restaurant-service
```

Script chạy Gradle **bên trong container** và ghi ra đúng `build/libs/<service>.jar`.
Mọi lệnh Docker phía sau không đổi một chữ.

> Muốn dùng đúng `./gradlew bootJar` như bảng lab: cài JDK 17
> ```bash
> brew install --cask temurin@17
> ```

---

## ✅ Đã kiểm chứng trên máy này

| Hạng mục | Kết quả |
|---|---|
| `check.sh` | **11/11 pass** |
| Reset sạch → hệ thống chạy lại đầy đủ | **11.7 giây** |
| Spring Boot khởi động (amd64 emulation trên ARM) | **4.2 giây** |
| `init-db.sql` tạo đúng 2 database + 2 user | ✅ |
| `/actuator/health` → `db: UP` | ✅ |
| `/api/users` đọc được dữ liệu thật | ✅ |
| `ping quickbite-db` từ trong container app | ✅ |
| Java 17 (8081) + Java 21 (8082) song song | ✅ |
| Lỗi `network ... could not be found` tái hiện đúng | ✅ |

---

## 🧯 Sự cố nhanh

| Triệu chứng | Xử lý |
|---|---|
| `port is already allocated` | `lsof -i :8081` tìm tiến trình, hoặc đổi `USER_SERVER_PORT` trong `.env` |
| `no matching manifest for linux/arm64` | Thiếu `platform: linux/amd64` trong compose |
| `network ... could not be found` | Chưa bật stack DB. Chạy `./start-all.sh` |
| App `Up` nhưng `/api/users` lỗi 500 | DB chưa sẵn sàng. Đợi thêm hoặc xem `docker compose logs quickbite-user` |
| Sửa code không thấy đổi | `./build-jar.sh && docker compose up -d --build` |
| Muốn làm lại sạch từ đầu | `./reset-demo.sh` |
