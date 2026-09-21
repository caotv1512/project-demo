# LAB SESSION 04 — BẢNG LỆNH THỰC HÀNH
# Dockerfile & Docker Compose · Dự án QuickBite

> **Cách dùng:** làm tuần tự từ BÀI 1 → BÀI 7. Mỗi bài gồm **lệnh cần gõ** → **kết quả phải thấy** → **thí nghiệm gây lỗi** để hiểu vì sao.
> Gõ từng lệnh, đọc kết quả, hiểu rồi mới sang lệnh sau. Đừng copy-paste hàng loạt.

---

# A · CHUẨN BỊ (làm một lần)

## A1. Đường dẫn project

Tài liệu này giả sử project nằm ở `~/Downloads/quickbite-demo`.

**Nếu máy bạn để chỗ khác**, thay phần `~/Downloads/quickbite-demo` trong mọi lệnh bằng đường dẫn của bạn. Ví dụ:

| Nơi bạn để project | Thay bằng |
|---|---|
| Desktop | `~/Desktop/quickbite-demo` |
| Thư mục code | `~/code/quickbite-demo` |
| Windows, ổ D | `D:\hoc-docker\quickbite-demo` |

> 💡 **Mẹo lấy đúng đường dẫn:** mở thư mục project trong terminal rồi gõ `pwd` — copy kết quả đó ra dùng.

## A2. Quy tắc thư mục — ĐỌC KỸ, đây là lỗi hay gặp nhất

Project có **thư mục gốc** và **4 thư mục con**. Mỗi nơi chạy được loại lệnh khác nhau:

```
quickbite-demo/              ← THƯ MỤC GỐC: chỉ chạy được SCRIPT (.sh)
│                              KHÔNG có docker-compose.yml ở đây
├── start-all.sh  stop-all.sh  check.sh  reset-demo.sh  build-jar.sh
│
├── quickbite-db/            ← có docker-compose.yml  (Database)
├── quickbite-backend/       ← có docker-compose.yml  (Backend)
├── lab0-test/               ← có docker-compose.yml  (Bài 1)
└── bai-tap-1-restaurant/    ← có docker-compose.yml  (Bài tập)
```

| Bạn đang đứng ở | Chạy được | KHÔNG chạy được |
|---|---|---|
| Thư mục gốc `quickbite-demo/` | `./check.sh` `./start-all.sh` … | `docker compose …` |
| Thư mục con `quickbite-db/` … | `docker compose …` | `./check.sh` |

**Hai thông báo này là BÌNH THƯỜNG, không phải hỏng máy:**

```
ls: docker-compose.yml: No such file or directory
```
→ Bạn đang ở **thư mục gốc**. Đúng, vì gốc không chứa file compose. Muốn dùng `docker compose` thì `cd` vào thư mục con.

```
zsh: no such file or directory: ./check.sh
```
→ Bạn đang ở **thư mục con**. Đúng, vì script nằm ở gốc.

> 💡 **Cách chạy script từ bất cứ đâu** — dùng đường dẫn đầy đủ thay vì `./`:
> ```bash
> ~/Downloads/quickbite-demo/check.sh
> ```
> Cách này luôn đúng dù bạn đang đứng ở thư mục nào.

## A3. Lệnh khác nhau theo hệ điều hành

Mọi lệnh bắt đầu bằng `docker` **giống hệt nhau trên cả 3 hệ**. Chỉ lệnh của hệ điều hành mới khác:

| Việc | macOS · Ubuntu · Git Bash | Windows PowerShell |
|---|---|---|
| Build JAR | `./gradlew bootJar` | `.\gradlew.bat bootJar` |
| Gọi API | `curl -s <url>` | `curl.exe -s <url>` |
| Lọc chữ | `… \| grep x` | `… \| Select-String x` |
| Xem file | `cat f` | `Get-Content f` |
| Xem file ẩn | `ls -la` | `ls -Force` |
| Copy file | `cp a b` | `Copy-Item a b` |
| Tìm cổng bận | `lsof -i :8081` | `netstat -ano \| findstr :8081` |
| Tắt tiến trình | `kill -9 <pid>` | `taskkill /PID <pid> /F` |
| Chạy script `.sh` | `./x.sh` | dùng **Git Bash** |

> 💡 **Sinh viên Windows:** cài [Git for Windows](https://git-scm.com/download/win) rồi dùng **Git Bash**. Khi đó toàn bộ lệnh trong tài liệu chạy nguyên xi, không cần quy đổi.

## A4. Ba việc phải làm trước khi bắt đầu

**① Mac chip Apple Silicon (M1/M2/M3/M4)** — project đã xử lý sẵn bằng dòng `platform: linux/amd64` trong file compose. Không cần làm gì. Nếu tự viết compose mới, nhớ thêm dòng đó, nếu không sẽ gặp:
```
no matching manifest for linux/arm64/v8
```

**② Windows PowerShell** — gõ `curl.exe` (có `.exe`), vì `curl` trong PowerShell là lệnh khác hẳn.

**③ Windows, script `.sh` không chạy** — lỗi CRLF. Sửa:
```bash
cd ~/Downloads/quickbite-demo
sed -i 's/\r$//' *.sh
```

## A5. Ba cổng phải trống: `5432`, `8081`, `8082`

```bash
lsof -i :5432 -i :8081 -i :8082
```
```powershell
netstat -ano | findstr ":5432 :8081 :8082"
```

**Không có kết quả = cổng trống = tốt.**

---

# B · KHỞI ĐỘNG NHANH

Nếu chỉ muốn thấy hệ thống chạy trước khi học chi tiết:

```bash
cd ~/Downloads/quickbite-demo
./start-all.sh
```

```bash
cd ~/Downloads/quickbite-demo
./check.sh
```

**Phải thấy:** `KET QUA: 11 pass / 0 fail`

Mở trình duyệt: <http://localhost:8081/api/users>

Rồi tắt đi để bắt đầu học từ đầu:

```bash
cd ~/Downloads/quickbite-demo
./stop-all.sh
```

---

# BÀI 1 — KIỂM TRA MÔI TRƯỜNG

**Mục tiêu:** xác nhận Docker hoạt động trước khi đụng vào project.

### 1.1 · Kiểm tra Docker

```bash
docker --version
```
**Phải thấy:** `Docker version 27.x.x` (bản 24 trở lên đều dùng được)

```bash
docker compose version
```
**Phải thấy:** `Docker Compose version v2.x.x`

> **Vì sao:** `docker compose` (khoảng trắng) là bản V2 hiện hành. `docker-compose` (gạch nối) là bản cũ đã ngừng hỗ trợ từ 07/2023.

**Nếu báo `Cannot connect to the Docker daemon`:**

| Hệ điều hành | Xử lý |
|---|---|
| macOS · Windows | Mở **Docker Desktop**, đợi icon cá voi hết nhấp nháy |
| Ubuntu | `sudo systemctl start docker` |

**Nếu Ubuntu báo `permission denied`:**
```bash
sudo usermod -aG docker $USER && newgrp docker
```

### 1.2 · Chạy thử file Compose tối giản

```bash
cd ~/Downloads/quickbite-demo/lab0-test
```
```bash
docker compose up
```

**Phải thấy:**
```
java-tester-1  | openjdk version "17.0.x" ...
java-tester-1 exited with code 0
```

> **Vì sao `exited with code 0` là THÀNH CÔNG:** container chỉ sống đúng bằng vòng đời tiến trình chính của nó. Lệnh `java -version` in xong là kết thúc → container dừng. Đây là hành vi đúng.

> ℹ️ Dòng cảnh báo `the attribute version is obsolete` **không phải lỗi**. Compose V2 không còn cần trường `version:`.

```bash
docker compose down
```

---

## 🧪 Thí nghiệm 1 — Chạy lệnh compose ở sai thư mục

```bash
cd ~/Downloads/quickbite-demo
```
```bash
docker compose ps
```

**Sẽ thấy:**
```
no configuration file provided: not found
```

**Vì sao:** `docker compose` luôn tìm file `docker-compose.yml` **ở thư mục bạn đang đứng**. Thư mục gốc không có file đó.

**Sửa:** `cd` vào thư mục con có file compose.
```bash
cd ~/Downloads/quickbite-demo/quickbite-db && docker compose ps
```

---

# BÀI 2 — DOCKERFILE & BUILD IMAGE

**Mục tiêu:** tự đóng gói một service Spring Boot thành image.

```bash
cd ~/Downloads/quickbite-demo/quickbite-backend/user-service
```

### 2.1 · Đọc Dockerfile

```bash
cat Dockerfile
```

```dockerfile
FROM eclipse-temurin:17-jre-alpine      # 1. nền: Linux nhỏ + Java 17
WORKDIR /app                            # 2. vào thư mục làm việc
COPY build/libs/user-service.jar app.jar # 3. chép JAR vào
EXPOSE 8081                             # 4. dán nhãn: nghe cổng 8081
ENTRYPOINT ["java", "-jar", "app.jar"]  # 5. lệnh chạy khi bật container
```

| Dòng | Vì sao cần |
|---|---|
| `FROM` | Mọi image phải có điểm khởi đầu. `jre` nhẹ hơn `jdk` (~180MB vs ~450MB), `alpine` nhẹ hơn Debian |
| `WORKDIR` | Tạo `/app` và `cd` vào đó. Mọi đường dẫn sau tính từ đây |
| `COPY` | Vế trái = trên máy bạn, vế phải = trong container. Đổi tên thành `app.jar` để không phụ thuộc số version |
| `EXPOSE` | **Chỉ là nhãn dán.** KHÔNG mở cổng |
| `ENTRYPOINT` | Tiến trình chính. Viết **dạng mảng JSON** để Java nhận được tín hiệu dừng và tắt sạch sẽ |

### 2.2 · Build file JAR

```bash
cd ~/Downloads/quickbite-demo/quickbite-backend/user-service
```
```bash
./gradlew bootJar
```
```powershell
.\gradlew.bat bootJar
```

**Phải thấy:** `BUILD SUCCESSFUL`

> 🛟 **Máy chưa cài JDK 17?** Dùng script build bằng Docker, kết quả ra file y hệt:
> ```bash
> cd ~/Downloads/quickbite-demo && ./build-jar.sh
> ```

```bash
ls -lh build/libs/
```
**Phải thấy:** `user-service.jar` (~24M)

> **Vì sao kiểm tra:** đây là nguyên nhân số 1 gây lỗi `COPY failed` ở bước sau.

### 2.3 · Build image

```bash
cd ~/Downloads/quickbite-demo/quickbite-backend/user-service
```
```bash
docker build --platform linux/amd64 -t quickbite-user-service:v1 .
```

**Phải thấy:** dòng cuối `naming to docker.io/library/quickbite-user-service:v1 done`

| Tham số | Vì sao cần |
|---|---|
| `--platform linux/amd64` | Bắt buộc trên Mac Apple Silicon. Máy khác giữ cũng không sao |
| `-t quickbite-user-service:v1` | Đặt tên + version cho image. Không có thì chỉ còn mã băm khó nhớ |
| `.` (dấu chấm cuối) | **Build context** — thư mục Docker được phép nhìn thấy. `COPY` tìm file tương đối từ đây |

```bash
docker images | grep quickbite
```
**Phải thấy:** image `quickbite-user-service` cỡ ~200MB

---

## 🧪 Thí nghiệm 2 — Sai tên file trong COPY

Sửa tạm Dockerfile cho sai tên JAR:

```bash
cd ~/Downloads/quickbite-demo/quickbite-backend/user-service
```
```bash
sed -i '' 's|user-service.jar app.jar|user-service-1.0.0.jar app.jar|' Dockerfile
```
```bash
docker build --platform linux/amd64 -t thu-loi .
```

**Sẽ thấy:**
```
ERROR: failed to build: ... "/build/libs/user-service-1.0.0.jar": not found
```

**Vì sao:** Docker chỉ thấy file nằm trong build context, và tên phải khớp **chính xác**. Mặc định Gradle sinh ra tên có kèm version (`user-service-1.0.0.jar`) — project này đã ép tên cố định trong `build.gradle`:
```gradle
bootJar { archiveFileName = 'user-service.jar' }
```

**Khôi phục:**
```bash
sed -i '' 's|user-service-1.0.0.jar app.jar|user-service.jar app.jar|' Dockerfile
```

---

## 🧪 Thí nghiệm 3 — EXPOSE không mở cổng

> **Chuẩn bị:** stack database phải đang chạy. Nếu chưa:
> ```bash
> cd ~/Downloads/quickbite-demo/quickbite-db && docker compose up -d
> ```
> Thí nghiệm dùng cổng **8091** để không đụng vào cổng 8081 của hệ thống chính.

Chạy container **đầy đủ mọi thứ, chỉ THIẾU cờ `-p`**:

```bash
docker run -d --name thu-khong-p --network quickbite-net \
  -e DB_HOST=quickbite-db quickbite-user-service:v1
```
```bash
sleep 15 && docker logs thu-khong-p | grep Started
```
**Phải thấy:** `Started UserServiceApplication in 3.4 seconds` → **app khởi động HOÀN TOÀN BÌNH THƯỜNG**

```bash
curl http://localhost:8091/actuator/health
```
**Sẽ thấy:** `Connection refused` → **nhưng không vào được từ máy thật**

**Vì sao:** `EXPOSE 8081` trong Dockerfile chỉ là **nhãn dán**. App vẫn nghe cổng 8081 *bên trong* container, nhưng cánh cửa ra máy thật chưa được mở.

Giờ thêm `-p`, **vẫn image đó, không sửa gì khác**:

```bash
docker rm -f thu-khong-p
```
```bash
docker run -d -p 8091:8081 --name thu-co-p --network quickbite-net \
  -e DB_HOST=quickbite-db quickbite-user-service:v1
```
```bash
sleep 15 && curl http://localhost:8091/actuator/health
```
**Phải thấy:** `{"status":"UP","components":{"db":{"status":"UP"...` → **vào được rồi**

> 💡 Hai lần chạy **cùng một image**, khác nhau đúng một cờ `-p`. Đó là toàn bộ bài học.

**Dọn dẹp:**
```bash
docker rm -f thu-co-p
```

> 💡 **Câu thần chú: EXPOSE là NÓI, `-p` là LÀM.**

---

# BÀI 3 — CHẠY DATABASE

**Mục tiêu:** dựng PostgreSQL tự tạo sẵn database và user.

```bash
cd ~/Downloads/quickbite-demo/quickbite-db
```

### 3.1 · Xem trước sẽ chạy gì

```bash
cat init-db.sql
```
```bash
docker compose config
```

> **Vì sao `docker compose config`:** nó đọc file YAML, thay hết biến, rồi in ra cấu hình **thực sự sẽ dùng**. Bắt lỗi thụt lề và biến thiếu **trước khi** tốn thời gian tạo container. Nên gõ mỗi lần vừa sửa file compose.

### 3.2 · Khởi chạy

```bash
docker compose up -d
```

**Phải thấy:**
```
✔ Network quickbite-net          Created
✔ Volume "quickbite-db_db-data"  Created
✔ Container quickbite-db         Started
```

```bash
docker compose ps
```
**Phải thấy:** cột STATUS là `Up`

### 3.3 · Xác nhận database sẵn sàng

```bash
docker exec quickbite-db pg_isready -U postgres
```
**Phải thấy:** `/var/run/postgresql:5432 - accepting connections`

> **Vì sao cần bước này:** container `Up` **không có nghĩa** PostgreSQL đã nhận kết nối. Nó cần vài giây để khởi tạo.

> ℹ️ Nhiều tài liệu viết `docker exec -it`. Cờ `-it` chỉ cần khi mở shell tương tác. Với lệnh chạy-một-lần, **bỏ `-it`** để tránh lỗi `the input device is not a TTY` trên Git Bash/PowerShell.

### 3.4 · Chứng minh `init-db.sql` đã chạy

```bash
docker compose exec quickbite-db psql -U postgres -c "\l"
```
**Phải thấy:** có `quickbite_user_db` và `quickbite_restaurant_db`

```bash
docker compose exec quickbite-db psql -U postgres -c "\du"
```
**Phải thấy:** có `quickbite_user` và `quickbite_restaurant`

> **Vì sao tự có:** image Postgres có quy ước — mọi file `.sql` trong `/docker-entrypoint-initdb.d/` được chạy tự động lần khởi động đầu tiên. File compose đã gắn `init-db.sql` vào đó.

---

## 🧪 Thí nghiệm 4 — Script init chỉ chạy MỘT LẦN

Thêm một database mới vào script:

```bash
cd ~/Downloads/quickbite-demo/quickbite-db
```
```bash
echo "CREATE DATABASE thu_nghiem;" >> init-db.sql
```

Thử `restart` xem có tác dụng không:

```bash
docker compose restart && sleep 8
```
```bash
docker compose exec quickbite-db psql -U postgres -c "\l" | grep thu_nghiem
```
**Sẽ thấy:** không có kết quả → **script KHÔNG chạy lại**

Giờ xoá volume rồi bật lại:

```bash
docker compose down -v && docker compose up -d && sleep 10
```
```bash
docker compose exec quickbite-db psql -U postgres -c "\l" | grep thu_nghiem
```
**Phải thấy:** `thu_nghiem` xuất hiện → **script đã chạy lại**

**Vì sao:** PostgreSQL chỉ chạy script khởi tạo khi thư mục dữ liệu **còn rỗng**. Volume đang có dữ liệu thì nó bỏ qua. Cờ `-v` xoá volume → dữ liệu rỗng trở lại → script chạy lại.

**Khôi phục file gốc:**
```bash
sed -i '' '/thu_nghiem/d' init-db.sql && docker compose down -v && docker compose up -d
```

> ⚠️ Ghi nhớ: sửa `init-db.sql` mà chỉ `restart` thì **không bao giờ có tác dụng**.

---

# BÀI 4 — BIẾN MÔI TRƯỜNG `.env`

**Mục tiêu:** tách mật khẩu ra khỏi file cấu hình.

```bash
cd ~/Downloads/quickbite-demo/quickbite-backend
```

### 4.1 · Xem các file

```bash
ls -la
```
```powershell
ls -Force
```
**Phải thấy:** `.env`, `.env.example`, `.gitignore`, `docker-compose.yml`

```bash
cat .env
```

| Biến | Giá trị | Lưu ý |
|---|---|---|
| `DB_HOST` | `quickbite-db` | **Tên service**, không phải `localhost`, không phải IP |
| `USER_DB_PASSWORD` | `quickbite_user` | Đây là lý do file này KHÔNG được lên Git |

```bash
cat .gitignore
```
**Phải thấy:** dòng `.env`

> **Vì sao bắt buộc:** Git lưu **toàn bộ lịch sử**. Commit nhầm mật khẩu rồi xoá đi thì `git log -p` vẫn đọc được. Repo public bị bot quét ra trong vài phút.

```bash
cat .env.example
```
> **Vì sao cần file mẫu:** `.env` không lên Git nên người mới clone về không biết cần biến gì. File `.example` có tên biến, không có giá trị thật. Người mới chỉ cần `cp .env.example .env` rồi điền.

### 4.2 · Xem Compose thay biến như thế nào

```bash
docker compose config | grep -E "DB_|SERVER_PORT|published"
```

**Phải thấy** giá trị thật đã được điền vào, ví dụ `DB_HOST: quickbite-db`, `published: "8081"`.

---

## 🧪 Thí nghiệm 5 — Thiếu biến trong `.env`

```bash
cd ~/Downloads/quickbite-demo/quickbite-backend
```
```bash
cp .env .env.backup
```
```bash
sed -i '' 's/^USER_SERVER_PORT=8081/#USER_SERVER_PORT=8081/' .env
```
```bash
docker compose config
```

**Sẽ thấy:**
```
WARN ... The "USER_SERVER_PORT" variable is not set. Defaulting to a blank string.
```

**Vì sao nguy hiểm:** Compose **chỉ cảnh báo nhẹ** rồi thay bằng chuỗi rỗng và vẫn chạy tiếp. Cổng biến thành `":"` → lỗi phát sinh sau đó rất khó truy nguyên.

> 💡 Đây chính là lý do nên gõ `docker compose config` mỗi khi sửa `.env`.

**Khôi phục:**
```bash
cp .env.backup .env && rm .env.backup
```

---

# BÀI 5 — CHẠY BACKEND

**Mục tiêu:** nối app vào database và kiểm chứng hoạt động.

### 5.1 · Kiểm tra mạng của database đã có chưa

```bash
docker network ls | grep quickbite
```
**Phải thấy:** dòng chứa `quickbite-net`

> **Vì sao:** file compose của backend khai báo `external: true` — nghĩa là nó **đòi** mạng phải có sẵn, do stack database tạo ra.

### 5.2 · Build JAR mới rồi khởi chạy

```bash
cd ~/Downloads/quickbite-demo/quickbite-backend/user-service && ./gradlew bootJar
```
```bash
cd ~/Downloads/quickbite-demo/quickbite-backend && docker compose up -d --build
```

> 📌 **QUY TRÌNH CHUẨN MỖI LẦN SỬA CODE JAVA:**
> ```
> Sửa code → ./gradlew bootJar → docker compose up -d --build
> ```
> Thiếu bước giữa → JAR cũ. Thiếu `--build` → image cũ.

```bash
docker compose ps
```
**Phải thấy:** `quickbite-user` · `Up` · `0.0.0.0:8081->8081/tcp`

### 5.3 · Kiểm chứng

```bash
curl http://localhost:8081/actuator/health
```
```powershell
curl.exe http://localhost:8081/actuator/health
```
**Phải thấy:** `{"status":"UP","components":{"db":{"status":"UP"...`

> Chỗ quan trọng là `"db":{"status":"UP"` — chứng minh app **kết nối được database**.

```bash
curl http://localhost:8081/api/users
```
**Phải thấy:** 3 bản ghi đọc từ PostgreSQL

```bash
curl http://localhost:8081/api/db-check
```
**Phải thấy:** `currentDatabase`, `currentUser`, `serverAddress`

> 💡 Không có `curl` cũng được — mở trình duyệt và dán địa chỉ vào. Cách này giống nhau trên mọi máy.

### 5.4 · Chứng minh Service Discovery

```bash
docker compose exec quickbite-user ping -c 3 quickbite-db
```
**Phải thấy:** `PING quickbite-db (172.x.x.x)` và 3 dòng trả lời

**So sánh với kết quả `/api/db-check` ở trên** — `serverAddress` chính là IP mà `ping` vừa phân giải ra.

> **Ý nghĩa:** con số IP đó bạn **không cần biết**. Docker có DNS nội bộ, tự dịch tên service thành IP hiện tại. Đây là lý do `.env` ghi `DB_HOST=quickbite-db` chứ không ghi IP.

```bash
docker compose exec quickbite-user env | grep DB_
```
**Phải thấy:** các biến `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`

> **Vì sao xem:** đây là **sự thật cuối cùng** — biến thật sự đang có bên trong container. Nếu sai ở đây thì lỗi nằm ở `.env`, không phải ở code Java.

---

## 🧪 Thí nghiệm 6 — Chạy backend TRƯỚC database

```bash
cd ~/Downloads/quickbite-demo/quickbite-backend && docker compose down
```
```bash
cd ~/Downloads/quickbite-demo/quickbite-db && docker compose down
```
```bash
cd ~/Downloads/quickbite-demo/quickbite-backend && docker compose up -d
```

**Sẽ thấy:**
```
network quickbite-net declared as external, but could not be found
```

**Vì sao:** stack database là bên **tạo ra** mạng `quickbite-net`. Backend chỉ **dùng nhờ** (`external: true`). Chưa có mạng thì không gắn vào đâu được.

**Sửa — bật đúng thứ tự:**
```bash
cd ~/Downloads/quickbite-demo/quickbite-db && docker compose up -d && sleep 10
```
```bash
cd ~/Downloads/quickbite-demo/quickbite-backend && docker compose up -d
```

> 💡 **Quy tắc vàng: Database lên TRƯỚC, xuống SAU.**

---

## 🧪 Thí nghiệm 7 — Dùng `localhost` thay vì tên service

```bash
cd ~/Downloads/quickbite-demo/quickbite-backend
```
```bash
cp .env .env.backup && sed -i '' 's/^DB_HOST=.*/DB_HOST=localhost/' .env
```
```bash
docker compose down && docker compose up -d && sleep 18
```
```bash
docker compose logs quickbite-user | grep "Caused by" | tail -2
```

**Sẽ thấy:**
```
Caused by: org.postgresql.util.PSQLException: Connection to localhost:5432 refused.
Caused by: java.net.ConnectException: Connection refused
```

**Vì sao:** bên trong container, `localhost` trỏ vào **chính container đó**, không phải máy thật và cũng không phải container database. Mỗi container có không gian mạng riêng.

**Khôi phục:**
```bash
cp .env.backup .env && rm .env.backup && docker compose up -d --force-recreate
```

---

## 🧪 Thí nghiệm 8 — Sai mật khẩu database

```bash
cd ~/Downloads/quickbite-demo/quickbite-backend
```
```bash
cp .env .env.backup && sed -i '' 's/^USER_DB_PASSWORD=.*/USER_DB_PASSWORD=sai_mat_khau/' .env
```
```bash
docker compose down && docker compose up -d && sleep 18
```
```bash
docker compose logs quickbite-user | grep "Caused by" | tail -1
```

**Sẽ thấy:**
```
Caused by: org.postgresql.util.PSQLException: FATAL: password authentication failed for user "quickbite_user"
```

**Vì sao hữu ích:** thông báo nói rõ **user nào** bị từ chối → biết ngay phải sửa biến nào trong `.env`.

> 💡 **Cách đọc log Java:** luôn đọc dòng `Caused by:` **cuối cùng** — đó mới là nguyên nhân gốc. Các dòng trên chỉ là vỏ bọc của Spring.

**Khôi phục:**
```bash
cp .env.backup .env && rm .env.backup && docker compose down && docker compose up -d
```

---

## 🧪 Thí nghiệm 9 — Trùng cổng

```bash
docker run -d --name chiem-cong -p 8081:80 nginx:alpine
```
```bash
cd ~/Downloads/quickbite-demo/quickbite-backend && docker compose up -d --force-recreate
```

**Sẽ thấy:**
```
Bind for 0.0.0.0:8081 failed: port is already allocated
```

**Vì sao:** hai container **có thể** cùng nghe cổng 8081 *bên trong* (mỗi cái có không gian mạng riêng), nhưng **không thể** cùng chiếm cổng 8081 trên máy thật.

**Sửa:**
```bash
docker rm -f chiem-cong && docker compose up -d
```

**Cách tìm thủ phạm khi gặp lỗi này ngoài đời:**
```bash
lsof -i :8081
```
```powershell
netstat -ano | findstr :8081
```

---

## 🧪 Thí nghiệm 10 — Quên cờ `--build`

```bash
cd ~/Downloads/quickbite-demo/quickbite-backend/user-service
```

Sửa một chuỗi trong code:
```bash
sed -i '' 's/"service", "user-service"/"service", "user-service-DA-SUA"/' src/main/java/com/quickbite/user/UserController.java
```
```bash
./gradlew bootJar
```

Chạy lại **không có** `--build`:
```bash
cd ~/Downloads/quickbite-demo/quickbite-backend && docker compose up -d
```
```bash
sleep 12 && curl -s http://localhost:8081/api/info
```
**Sẽ thấy:** vẫn là `"service":"user-service"` → **thay đổi chưa vào**

Giờ thêm `--build`:
```bash
docker compose up -d --build
```
```bash
sleep 12 && curl -s http://localhost:8081/api/info
```
**Phải thấy:** `"service":"user-service-DA-SUA"` → **đã vào**

**Vì sao:** Compose thấy image đã tồn tại thì dùng lại luôn, không tự build lại. Cờ `--build` ép nó đóng gói lại.

**Khôi phục:**
```bash
cd ~/Downloads/quickbite-demo/quickbite-backend/user-service
```
```bash
sed -i '' 's/"service", "user-service-DA-SUA"/"service", "user-service"/' src/main/java/com/quickbite/user/UserController.java && ./gradlew bootJar
```
```bash
cd ~/Downloads/quickbite-demo/quickbite-backend && docker compose up -d --build
```

---

# BÀI 6 — VÒNG ĐỜI & AN TOÀN DỮ LIỆU

### 6.1 · Các lệnh điều khiển

| Lệnh | Tác dụng |
|---|---|
| `docker compose up -d` | Bật cụm, chạy nền. Đọc lại file YAML |
| `docker compose start` | Bật lại container đã dừng. **KHÔNG đọc lại YAML** |
| `docker compose stop` | Tạm dừng, giữ nguyên container |
| `docker compose restart` | = stop + start |
| `docker compose down` | Xoá container + mạng. **GIỮ dữ liệu** |
| `docker compose down -v` | Xoá container + mạng + **dữ liệu** ⚠️ |

> 💡 Sửa file YAML rồi gõ `start` → **không có tác dụng**. Phải dùng `up`.

### 6.2 · ⚠️ Bảng an toàn dữ liệu — HỌC THUỘC

| Lệnh | Container | Mạng | **Dữ liệu database** |
|---|---|---|---|
| `docker compose stop` | Giữ (Exited) | Giữ | **Giữ** ✅ |
| `docker compose down` | Xoá | Xoá | **GIỮ** ✅ |
| `docker compose down -v` | Xoá | Xoá | **XOÁ SẠCH** ⚠️ |

---

## 🧪 Thí nghiệm 11 — `down` giữ dữ liệu, `down -v` xoá sạch

Đếm số bản ghi hiện có:

```bash
curl -s http://localhost:8081/api/users
```
**Phải thấy:** 3 bản ghi

Chạy `down` (**không** có `-v`):

```bash
cd ~/Downloads/quickbite-demo/quickbite-db
```
```bash
docker compose down && docker compose up -d && sleep 10
```
```bash
docker compose exec quickbite-db psql -U quickbite_user -d quickbite_user_db -c "SELECT COUNT(*) FROM users;"
```
**Phải thấy:** `count` = `3` → **dữ liệu còn nguyên** ✅

Giờ chạy `down -v`:

```bash
docker compose down -v && docker compose up -d && sleep 10
```
```bash
docker compose exec quickbite-db psql -U quickbite_user -d quickbite_user_db -c "SELECT COUNT(*) FROM users;"
```
**Sẽ thấy:**
```
ERROR:  relation "users" does not exist
```
→ **dữ liệu đã mất sạch** ⚠️

**Vì sao:** `down` chỉ xoá container và mạng; named volume vẫn còn. Cờ `-v` xoá luôn volume — **không hoàn tác được, không có thùng rác**.

> 👉 Đây chính là lý do project tách Database ra **stack riêng**: lỡ gõ `down -v` ở stack backend cũng **không chạm được** vào dữ liệu.

**Khôi phục về trạng thái đủ dữ liệu:**
```bash
cd ~/Downloads/quickbite-demo && ./start-all.sh
```
```bash
curl -s http://localhost:8081/api/users
```
**Phải thấy:** 3 bản ghi trở lại

> ⚠️ **Điểm rất dễ vấp — đọc kỹ:**
> Sau khi xoá database bằng `down -v`, **chỉ bật lại stack database là KHÔNG ĐỦ**.
>
> Bảng `users` và 3 bản ghi mẫu do **ứng dụng Spring Boot** tạo ra (qua `schema.sql` và `data.sql`) **lúc nó khởi động**. Nếu container app vẫn đang chạy từ trước, nó không khởi động lại nên không tạo lại bảng → bạn sẽ thấy mãi lỗi `relation "users" does not exist`.
>
> Vì vậy phải **tạo lại container app**:
> ```bash
> cd ~/Downloads/quickbite-demo/quickbite-backend
> docker compose up -d --force-recreate
> ```
> Script `./start-all.sh` đã làm sẵn việc này cho bạn — cứ dùng script là an toàn.

---

## 🧪 Thí nghiệm 12 — YAML dùng phím Tab

```bash
printf 'services:\n\tweb:\n\t\timage: nginx\n' > /tmp/thu-tab.yml
```
```bash
cd /tmp && docker compose -f thu-tab.yml config
```

**Sẽ thấy:**
```
found character that cannot start any token
```

**Vì sao:** chuẩn YAML **cấm tuyệt đối** ký tự Tab. Phải thụt lề bằng dấu cách, thống nhất 2 space mỗi cấp.

> 💡 Bật `"editor.renderWhitespace": "all"` trong VS Code để **nhìn thấy** dấu cách và Tab.

```bash
rm /tmp/thu-tab.yml
```

---

# BÀI 7 — TÌM LỖI

**Nguyên tắc: không đoán mò. Thu hẹp phạm vi theo thứ tự.**

### Bước 1 — Container còn sống không?

```bash
docker compose ps
```

| STATUS | Nghĩa là |
|---|---|
| `Up 2 minutes` | Đang chạy bình thường ✅ |
| `Exited (1)` | Đã crash → sang bước 2 ❌ |
| `Restarting` lặp lại | Crash liên tục khi khởi động ❌ |

### Bước 2 — App báo lỗi gì?

```bash
docker compose logs --tail=100 quickbite-user
```
```bash
docker compose logs quickbite-user | grep "Caused by" | tail -2
```

> Đọc dòng `Caused by:` **cuối cùng** — đó mới là nguyên nhân gốc.

### Bước 3 — Cấu hình thực tế là gì?

```bash
docker compose config
```
```bash
docker compose exec quickbite-user env | grep DB_
```

### Bước 4 — Mạng có thông không?

```bash
docker network inspect quickbite-net
```
```bash
docker compose exec quickbite-user ping -c 3 quickbite-db
```

> Ping fail → lỗi mạng. Ping OK mà app vẫn lỗi → lỗi cổng hoặc mật khẩu.

### Bước 5 — Database ổn không?

```bash
docker exec quickbite-db pg_isready -U postgres
```
```bash
docker compose exec quickbite-db psql -U postgres -c "\l"
```

### Bước 6 — Vào hẳn trong container xem

```bash
docker compose exec quickbite-user sh
```
Bên trong gõ:
```sh
ls -la /app
env | grep DB
exit
```

> Dùng `sh` chứ không phải `bash` — image Alpine không có bash.

---

# PHỤ LỤC 1 · RESET KHI HỎNG

### Reset mềm — tắt bật lại, giữ dữ liệu

```bash
cd ~/Downloads/quickbite-demo && ./stop-all.sh && ./start-all.sh
```

### Reset cứng — xoá sạch, dựng lại từ đầu

```bash
cd ~/Downloads/quickbite-demo && ./reset-demo.sh
```
Gõ `yes` khi được hỏi. Sau đó:
```bash
cd ~/Downloads/quickbite-demo && ./start-all.sh
```

### Kiểm tra lại

```bash
cd ~/Downloads/quickbite-demo && ./check.sh
```
**Phải thấy:** `KET QUA: 11 pass / 0 fail`

### Nếu vẫn hỏng — dựng lại hoàn toàn

```bash
cd ~/Downloads/quickbite-demo && ./reset-demo.sh
```
```bash
cd ~/Downloads/quickbite-demo && ./build-jar.sh
```
```bash
cd ~/Downloads/quickbite-demo && ./start-all.sh && ./check.sh
```

> ⚠️ **Nhớ:** các script này chỉ chạy được ở **thư mục gốc**. Đứng ở thư mục con thì dùng đường dẫn đầy đủ:
> ```bash
> ~/Downloads/quickbite-demo/check.sh
> ```

---

# PHỤ LỤC 2 · BẢNG TRA NHANH

### Lệnh Docker — giống nhau trên mọi hệ điều hành

| Việc | Lệnh |
|---|---|
| Kiểm tra file compose có lỗi không | `docker compose config` |
| Bật cụm chạy nền | `docker compose up -d` |
| Bật cụm + build lại image | `docker compose up -d --build` |
| Xem trạng thái | `docker compose ps` |
| Xem log realtime | `docker compose logs -f --tail=50` |
| Xem log 1 service | `docker compose logs -f quickbite-user` |
| Tìm nguyên nhân gốc trong log | `docker compose logs quickbite-user \| grep "Caused by" \| tail -2` |
| Chạy lệnh trong container | `docker compose exec <service> <lệnh>` |
| Vào shell container | `docker compose exec <service> sh` |
| Xem biến môi trường thật | `docker compose exec <service> env` |
| Tạm dừng | `docker compose stop` |
| Xoá container, **giữ dữ liệu** | `docker compose down` |
| Xoá tất cả + **dữ liệu** ⚠️ | `docker compose down -v` |
| Postgres sẵn sàng chưa | `docker exec quickbite-db pg_isready -U postgres` |
| Liệt kê database | `docker compose exec quickbite-db psql -U postgres -c "\l"` |
| Xem mạng ảo | `docker network ls` |
| Xem ai trong mạng | `docker network inspect quickbite-net` |
| Dung lượng Docker chiếm | `docker system df` |

### Script — chỉ chạy ở thư mục gốc

| Script | Tác dụng |
|---|---|
| `./start-all.sh` | Bật đúng thứ tự (DB trước, backend sau) |
| `./stop-all.sh` | Tắt đúng thứ tự ngược lại |
| `./check.sh` | Kiểm tra 11 mục |
| `./reset-demo.sh` | Xoá sạch làm lại (có hỏi xác nhận) |
| `./build-jar.sh` | Build JAR không cần cài JDK |

---

# PHỤ LỤC 3 · BẢNG LỖI

### 12 thí nghiệm lỗi trong tài liệu này

| # | Thông báo | Nguyên nhân | Sửa |
|---|---|---|---|
| 1 | `no configuration file provided: not found` | Đứng ở thư mục gốc | `cd` vào thư mục con |
| 2 | `"/build/libs/...jar": not found` | Sai tên JAR trong `COPY` | Sửa Dockerfile cho khớp tên thật |
| 3 | `Connection refused` khi curl | Thiếu cờ `-p` | Thêm `-p 8081:8081` |
| 4 | Sửa `init-db.sql` không tác dụng | Script chỉ chạy khi volume rỗng | `down -v` rồi `up -d` |
| 5 | `variable is not set. Defaulting to a blank string` | Thiếu biến trong `.env` | Thêm biến vào `.env` |
| 6 | `network ... could not be found` | Chạy backend trước database | Bật stack DB trước |
| 7 | `Connection to localhost:5432 refused` | Dùng `localhost` thay tên service | `DB_HOST=quickbite-db` |
| 8 | `FATAL: password authentication failed` | Sai mật khẩu trong `.env` | Sửa `USER_DB_PASSWORD` |
| 9 | `port is already allocated` | Cổng đã bị chiếm | `lsof -i :8081` rồi tắt, hoặc đổi port |
| 10 | Sửa code không thấy đổi | Quên `bootJar` hoặc `--build` | `./gradlew bootJar && docker compose up -d --build` |
| 11 | `relation "users" does not exist` | Đã chạy `down -v`, và container app cũ chưa được tạo lại nên chưa chạy lại `schema.sql` | `./start-all.sh` (đã có `--force-recreate`) |
| 12 | `found character that cannot start any token` | YAML dùng phím Tab | Thay Tab bằng 2 dấu cách |

### Lỗi riêng theo hệ điều hành

| Hệ | Triệu chứng | Sửa |
|---|---|---|
| macOS | `no matching manifest for linux/arm64/v8` | Thêm `platform: linux/amd64` |
| macOS | Cổng 5432 bận | `lsof -i :5432` rồi `kill -9 <pid>` |
| Ubuntu | `permission denied ... docker daemon` | `sudo usermod -aG docker $USER && newgrp docker` |
| Ubuntu | `'compose' is not a docker command` | `sudo apt-get install -y docker-compose-plugin` |
| Ubuntu | Cổng 5432 bận | `sudo systemctl stop postgresql` |
| Windows | `curl` ra kết quả lạ | Dùng `curl.exe` |
| Windows | `./x.sh` báo `bad interpreter` | `sed -i 's/\r$//' *.sh` |
| Windows | `gradlew: command not found` | Dùng `.\gradlew.bat bootJar` |
| Windows | `WSL 2 installation is incomplete` | PowerShell (Admin): `wsl --install` rồi reboot |
| Git Bash | Lỗi đường dẫn khi chạy `psql` | Thêm `MSYS_NO_PATHCONV=1` vào đầu lệnh |
| Git Bash | Lệnh có `-it` bị treo | Bỏ `-it`, hoặc thêm `winpty` vào đầu |

---

# ✅ CHECKLIST

Đánh dấu khi bạn **tự làm được** và **giải thích được**:

- [ ] Biết thư mục gốc chạy script, thư mục con chạy `docker compose`
- [ ] `docker compose version` trả về v2.x
- [ ] Chạy được file compose tối giản, hiểu `exited with code 0` là thành công
- [ ] Giải thích được cả 5 dòng trong Dockerfile
- [ ] `./gradlew bootJar` (hoặc `./build-jar.sh`) tạo ra JAR
- [ ] `docker build` thành công, thấy image trong `docker images`
- [ ] **Thí nghiệm 3:** chứng minh được `EXPOSE` không mở cổng
- [ ] Stack database chạy, `pg_isready` báo `accepting connections`
- [ ] `psql -c "\l"` thấy `quickbite_user_db`
- [ ] **Thí nghiệm 4:** hiểu vì sao sửa `init-db.sql` phải `down -v`
- [ ] Hiểu vai trò `.env`, `.env.example`, `.gitignore`
- [ ] Stack backend chạy, `/actuator/health` trả `"db":{"status":"UP"`
- [ ] `ping quickbite-db` từ trong container thành công
- [ ] **Thí nghiệm 6:** hiểu vì sao DB phải lên trước
- [ ] **Thí nghiệm 7:** hiểu vì sao không dùng được `localhost`
- [ ] **Thí nghiệm 10:** hiểu vì sao cần `--build`
- [ ] **Thí nghiệm 11:** phân biệt `down` và `down -v`
- [ ] Biết 6 bước tìm lỗi ở BÀI 7
- [ ] Biết cách reset khi hỏng (Phụ lục 1)
