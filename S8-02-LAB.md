# LAB SESSION 08 — BẢNG LỆNH THỰC HÀNH
# Đóng gói Docker Image & Đẩy lên Registry

> **Repo demo:** <https://github.com/caotv1512/project-demo>
> Workflow `06` (build + push image) và `07` (pull + verify) đã chạy thật — mở tab **Actions** xem kết quả ngay.

> **Cách dùng:** làm tuần tự BÀI 1 → BÀI 7. Mỗi bài: **lệnh cần gõ** → **kết quả phải thấy** → **thí nghiệm gây lỗi**.

---

# A · CHUẨN BỊ

## A1. Buổi này khác buổi trước ở chỗ nào

| | Session 07 | **Session 08** |
|---|---|---|
| Sản phẩm cuối | File **JAR** | **Docker image** |
| Nơi lưu | **Artifact** (3–7 ngày rồi tự xoá) | **Registry** GHCR (lâu dài) |
| Lấy về bằng | Bấm nút tải trên web | `docker pull` |
| Chạy được ngay? | **Không** — máy đích phải có Java | **Có** — Java nằm trong image |
| Đánh phiên bản | Không có chuẩn | **Tag** và **digest** |

> **Câu chốt:** Session 07 trả lời *"code có chạy được không?"*. Session 08 trả lời *"làm sao giao thứ chạy được đó cho người khác?"*

## A2. Cần gì trước khi bắt đầu

| Yêu cầu | Kiểm tra bằng |
|---|---|
| Docker Desktop đang chạy | `docker --version` |
| Tài khoản GitHub | — |
| **PAT classic** có quyền `read:packages` + `write:packages` | Tạo ở bước A4 |
| Repo đã clone về máy | `cd ~/Downloads/quickbite-demo` |

```bash
docker --version
```
**Phải thấy:** `Docker version 2x.x.x`

> ⚠️ **Nếu báo `Cannot connect to the Docker daemon`** thì Docker Desktop chưa bật. Mở Docker Desktop, đợi icon cá voi hết nhấp nháy rồi thử lại.

## A3. Cấu trúc thư mục liên quan

```
quickbite-demo/
├── .github/workflows/
│   ├── 06-build-va-push-image.yml     ← build image trong CI, push GHCR
│   └── 07-pull-va-verify-image.yml    ← pull về, chạy thử, health check
│
└── quickbite-backend/user-service/
    ├── Dockerfile                      ← MULTI-STAGE (bài này)
    ├── Dockerfile.single               ← bản đơn tầng cũ, để đối chiếu
    ├── .dockerignore
    ├── build.gradle  gradlew  gradle/
    └── src/
```

## A4. Tạo Personal Access Token (làm một lần)

1. Vào <https://github.com/settings/tokens> → **Generate new token (classic)**
2. Note: `docker-ghcr-lab`
3. Expiration: 30 days
4. Tick đúng **2 quyền**: `write:packages` và `read:packages`
5. **Generate token** → **copy ngay** (chỉ hiện một lần)

> ⚠️ **Ba điều tuyệt đối không làm với token:**
> 1. Không dán vào Dockerfile, YAML, `.env` bị commit, ảnh slide hay log
> 2. Không dùng mật khẩu tài khoản GitHub thay cho token
> 3. Không gõ token thẳng vào lệnh (`-p <token>`) — nó lưu vào lịch sử shell

## A5. Lệnh theo hệ điều hành

| Việc | macOS · Ubuntu · Git Bash | Windows PowerShell |
|---|---|---|
| Đặt biến môi trường | `export CR_PAT='...'` | `$env:CR_PAT='...'` |
| Đăng nhập an toàn | `printf '%s' "$CR_PAT" \| docker login ghcr.io -u <user> --password-stdin` | `$env:CR_PAT \| docker login ghcr.io -u <user> --password-stdin` |
| Lọc chữ | `… \| grep x` | `… \| Select-String x` |
| Gọi API | `curl -s <url>` | `curl.exe -s <url>` |

---

# BÀI 1 — DOCKERFILE MULTI-STAGE

**Mục tiêu:** hiểu vì sao tách hai tầng, và chứng minh image cuối không chứa mã nguồn.

```bash
cd ~/Downloads/quickbite-demo/quickbite-backend/user-service
```

## 1.1 · So sánh hai bản Dockerfile

```bash
cat Dockerfile.single
```
**Bản đơn tầng (Session 04)** — cần file JAR **có sẵn** trên máy:
```dockerfile
FROM eclipse-temurin:17-jre-alpine
COPY build/libs/user-service.jar app.jar     ← giả định JAR đã tồn tại
```

```bash
cat Dockerfile
```
**Bản multi-stage (Session 08)** — tự biên dịch bên trong:
```dockerfile
FROM eclipse-temurin:17-jdk-alpine AS builder   ← tầng 1: JDK để build
...
RUN ./gradlew bootJar --no-daemon

FROM eclipse-temurin:17-jre-alpine AS runtime    ← tầng 2: JRE để chạy
COPY --from=builder /app/build/libs/user-service.jar app.jar
```

| Điểm khác | Đơn tầng | Multi-stage |
|---|---|---|
| Cần build JAR trước? | **Có** | **Không** |
| Base image | JRE | JDK (tầng 1) + JRE (tầng 2) |
| Image cuối chứa mã nguồn? | Không | Không |
| Tự chứa toàn bộ quy trình? | Không | **Có** |

## 1.2 · Build bản multi-stage

```bash
cd ~/Downloads/quickbite-demo/quickbite-backend/user-service
```
```bash
docker build -t user-service:1.0.0 .
```
```bash
docker build --platform linux/amd64 -t user-service:1.0.0 .
```
> 🍎 Dòng thứ hai dành cho Mac Apple Silicon — base image `eclipse-temurin:17-*-alpine` không có bản ARM.

**Phải thấy:** các bước `[builder 1/7]` … `[runtime 2/2]` rồi `naming to docker.io/library/user-service:1.0.0 done`

> 💡 **Lần đầu mất 2–4 phút** vì phải tải thư viện Gradle. Lần sau nhanh hơn nhiều nhờ cache layer.

## 1.3 · Chứng minh image cuối sạch

```bash
docker images user-service
```

```bash
docker history user-service:1.0.0
```
**Phải thấy:** lịch sử layer **không hề có** bước `./gradlew bootJar` hay `COPY src`. Chúng nằm ở tầng builder đã bị vứt.

Vào hẳn trong image xem:
```bash
docker run --rm user-service:1.0.0 sh -c "ls -la /app"
```
**Phải thấy:** chỉ có `app.jar` — không có `src/`, không có `gradlew`, không có `build.gradle`

```bash
docker run --rm user-service:1.0.0 sh -c "which javac || echo 'KHONG co javac - dung nhu mong doi'"
```
**Phải thấy:** `KHONG co javac` → image chỉ có JRE, không có trình biên dịch

> 💡 **Đây mới là lợi ích lớn nhất của multi-stage** — không phải dung lượng, mà là **bề mặt tấn công**. Kẻ xâm nhập được vào container cũng không có công cụ gì để biên dịch thêm.

---

## 🧪 Thí nghiệm 1 — So sánh dung lượng hai bản

```bash
cd ~/Downloads/quickbite-demo/quickbite-backend/user-service
```

Bản đơn tầng cần JAR sẵn, nên phải build JAR trước:
```bash
./gradlew bootJar
```
```bash
docker build -f Dockerfile.single -t user-service:single .
```
```bash
docker images user-service
```

**Lập bảng ghi lại:**

| Tag | Dung lượng | Cần build JAR trước? |
|---|---|---|
| `single` | ? | Có |
| `1.0.0` (multi) | ? | Không |

> 💡 **Đừng chỉ nhìn con số.** Hai bản có thể xấp xỉ nhau vì cùng dùng `jre-alpine` làm tầng cuối. **Điều đáng nói là bản multi-stage tự biên dịch được** — không phụ thuộc vào việc bạn đã chạy `./gradlew bootJar` hay chưa.

---

## 🧪 Thí nghiệm 2 — Thứ tự layer quyết định tốc độ build

Sửa một dòng trong mã nguồn rồi build lại, đo thời gian:

```bash
echo "// thu $(date +%H:%M:%S)" >> src/main/java/com/quickbite/user/WalletRules.java
```
```bash
time docker build -t user-service:1.0.0 .
```

**Phải thấy:** các bước `COPY gradlew`, `COPY build.gradle`, `RUN ./gradlew dependencies` đều hiện **`CACHED`** — chỉ `COPY src` và `bootJar` chạy lại.

**Vì sao:** Dockerfile chép file **ít thay đổi trước**, mã nguồn **sau cùng**:
```dockerfile
COPY build.gradle settings.gradle ./
RUN ./gradlew dependencies --no-daemon    ← layer này được TÁI DÙNG
COPY src ./src                            ← đổi liên tục, để cuối
RUN ./gradlew bootJar --no-daemon
```

**Giờ thử làm sai.** Tạo bản Dockerfile đảo thứ tự:

```bash
sed 's|COPY gradlew ./|COPY . .|; /COPY gradle \.\/gradle/d; /COPY build.gradle settings.gradle/d; /COPY src \.\/src/d' Dockerfile > Dockerfile.sai
```
```bash
docker build -f Dockerfile.sai -t user-service:sai . && echo "--- lan 2 ---"
```
```bash
echo "// thu lai $(date +%H:%M:%S)" >> src/main/java/com/quickbite/user/WalletRules.java
```
```bash
time docker build -f Dockerfile.sai -t user-service:sai .
```

**Sẽ thấy:** bước `./gradlew dependencies` **không** hiện `CACHED` — phải tải lại toàn bộ thư viện.

**Vì sao:** `COPY . .` gộp hết vào một layer. Sửa một dấu chấm phẩy trong Java cũng làm layer đó đổi → **mọi layer phía sau phải làm lại**.

**Dọn dẹp:**
```bash
rm Dockerfile.sai && docker rmi -f user-service:sai
```

> 💡 **Nguyên tắc áp dụng cho mọi ngôn ngữ:** chép file ít thay đổi trước, file thay đổi nhiều sau. Node.js thì `package.json` trước `src/`. Python thì `requirements.txt` trước code.

---

# BÀI 2 — ĐẨY IMAGE LÊN GHCR TỪ MÁY

**Mục tiêu:** hiểu quy trình login → tag → push bằng tay, trước khi để CI làm hộ.

## 2.1 · Đăng nhập GHCR

```bash
export CR_PAT='<dán token PAT vào đây>'
```
```bash
printf '%s' "$CR_PAT" | docker login ghcr.io -u caotv1512 --password-stdin
```
```powershell
$env:CR_PAT | docker login ghcr.io -u caotv1512 --password-stdin
```

**Phải thấy:** `Login Succeeded`

> **Vì sao dùng `--password-stdin`:** gõ `-p <token>` sẽ lưu token vào lịch sử shell (`~/.zsh_history`). Ai đọc được file đó là lấy được token.

## 2.2 · Gắn tag theo chuẩn Registry

```bash
docker tag user-service:1.0.0 ghcr.io/caotv1512/user-service:1.0.0
```
```bash
docker images | grep user-service
```

**Đọc cấu trúc tên:**
```
ghcr.io / caotv1512 / user-service : 1.0.0
└──┬──┘   └───┬───┘   └─────┬────┘   └─┬─┘
registry   namespace    tên image     tag
```

> ⚠️ **Tên image bắt buộc viết thường toàn bộ.** Có chữ hoa là GHCR từ chối với lỗi `invalid reference format`.

## 2.3 · Đẩy lên

```bash
docker push ghcr.io/caotv1512/user-service:1.0.0
```

**Phải thấy:** các layer được đẩy lên, kết thúc bằng dòng có **`digest: sha256:...`**

> 💡 **Ghi lại chuỗi digest đó.** Đây là bằng chứng xác thực duy nhất cho nội dung image. Tag có thể bị ghi đè, digest thì không.

## 2.4 · Xác nhận trên GitHub

Vào <https://github.com/caotv1512?tab=packages>

**Phải thấy:** package `user-service` với tag `1.0.0`

```bash
docker pull ghcr.io/caotv1512/user-service:1.0.0
```
**Phải thấy:** `Status: Image is up to date` → image thật sự nằm trên Registry

---

## 🧪 Thí nghiệm 3 — Tên image có chữ hoa

```bash
docker tag user-service:1.0.0 ghcr.io/CaoTV1512/user-service:1.0.0
```

**Sẽ thấy:**
```
invalid reference format: repository name must be lowercase
```

**Vì sao:** chuẩn Docker quy định tên repository **chỉ dùng chữ thường**, số, dấu gạch ngang, gạch dưới và dấu chấm.

> 💡 Trong workflow, luôn chuyển tên về chữ thường cho chắc:
> ```bash
> TEN=$(echo "$IMAGE_NAME" | tr '[:upper:]' '[:lower:]')
> ```
> Vì `github.repository_owner` giữ nguyên chữ hoa như bạn đăng ký tài khoản.

---

## 🧪 Thí nghiệm 4 — `latest` bị ghi đè lặng lẽ

Gắn thêm nhãn `latest` rồi push:

```bash
docker tag user-service:1.0.0 ghcr.io/caotv1512/user-service:latest
```
```bash
docker push ghcr.io/caotv1512/user-service:latest
```

Giờ sửa code rồi build và push đè lên `latest`:

```bash
echo "// ban moi $(date +%H:%M:%S)" >> src/main/java/com/quickbite/user/WalletRules.java
```
```bash
docker build -t ghcr.io/caotv1512/user-service:latest .
```
```bash
docker push ghcr.io/caotv1512/user-service:latest
```

**Sẽ thấy:** push thành công, **không có cảnh báo gì cả**. Nhãn `latest` giờ trỏ sang nội dung mới.

**Hậu quả nếu đây là production:**

| Tình huống | Chuyện gì xảy ra |
|---|---|
| Máy chủ restart | Tự động lấy **bản mới** dù không ai yêu cầu |
| Cần quay về bản cũ | **Không có cách nào** — không nhãn nào còn trỏ tới bản cũ |
| Hai máy pull cách nhau 1 giờ | **Chạy hai phiên bản khác nhau** mà không ai biết |

> ⚠️ **Quy tắc bắt buộc:** production **luôn** dùng tag cố định (`1.0.0`) hoặc digest. `latest` chỉ dùng cho dev.

---

# BÀI 3 — BUILD IMAGE TRONG CI

**Mục tiêu:** để CI build thay vì build ở máy — đảm bảo image khớp đúng commit.

## 3.1 · Đọc workflow

```bash
cat ~/Downloads/quickbite-demo/.github/workflows/06-build-va-push-image.yml
```

Ba điểm cần giải thích:

**① Quyền tối thiểu**
```yaml
permissions:
  contents: read      # để checkout
  packages: write     # để push image
```
Không cần PAT — `GITHUB_TOKEN` được sinh **tự động theo từng job**.

**② Ba nhãn cho cùng một image**
```
1.0.0          → nhãn phát hành, người đọc hiểu ngay
sha-a1b2c3d    → truy vết chính xác commit, KHÔNG bao giờ bị ghi đè
latest         → tiện nhưng nguy hiểm (xem Thí nghiệm 4)
```

**③ Cache layer giữa các lần chạy**
```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
```
Máy ảo mới tinh mỗi lần nên không có cache sẵn. Dòng này lưu cache vào kho của GitHub Actions.

## 3.2 · Chạy workflow

1. Vào <https://github.com/caotv1512/project-demo/actions>
2. Chọn **06 · Build image và đẩy lên GHCR** → **Run workflow**
3. Nhập số phiên bản (mặc định `1.0.0`) → **Run workflow**

**Phải thấy:** job chạy qua các bước checkout → login → build → push, kết thúc ✅

Cuộn xuống cuối trang lần chạy:

**Phải thấy** bảng tóm tắt có **Digest** — ghi lại con số này.

## 3.3 · Kiểm tra bằng dòng lệnh

```bash
curl -s "https://api.github.com/repos/caotv1512/project-demo/actions/runs?per_page=5" | grep -E '"name"|"conclusion"'
```

```bash
docker pull ghcr.io/caotv1512/user-service:latest
```
```bash
docker image inspect ghcr.io/caotv1512/user-service:latest --format '{{.Created}} | {{.Architecture}}'
```
**Phải thấy:** thời điểm tạo là vài phút trước — **do CI build, không phải máy bạn**

---

## 🧪 Thí nghiệm 5 — Thiếu quyền `packages: write`

Sửa tạm workflow để bỏ quyền ghi:

```bash
cd ~/Downloads/quickbite-demo
```
```bash
cp .github/workflows/06-build-va-push-image.yml /tmp/06.bak
```
```bash
sed -i '' 's/      packages: write/      packages: read/' .github/workflows/06-build-va-push-image.yml
```
```bash
git add -A && git commit -q -m "test: bo quyen ghi packages" && git push
```

Chạy lại workflow 06.

**Sẽ thấy trong log:**
```
denied: permission_denied: write_package
```

**Vì sao:** `GITHUB_TOKEN` chỉ có đúng quyền bạn khai báo trong `permissions`. Đây là **tính năng bảo mật**, không phải lỗi — token bị rò rỉ cũng không làm được gì ngoài phạm vi đã cho.

**Khôi phục:**
```bash
cp /tmp/06.bak .github/workflows/06-build-va-push-image.yml && rm /tmp/06.bak
```
```bash
git add -A && git commit -q -m "revert: tra lai quyen ghi packages" && git push
```

---

# BÀI 4 — PULL IMAGE VỀ VÀ KIỂM CHỨNG

**Mục tiêu:** chứng minh image **dùng được**, không chỉ tải về được.

## 4.1 · Đọc workflow

```bash
cat ~/Downloads/quickbite-demo/.github/workflows/07-pull-va-verify-image.yml
```

**Điểm đáng chú ý — service container:**
```yaml
services:
  postgres:
    image: postgres:15-alpine
    env:
      POSTGRES_USER: quickbite_user
      POSTGRES_PASSWORD: quickbite_user
      POSTGRES_DB: quickbite_user_db
    ports: [5432:5432]
    options: >-
      --health-cmd "pg_isready -U quickbite_user"
      --health-interval 5s
      --health-retries 10
```

GitHub dựng sẵn PostgreSQL **trước khi** step đầu tiên chạy, và đợi tới khi nó thật sự nhận kết nối.

> 💡 **Đây là cách chuẩn để test ứng dụng cần database trên CI.** Không phải cài Postgres bằng tay trong step.

## 4.2 · Chạy workflow

Vào Actions → **07 · Pull image và kiểm tra** → **Run workflow** → để nhãn `latest` → Run.

**Phải thấy trong log:**
```
--- Lịch sử layer (chứng minh multi-stage đã bỏ JDK và mã nguồn) ---
...
Đợi tối đa 60 giây cho Spring Boot khởi động...
  lần 1/12 — chưa sẵn sàng, đợi 5 giây...
  lần 2/12 — chưa sẵn sàng, đợi 5 giây...
✅ Ứng dụng đã sẵn sàng sau 15 giây
{"status":"UP",...}
```

và

```
--- GET /api/users ---
[{"id":1,"full_name":"Nguyen Van An",...
```

> 💡 **Đây mới là bằng chứng đầy đủ:** image pull về được, chạy được, kết nối được database, và trả về dữ liệu thật.

## 4.3 · Chạy thử ở máy để đối chiếu

```bash
docker run -d --name thu-image -p 8091:8081 \
  -e DB_HOST=host.docker.internal \
  ghcr.io/caotv1512/user-service:latest
```
```bash
sleep 20 && docker logs thu-image | grep -E "Started|Caused by" | tail -3
```
```bash
docker rm -f thu-image
```

> Nếu máy chưa có PostgreSQL chạy ở cổng 5432 thì app sẽ báo lỗi kết nối — **đó là đúng**, chứng minh image cần database thật.

---

## 🧪 Thí nghiệm 6 — Gọi health check ngay sau `docker run -d`

```bash
docker run -d --name thu-voi -p 8092:8081 ghcr.io/caotv1512/user-service:latest
```
```bash
curl -m 3 http://localhost:8092/actuator/health
```

**Sẽ thấy:** `Connection refused` hoặc `Empty reply from server`

**Vì sao:** `docker run -d` trả về **ngay lập tức** — nó chỉ báo "container đã được tạo", không phải "ứng dụng đã sẵn sàng". Spring Boot cần thêm 10–20 giây.

Đợi rồi thử lại:
```bash
sleep 20 && curl -s http://localhost:8092/actuator/health | head -c 80; echo
```

**Dọn dẹp:**
```bash
docker rm -f thu-voi
```

> 💡 **Ba cách xử lý, từ tệ tới tốt:**
> | Cách | Vấn đề |
> |---|---|
> | `sleep 30` rồi curl | Máy nhanh thì phí 20 giây, máy chậm vẫn fail |
> | **Vòng lặp thử lại 12 lần × 5 giây** | **Tốt** — sẵn sàng lúc nào đi tiếp lúc đó |
> | `HEALTHCHECK` trong Dockerfile | Tốt nhất, để dành bài nâng cao |

---

## 🧪 Thí nghiệm 7 — Quên `if: always()` thì rác ở lại

Mô phỏng ở máy: chạy container rồi cố tình để lệnh sau thất bại.

```bash
docker run -d --name rac-lai ghcr.io/caotv1512/user-service:latest >/dev/null
```
```bash
curl --fail -m 3 http://localhost:9999/khong-ton-tai && docker rm -f rac-lai
```

**Sẽ thấy:** `curl` thất bại → `&&` không chạy → container **vẫn còn**

```bash
docker ps -a | grep rac-lai
```

**Vì sao nguy hiểm trên CI:** với self-hosted runner, container rác tích tụ dần cho tới khi **đầy đĩa**. Với GitHub-hosted thì máy ảo bị huỷ nên không sao — nhưng vẫn nên tập thói quen đúng.

**Cách đúng trong workflow:**
```yaml
- name: Dọn dẹp
  if: always()      # chạy kể cả khi bước trên thất bại
  run: docker rm -f kiem_tra_user_service || true
```

**Dọn dẹp:**
```bash
docker rm -f rac-lai
```

---

# BÀI 5 — TAG VÀ DIGEST

**Mục tiêu:** hiểu vì sao production không dùng `latest`.

## 5.1 · Xem digest của image

```bash
docker pull ghcr.io/caotv1512/user-service:latest
```
```bash
docker image inspect ghcr.io/caotv1512/user-service:latest --format '{{index .RepoDigests 0}}'
```

**Phải thấy:** `ghcr.io/caotv1512/user-service@sha256:...`

## 5.2 · Chứng minh nhiều tag cùng trỏ một digest

```bash
docker pull ghcr.io/caotv1512/user-service:1.0.0
```
```bash
docker images --digests | grep user-service
```

**Phải thấy:** `1.0.0` và `latest` có **cùng một digest** (nếu được push cùng lúc)

## 5.3 · Pull bằng digest

```bash
DIGEST=$(docker image inspect ghcr.io/caotv1512/user-service:latest --format '{{index .RepoDigests 0}}')
```
```bash
echo "$DIGEST"
```
```bash
docker pull "$DIGEST"
```

**Vì sao dùng digest:** tag có thể bị ghi đè bất cứ lúc nào. Digest là **vân tay của nội dung** — pull bằng digest thì chắc chắn lấy đúng thứ đã kiểm duyệt, không ai đổi được.

| | Tag | Digest |
|---|---|---|
| Ai đặt | Con người | Máy tự tính từ nội dung |
| Đổi được không | **Có** | **Không** |
| Dùng khi | Chọn bản để triển khai | **Chứng minh** đúng nội dung |

---

# BÀI 6 — TÌM LỖI

## Bước 1 — Image có trên Registry chưa?

```bash
docker pull ghcr.io/caotv1512/user-service:latest
```
Lỗi `unauthorized` → chưa login hoặc thiếu quyền `read:packages`
Lỗi `manifest unknown` → tag không tồn tại, kiểm tra lại tên và nhãn

## Bước 2 — Đang đăng nhập bằng tài khoản nào?

```bash
cat ~/.docker/config.json | grep -A2 ghcr
```
```bash
docker logout ghcr.io && printf '%s' "$CR_PAT" | docker login ghcr.io -u caotv1512 --password-stdin
```

## Bước 3 — Image build ra có đúng không?

```bash
docker history ghcr.io/caotv1512/user-service:latest --no-trunc | head -8
```
```bash
docker run --rm ghcr.io/caotv1512/user-service:latest sh -c "ls -la /app && java -version"
```

## Bước 4 — Container chạy được không?

```bash
docker run -d --name debug-img -p 8093:8081 ghcr.io/caotv1512/user-service:latest
```
```bash
sleep 20 && docker logs debug-img 2>&1 | grep -E "Started|Caused by" | tail -3
```
```bash
docker rm -f debug-img
```

## Bước 5 — Xem log CI

```bash
curl -s "https://api.github.com/repos/caotv1512/project-demo/actions/runs?per_page=5" | grep -E '"name"|"conclusion"'
```

Vào tab Actions → bấm job đỏ → mở rộng step sập → đọc dòng `Caused by:` **cuối cùng**.

---

# PHỤ LỤC 1 · BẢNG TRA NHANH

## Docker ở máy

| Việc | Lệnh |
|---|---|
| Build image multi-stage | `docker build -t user-service:1.0.0 .` |
| Build trên Mac Apple Silicon | `docker build --platform linux/amd64 -t user-service:1.0.0 .` |
| Xem danh sách image | `docker images user-service` |
| Xem lịch sử layer | `docker history user-service:1.0.0` |
| Xem bên trong image | `docker run --rm user-service:1.0.0 sh -c "ls -la /app"` |
| Xem digest | `docker image inspect <image> --format '{{index .RepoDigests 0}}'` |
| Xoá image | `docker rmi -f user-service:1.0.0` |

## Registry

| Việc | Lệnh |
|---|---|
| Đăng nhập GHCR | `printf '%s' "$CR_PAT" \| docker login ghcr.io -u <user> --password-stdin` |
| Đăng xuất | `docker logout ghcr.io` |
| Gắn tag | `docker tag user-service:1.0.0 ghcr.io/<ns>/user-service:1.0.0` |
| Đẩy lên | `docker push ghcr.io/<ns>/user-service:1.0.0` |
| Kéo về | `docker pull ghcr.io/<ns>/user-service:1.0.0` |
| Kéo bằng digest | `docker pull ghcr.io/<ns>/user-service@sha256:...` |

## Kiểm tra CI

| Việc | Lệnh |
|---|---|
| 5 lần chạy gần nhất | `curl -s ".../actions/runs?per_page=5" \| grep -E '"name"\|"conclusion"'` |
| Danh sách workflow | `curl -s ".../actions/workflows" \| grep '"name"'` |

## Trang web hay dùng

| Trang | Địa chỉ |
|---|---|
| Actions | `github.com/caotv1512/project-demo/actions` |
| Packages (image đã push) | `github.com/caotv1512?tab=packages` |
| Tạo PAT | `github.com/settings/tokens` |

---

# PHỤ LỤC 2 · BẢNG LỖI

## 7 thí nghiệm trong tài liệu này

| # | Triệu chứng | Nguyên nhân | Sửa |
|---|---|---|---|
| 1 | Hai image dung lượng xấp xỉ nhau | Cùng dùng `jre-alpine` làm tầng cuối | Không phải lỗi — giá trị nằm ở chỗ multi-stage **tự biên dịch** |
| 2 | Build lại vẫn tải lại thư viện | `COPY . .` quá sớm | Chép file cấu hình trước `src/` |
| 3 | `repository name must be lowercase` | Tên image có chữ hoa | `tr '[:upper:]' '[:lower:]'` |
| 4 | `latest` trỏ sang bản khác lúc nào không hay | Bản chất của `latest` | Dùng tag cố định cho production |
| 5 | `denied: permission_denied: write_package` | Thiếu `packages: write` | Thêm vào khối `permissions` |
| 6 | `Connection refused` ngay sau `docker run -d` | App chưa khởi động xong | Vòng lặp thử lại 12 × 5 giây |
| 7 | Container rác ở lại trên Runner | Thiếu `if: always()` | Thêm bước dọn có `if: always()` |

## Lỗi khác

| Triệu chứng | Sửa |
|---|---|
| `unauthorized` khi pull | Chưa login, hoặc thiếu `packages: read` |
| `manifest unknown` | Tag không tồn tại — kiểm tra lại tên và nhãn |
| `COPY --from` không tìm thấy file | Sai đường dẫn ở builder stage — kiểm tra `WORKDIR` |
| `no matching manifest for linux/arm64` | Mac Apple Silicon — thêm `--platform linux/amd64` |
| `Cannot connect to the Docker daemon` | Docker Desktop chưa bật |
| Image chạy sai phiên bản Java | Chỉ đổi base image một trong hai tầng — phải đổi **cả hai** |
| Windows: `curl` ra kết quả lạ | Dùng `curl.exe` |

---

# ✅ CHECKLIST

- [ ] Giải thích được Session 08 khác Session 07 ở sản phẩm cuối
- [ ] Phân biệt được Artifact và Registry
- [ ] Đọc hiểu Dockerfile multi-stage, chỉ ra được tầng nào dùng JDK, tầng nào JRE
- [ ] **Chứng minh** được image cuối không có mã nguồn và không có `javac`
- [ ] **Thí nghiệm 2:** giải thích được vì sao thứ tự `COPY` quyết định tốc độ build
- [ ] Tạo được PAT với đúng 2 quyền, login GHCR bằng `--password-stdin`
- [ ] Gắn tag đúng chuẩn `ghcr.io/<ns>/<ten>:<tag>` và push thành công
- [ ] Xem được image trên trang Packages của GitHub
- [ ] **Thí nghiệm 4:** giải thích được vì sao `latest` nguy hiểm ở production
- [ ] Chạy được workflow 06 build image trong CI và ghi lại digest
- [ ] **Thí nghiệm 5:** hiểu `permissions` giới hạn quyền của `GITHUB_TOKEN`
- [ ] Chạy được workflow 07 pull + verify, đọc được log health check
- [ ] **Thí nghiệm 6:** giải thích được vì sao cần vòng lặp chờ
- [ ] **Thí nghiệm 7:** hiểu tác dụng của `if: always()`
- [ ] Phân biệt được tag và digest, biết pull bằng digest
