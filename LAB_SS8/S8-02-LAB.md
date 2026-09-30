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

## A1b. 🎯 CAM KẾT CỦA BUỔI HỌC — đọc to cho cả lớp nghe

> **Hết buổi hôm nay, bạn sẽ làm được điều này:**
>
> Bạn build ứng dụng **một lần** trên máy bạn (hoặc trên CI). Sau đó **bất kỳ máy nào** — máy bạn cùng lớp, máy chưa từng cài Java, máy chưa từng thấy mã nguồn — chỉ cần chạy **hai lệnh** là ứng dụng lên:
>
> ```
> docker pull  ...
> docker run   ...
> ```

**Vì sao cam kết này quan trọng?** Hãy nhớ lại nỗi đau quen thuộc:

| Tình huống thật | Không có image | Có image |
|---|---|---|
| Bạn gửi code cho bạn cùng nhóm | "Máy tao báo lỗi Java version" | `docker run` — xong |
| Bàn giao cho đội vận hành | Gửi kèm 3 trang hướng dẫn cài đặt | Gửi **một dòng tên image** |
| Máy chủ mới cần chạy app | Cài JDK, cài Gradle, build 5 phút | `docker pull` rồi chạy |
| Sáu tháng sau cần chạy lại **đúng** bản đó | Gần như không thể | Pull theo **digest** — chính xác từng byte |

> **Câu nói kinh điển:** *"Máy tao chạy được mà"* — Docker image tồn tại để câu này không còn là lý do.

**Con đường của buổi học, và mỗi bài trả lời câu gì:**

| Bài | Câu hỏi bài đó trả lời | Đóng góp gì cho cam kết |
|---|---|---|
| **1** | Đóng gói app vào image thế nào cho gọn và sạch? | Có **thứ** để giao |
| **2** | Làm sao đưa image ra khỏi máy mình? | Có **chỗ** để người khác lấy |
| **3** | Ai build? Máy cá nhân hay máy chung? | Build **không phụ thuộc máy ai** |
| **4** | Làm sao biết image thật sự chạy được? | Có **bằng chứng**, không phải niềm tin |
| **5** | Làm sao chỉ đúng **một** bản không nhầm lẫn? | Giao đúng thứ **đã kiểm duyệt** |
| **6** | **Chứng minh cam kết trên máy trắng** | ✅ **Kết luận** |

> 📌 **Cuối BÀI 6 chúng ta sẽ quay lại đúng khung này và tick từng dòng.**

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
**Máy Windows · Linux · Mac Intel:**
```bash
docker build -t user-service:1.0.0 .
```

**Mac Apple Silicon (M1/M2/M3/M4) — BẮT BUỘC dùng dòng này:**
```bash
docker build --platform linux/amd64 -t user-service:1.0.0 .
```

> ⚠️ **Trên Mac Apple Silicon, dòng đầu KHÔNG chạy được** — nó dừng ngay với lỗi:
> ```
> ERROR: failed to solve: eclipse-temurin:17-jre-alpine:
> no match for platform in manifest: not found
> ```
> Vì `eclipse-temurin:17-jdk-alpine` và `17-jre-alpine` **không có bản ARM**. Cờ `--platform linux/amd64` buộc Docker lấy bản amd64 và chạy qua Rosetta.
>
> **Từ đây trở đi, mọi lệnh trong tài liệu đã có sẵn `--platform linux/amd64`.** Cứ chép nguyên, không cần sửa gì.
>
> **Máy Ubuntu / Windows / Mac Intel có cần cờ này không?** Không cần — nhưng **để nguyên vẫn đúng**, vì các máy đó *vốn đã là* amd64, cờ này chỉ nói lại điều máy đang có nên nó không làm gì cả. Nhờ vậy cả lớp dùng **chung một bảng lệnh**, không ai phải nhớ mình thuộc loại máy nào.

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
docker run --rm --entrypoint sh user-service:1.0.0 -c "ls -la /app"
```
**Phải thấy:** chỉ có `app.jar` — không có `src/`, không có `gradlew`, không có `build.gradle`

```bash
docker run --rm --entrypoint sh user-service:1.0.0 -c "which javac || echo 'KHONG co javac - dung nhu mong doi'"
```
**Phải thấy:** `KHONG co javac` → image chỉ có JRE, không có trình biên dịch

```bash
docker run --rm --entrypoint sh user-service:1.0.0 -c "ls /app/gradlew /app/src 2>/dev/null || echo 'KHONG co gradlew, KHONG co src'"
```
**Phải thấy:** `KHONG co gradlew, KHONG co src`

> ⚠️ **Vì sao bắt buộc có `--entrypoint sh`?**
> Dockerfile kết thúc bằng `ENTRYPOINT ["java", "-jar", "app.jar"]`. Mọi thứ bạn gõ sau tên image sẽ trở thành **tham số truyền cho `java -jar`**, chứ không phải lệnh mới.
>
> Viết `docker run user-service:1.0.0 sh -c "ls /app"` thì Docker chạy:
> ```
> java -jar app.jar sh -c "ls /app"
> ```
> → Spring Boot khởi động, `sh -c` bị bỏ qua. Bạn sẽ thấy logo Spring Boot chứ không thấy danh sách file.
>
> Cờ `--entrypoint sh` **thay thế** lệnh mặc định, khi đó `-c "..."` mới đến được shell.

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
docker build --platform linux/amd64 -f Dockerfile.single -t user-service:single .
```

> ⚠️ **Nếu gặp lỗi `"/build/libs/user-service.jar": not found`** dù `bootJar` đã thành công, hãy mở `.dockerignore` kiểm tra. File đó phải có dòng cho phép JAR lọt qua:
> ```gitignore
> build/
> !build/libs/*.jar
> ```
> Chặn cả `build/` thì Docker **không nhìn thấy** file JAR, dù nó nằm ngay trên đĩa. Đây là lỗi rất khó đoán vì `ls` thấy file mà Docker thì không.
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
time docker build --platform linux/amd64 -t user-service:1.0.0 .
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
docker build --platform linux/amd64 -f Dockerfile.sai -t user-service:sai . && echo "--- lan 2 ---"
```
```bash
echo "// thu lai $(date +%H:%M:%S)" >> src/main/java/com/quickbite/user/WalletRules.java
```
```bash
time docker build --platform linux/amd64 -f Dockerfile.sai -t user-service:sai .
```

**Sẽ thấy:** bước `./gradlew dependencies` **không** hiện `CACHED` — phải tải lại toàn bộ thư viện.

**Vì sao:** `COPY . .` gộp hết vào một layer. Sửa một dấu chấm phẩy trong Java cũng làm layer đó đổi → **mọi layer phía sau phải làm lại**.

**Dọn dẹp** — xoá Dockerfile tạm, xoá image tạm, **và trả lại file nguồn như ban đầu:**
```bash
rm Dockerfile.sai && docker rmi -f user-service:sai
```
```bash
git checkout -- src/main/java/com/quickbite/user/WalletRules.java && echo "Da hoan tac file nguon"
```

> ⚠️ **Đừng bỏ bước này.** Hai lệnh `echo ... >>` ở trên **ghi thêm dòng vào file nguồn thật**. Nếu không hoàn tác, mỗi lần dạy lại file lại dài thêm vài dòng rác, và `git status` luôn báo bẩn.
>
> Không dùng git? Mở file rồi xoá tay các dòng bắt đầu bằng `// thu` ở cuối file.

> 💡 **Nguyên tắc áp dụng cho mọi ngôn ngữ:** chép file ít thay đổi trước, file thay đổi nhiều sau. Node.js thì `package.json` trước `src/`. Python thì `requirements.txt` trước code.

---

## 🔍 GIẢI THÍCH TƯỜNG TẬN — BÀI 1

### Multi-stage thực chất là gì?

Một Dockerfile bình thường có **một** `FROM`. Multi-stage có **nhiều** `FROM`, và **chỉ tầng cuối cùng trở thành image**. Các tầng trước chỉ là **xưởng gia công tạm** — dùng xong bỏ.

| Tầng | Base image | Nhiệm vụ | Có vào image cuối? |
|---|---|---|---|
| `builder` | `17-jdk-alpine` (có `javac`, có Gradle) | Biên dịch `src/` thành `user-service.jar` | ❌ **Không** |
| `runtime` | `17-jre-alpine` (chỉ có `java`) | Nhận cái JAR, chạy nó | ✅ **Có** |

Cây cầu duy nhất giữa hai tầng là **một dòng**:

```
COPY --from=builder /app/build/libs/user-service.jar app.jar
```

Dòng này nói: *"lấy đúng một file từ xưởng, đem sang nhà mới"*. Mọi thứ khác ở xưởng — mã nguồn, Gradle, `javac`, thư mục `.gradle` vài trăm MB — **bị bỏ lại** vì không ai chép sang.

### Vì sao không giữ luôn JDK cho tiện?

| | Giữ JDK trong image | Chỉ có JRE |
|---|---|---|
| Chạy app được | ✅ | ✅ |
| Có `javac` để biên dịch code lạ | ✅ **Đây là vấn đề** | ❌ **Đây là điều tốt** |
| Có mã nguồn để người khác đọc | ✅ **Vấn đề** | ❌ **Tốt** |

Nếu ai đó chiếm được container, JDK cho họ khả năng **biên dịch và chạy mã mới ngay bên trong**. JRE thì không. Đây gọi là **giảm bề mặt tấn công** — mỗi công cụ bạn không cài là một cửa bạn không phải khoá.

> ⚠️ **Đừng chỉ nhìn con số MB.** Ở Thí nghiệm 1 bạn sẽ thấy bản single-stage và multi-stage **dung lượng gần như nhau**, vì cả hai đều kết thúc ở `jre-alpine`. Giá trị thật của multi-stage **không phải** dung lượng, mà là:
> 1. **Máy đích không cần cài Gradle/JDK** — build diễn ra bên trong Docker
> 2. **Image cuối không chứa mã nguồn** — bạn giao sản phẩm, không giao công thức
> 3. **Build giống nhau ở mọi máy** — không còn phụ thuộc phiên bản Java của từng người

### "Tầng" (layer) và vì sao thứ tự `COPY` quyết định tốc độ

Mỗi dòng lệnh trong Dockerfile tạo ra **một tầng**, và Docker **nhớ lại** tầng đã build. Khi build lần sau, Docker đi từ trên xuống và hỏi từng tầng: *"đầu vào của mày có thay đổi không?"*

- **Không đổi** → dùng lại tầng cũ, **0 giây**
- **Đổi** → build lại tầng này **và mọi tầng bên dưới**

Chính chữ **"và mọi tầng bên dưới"** là lý do thứ tự quan trọng. So sánh:

| Dockerfile của chúng ta | Bản sai ở Thí nghiệm 2 |
|---|---|
| `COPY build.gradle settings.gradle` | `COPY . .` ← **chép hết cùng lúc** |
| `RUN ./gradlew dependencies` ← tải thư viện | `RUN ./gradlew bootJar` |
| `COPY src ./src` ← code đổi ở đây | |
| `RUN ./gradlew bootJar` | |

Bạn sửa một dòng Java. Ở bản của chúng ta, tầng `dependencies` **không bị ảnh hưởng** vì `build.gradle` không đổi → thư viện dùng lại, build nhanh. Ở bản sai, `COPY . .` thấy có file đổi → **tải lại toàn bộ thư viện từ đầu**.

> 💡 **Quy tắc nhớ đời:** trong Dockerfile, đặt thứ **ít thay đổi** lên trên, thứ **hay thay đổi** xuống dưới. File cấu hình đổi vài tháng một lần; code đổi vài phút một lần.

### 🎯 Bài này đóng góp gì cho cam kết đầu buổi?

Bây giờ bạn có **một thứ duy nhất, tự chứa, có thể giao đi**: một image mang sẵn Java bên trong. Máy nhận **không cần Java, không cần Gradle, không cần mã nguồn**. Nhưng image này còn nằm trên máy bạn — **BÀI 2** sẽ đưa nó ra ngoài.

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
docker pull --platform linux/amd64 ghcr.io/caotv1512/user-service:1.0.0
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
docker build --platform linux/amd64 -t ghcr.io/caotv1512/user-service:latest .
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

**Dọn dẹp — trả lại file nguồn như ban đầu:**

```bash
git checkout -- src/main/java/com/quickbite/user/WalletRules.java && echo "Da hoan tac file nguon"
```

> ⚠️ Thí nghiệm này cũng `echo ... >>` vào file nguồn thật. Hoàn tác ngay để repo sạch. Không dùng git thì xoá tay dòng bắt đầu bằng `// ban moi` ở cuối file.

---

## 🔍 GIẢI THÍCH TƯỜNG TẬN — BÀI 2

### Đọc tên image như đọc một địa chỉ

Tên image không phải chuỗi tuỳ ý — nó là **địa chỉ đầy đủ** để Docker biết đi đâu lấy:

```
ghcr.io / caotv1512 / user-service : 1.0.0
   │          │            │           │
   │          │            │           └── TAG · nhãn bạn tự đặt cho một bản
   │          │            └────────────── TÊN · tên image
   │          └─────────────────────────── NAMESPACE · chủ sở hữu (user/org GitHub)
   └────────────────────────────────────── HOST · máy chủ registry
```

| Nếu thiếu phần nào | Docker hiểu thành |
|---|---|
| Thiếu host | `docker.io` (Docker Hub) — **không phải** GHCR |
| Thiếu tag | `:latest` |
| Thiếu namespace | Thư viện chính thức (`postgres`, `nginx`…) |

> Đây là lý do `docker tag` **bắt buộc** trước khi push: image tên `user-service:1.0.0` không có địa chỉ, Docker không biết đẩy đi đâu. `docker tag` **không tạo bản sao** — nó chỉ **dán thêm một nhãn** lên cùng một image.

### Vì sao tên phải chữ thường?

Chuẩn OCI quy định phần đường dẫn của tên image chỉ nhận **chữ thường**. Tên GitHub của bạn có thể là `CaoTV1512` (có chữ hoa) — nhưng tên image **phải** là `caotv1512`. Thí nghiệm 3 cho bạn thấy lỗi này, vì nó là lỗi rất hay gặp khi viết CI (biến `${{ github.actor }}` giữ nguyên chữ hoa).

### `--password-stdin` — không chỉ là cho gọn

```
printf '%s' "$CR_PAT" | docker login ghcr.io -u caotv1512 --password-stdin
```

| Cách viết | Hậu quả |
|---|---|
| `docker login -p <token>` | Token **nằm trong lịch sử shell** (`~/.zsh_history`), hiện trong `ps` cho user khác thấy, Docker cảnh báo |
| `--password-stdin` | Token đi qua đường ống, **không lưu vào đâu** |

> 🔒 **Ba điều tuyệt đối:** (1) Dùng **PAT**, **không bao giờ** dùng mật khẩu GitHub. (2) **Không** commit token vào repo. (3) PAT chỉ cần đúng 2 quyền `write:packages` + `read:packages` — cấp thừa quyền là tự tạo rủi ro.

### `docker push` thật sự gửi những gì?

Không phải cả image. Docker gửi **từng tầng**, và **bỏ qua tầng registry đã có**. Lần push đầu chậm; lần sau bạn chỉ sửa code, tầng `jre-alpine` và tầng thư viện đã nằm trên registry → chỉ tầng chứa JAR được gửi. Đó là lý do bạn thấy dòng `Layer already exists`.

### 🎯 Bài này đóng góp gì cho cam kết đầu buổi?

Image đã **ra khỏi máy bạn**. Từ giờ nó có một địa chỉ mà cả thế giới gõ được. Nhưng nó vẫn được build **bằng máy bạn** — nếu máy bạn cài sai phiên bản gì đó, cả lớp lãnh đủ. **BÀI 3** chuyển việc build sang một máy trung lập.

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
docker pull --platform linux/amd64 ghcr.io/caotv1512/user-service:latest
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

## 🔍 GIẢI THÍCH TƯỜNG TẬN — BÀI 3

### Vì sao phải build trên CI khi máy mình build được rồi?

| | Build ở máy cá nhân | Build trên CI |
|---|---|---|
| Phiên bản JDK | Của riêng máy đó | **Ghi rõ trong workflow** |
| File lạc trong thư mục | Có thể lọt vào image | Runner **luôn mới sạch** |
| Ai build được | Chỉ người đó | **Bất kỳ ai** push code |
| Khi người đó nghỉ phép | Tắc | Không ảnh hưởng |
| Bằng chứng ai build, từ commit nào | Không có | **Log lưu vĩnh viễn** |

> **Câu chốt:** build ở máy cá nhân là *"tin vào máy một người"*. Build trên CI là *"tin vào một công thức viết ra giấy"*. Cam kết "máy nào cũng chạy được" chỉ vững nếu bản thân việc build cũng không phụ thuộc máy nào.

### `GITHUB_TOKEN` và khối `permissions`

Mỗi lần workflow chạy, GitHub **tự sinh** một token tạm — `GITHUB_TOKEN` — rồi **xoá khi job xong**. Bạn không phải tạo, không phải lưu, không lo hết hạn.

Mặc định token này **không có** quyền ghi package. Bạn phải xin rõ ràng:

```yaml
permissions:
  contents: read      # đọc code
  packages: write     # ghi image lên GHCR
```

| | `GITHUB_TOKEN` | PAT cá nhân |
|---|---|---|
| Ai tạo | GitHub tự | Bạn tự tạo |
| Sống bao lâu | **Hết job là chết** | Tới ngày hết hạn (có thể hàng tháng) |
| Lộ ra ngoài thì sao | Hết job là vô dụng | **Kẻ khác dùng được ngay** |
| Nên dùng khi | **Mặc định** | Chỉ khi cần với sang repo khác |

> 🔒 **Nguyên tắc đặc quyền tối thiểu:** khai đúng quyền cần, không khai `write-all`. Thí nghiệm 5 cho bạn thấy chuyện gì xảy ra khi thiếu quyền — và quan trọng hơn: **lỗi đó đọc là biết ngay**, `denied: permission_denied: write_package`.

### `setup-buildx-action` để làm gì?

Driver Docker mặc định **không** biết dùng cache của GitHub Actions. Nếu bạn viết `cache-to: type=gha` mà không bật Buildx trước, workflow sẽ chết với `buildx failed with: ... build-cache-backends`. Vì vậy thứ tự trong workflow luôn là:

1. `docker/setup-buildx-action@v3` ← bật driver hiểu cache
2. `docker/login-action@v3` ← đăng nhập registry
3. `docker/build-push-action@v5` ← build và push

### 🎯 Bài này đóng góp gì cho cam kết đầu buổi?

Việc build giờ **không phụ thuộc máy của ai**. Bất kỳ ai push code cũng ra được image giống nhau, và log chứng minh nó ra từ commit nào. Nhưng "build xong" chưa có nghĩa "chạy được" — **BÀI 4** đi tìm bằng chứng.

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
docker run -d --platform linux/amd64 --name thu-image -p 8091:8081 \
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
docker run -d --platform linux/amd64 --name thu-voi -p 8092:8081 ghcr.io/caotv1512/user-service:latest
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
docker run -d --platform linux/amd64 --name rac-lai ghcr.io/caotv1512/user-service:latest >/dev/null
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

## 🔍 GIẢI THÍCH TƯỜNG TẬN — BÀI 4

### "Build thành công" **không** đồng nghĩa "chạy được"

Đây là chỗ nhiều người ngã. `docker build` xanh chỉ chứng minh **các lệnh trong Dockerfile không lỗi**. Nó **không** chứng minh:

| Build xanh vẫn có thể | Ví dụ thật |
|---|---|
| Sai đường dẫn JAR | `COPY --from=builder` chép file rỗng, app không khởi động |
| Thiếu biến môi trường | App bật lên rồi tắt vì không có `DB_HOST` |
| Sai `ENTRYPOINT` | Container tạo xong tắt ngay |
| Sai kiến trúc CPU | `no match for platform in manifest` khi chạy ở máy khác |

Vì vậy workflow 07 làm một việc khác hẳn workflow 06: nó **pull image về một Runner mới** rồi **thật sự chạy**, rồi **gọi health check**. Chỉ khi health check trả về `UP` mới coi là đạt.

### Runner mới là "máy trắng" hoàn hảo

Điểm quan trọng nhất của BÀI 4: mỗi job GitHub Actions chạy trên một máy ảo **vừa được tạo, sẽ bị xoá**. Nó **không có** mã nguồn của bạn (trừ khi bạn `checkout`), **không có** image bạn vừa build ở job trước, **không có** gì cả.

> Nên khi Runner đó `docker pull` rồi `docker run` mà app lên `UP`, bạn có **bằng chứng máy móc** cho cam kết đầu buổi — không phải lời hứa của thầy, mà là log ai cũng mở xem được.

### Vì sao cần vòng lặp chờ, không dùng `sleep`?

`docker run -d` trả về **ngay khi container được tạo** — không phải khi app sẵn sàng. Spring Boot còn cần 10–20 giây nữa để nạp context và kết nối database.

| Cách chờ | Vấn đề |
|---|---|
| `curl` ngay | **Luôn fail** — Thí nghiệm 6 cho thấy |
| `sleep 30` rồi `curl` | Máy nhanh **phí 20 giây**; máy chậm **vẫn fail** |
| **Lặp 12 lần × 5 giây, thoát khi `UP`** | ✅ Sẵn sàng lúc nào đi tiếp lúc đó |
| `HEALTHCHECK` trong Dockerfile | Tốt nhất — để bài nâng cao |

### `if: always()` — vì sao một dòng nhỏ lại quan trọng

Mặc định, một bước trong job **bị bỏ qua** nếu bước trước thất bại. Nghĩa là khi health check fail, bước `docker rm` **không chạy** → container rác ở lại. Trên Runner dùng một lần thì không sao, nhưng trên **self-hosted runner** hoặc máy chủ thật, rác tích lại cho tới khi hết cổng hoặc hết đĩa.

```yaml
- name: Dọn container
  if: always()        # chạy kể cả khi bước trước fail
  run: docker rm -f thu-image || true
```

> 💡 Quy tắc: **bước dọn dẹp luôn có `if: always()`**. Thí nghiệm 7 mô phỏng đúng tình huống này ở máy bạn.

### 🎯 Bài này đóng góp gì cho cam kết đầu buổi?

Bạn đã có **bằng chứng tự động**: một máy trắng pull image về và chạy được. Còn một lỗ hổng cuối: bạn đang gọi image bằng **tag**, mà tag thì **đổi được**. **BÀI 5** bịt lỗ hổng đó.

---

# BÀI 5 — TAG VÀ DIGEST

**Mục tiêu:** hiểu vì sao production không dùng `latest`.

## 5.1 · Xem digest của image

```bash
docker pull --platform linux/amd64 ghcr.io/caotv1512/user-service:latest
```
```bash
docker image inspect ghcr.io/caotv1512/user-service:latest --format '{{index .RepoDigests 0}}'
```

**Phải thấy:** `ghcr.io/caotv1512/user-service@sha256:...`

## 5.2 · Chứng minh nhiều tag cùng trỏ một digest

```bash
docker pull --platform linux/amd64 ghcr.io/caotv1512/user-service:1.0.0
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
docker pull --platform linux/amd64 "$DIGEST"
```

**Vì sao dùng digest:** tag có thể bị ghi đè bất cứ lúc nào. Digest là **vân tay của nội dung** — pull bằng digest thì chắc chắn lấy đúng thứ đã kiểm duyệt, không ai đổi được.

| | Tag | Digest |
|---|---|---|
| Ai đặt | Con người | Máy tự tính từ nội dung |
| Đổi được không | **Có** | **Không** |
| Dùng khi | Chọn bản để triển khai | **Chứng minh** đúng nội dung |

---

## 🔍 GIẢI THÍCH TƯỜNG TẬN — BÀI 5

### Tag là cái nhãn dán, digest là vân tay

Hãy tưởng tượng registry là một kho hàng:

- **Digest** = **vân tay của thùng hàng**, máy tự tính từ **nội dung** (`sha256:a1b2c3...`). Nội dung đổi một byte → vân tay khác hoàn toàn. **Không ai sửa được** vân tay mà giữ nguyên nội dung.
- **Tag** = **mảnh giấy dán bên ngoài** ghi "bản mới nhất". Người dán được, người **bóc ra dán sang thùng khác** cũng được.

| | Tag | Digest |
|---|---|---|
| Ai đặt | Con người | Máy tính từ nội dung |
| Đổi được không | ✅ **Có — đây là nguy hiểm** | ❌ **Không** |
| Đọc có hiểu không | `1.0.0` — dễ hiểu | `sha256:9f8e...` — không |
| Dùng để | **Chọn** bản muốn triển khai | **Chứng minh** đúng nội dung |

### Kịch bản thật khiến người ta mất ngủ

1. Thứ Hai: bạn test `latest` rất kỹ, mọi thứ hoàn hảo, bạn triển khai.
2. Thứ Ba: đồng nghiệp push một bản lỗi, CI gắn `latest` cho bản mới.
3. Thứ Tư: một máy chủ khởi động lại, `docker pull ... :latest` → **nhận bản lỗi**.
4. Không một dòng cấu hình nào của bạn thay đổi. Nhưng hệ thống đã khác.

Thí nghiệm 4 tái hiện đúng chuyện này ở máy bạn: bạn push hai lần và thấy `latest` **âm thầm** trỏ sang bản mới.

> ✅ **Cách làm đúng trong thực tế:** dùng **tag** khi nói chuyện với người (`1.0.0`, `2.3.1`), dùng **digest** khi nói chuyện với máy (file triển khai, Kubernetes manifest). Tag để chọn, digest để khoá.

### Vì sao digest mới hoàn thiện cam kết đầu buổi?

Cam kết là *"máy nào cũng chạy được"*. Nhưng chạy **cái gì**? Nếu mỗi máy pull `:latest` vào thời điểm khác nhau, chúng có thể đang chạy **những bản khác nhau** — và bạn không có cách nào biết.

Pull bằng digest thì **mọi máy chắc chắn có cùng từng byte**. Lúc đó cam kết mới đầy đủ:

> **"Build một lần, chạy mọi nơi — và mọi nơi chạy đúng cùng một thứ."**

### 🎯 Đã đủ mảnh ghép — giờ đi chứng minh

| Bài | Đã có gì |
|---|---|
| 1 | Image tự chứa, sạch, không cần Java ở máy đích |
| 2 | Địa chỉ công khai để mọi máy lấy về |
| 3 | Build không phụ thuộc máy của ai |
| 4 | Bằng chứng tự động: máy trắng pull về chạy được |
| 5 | Cách chỉ đúng một bản, không ai đổi được |

**BÀI 6** làm việc cuối cùng: **xoá sạch máy bạn**, pull lại từ Registry, và chạy. Không Java, không Gradle, không mã nguồn.

---

# BÀI 6 — CHỨNG MINH LỜI HỨA: MÁY NÀO CŨNG CHẠY ĐƯỢC

> **Đây là bài quan trọng nhất của buổi học.** Đầu buổi ta đặt câu hỏi: *"Đưa file JAR lên máy chủ khách hàng, chuyện gì có thể sai?"* Bài này trả lời dứt điểm.

## 6.1 · Lời hứa là gì?

Ba buổi vừa qua ta đi dần tới một điều:

| Buổi | Giao cho người khác cái gì | Họ phải tự lo gì |
|---|---|---|
| **04–05** | Mã nguồn + hướng dẫn | Cài Java, cài Docker, tự build, tự cấu hình |
| **07** | File JAR | **Cài đúng Java 17**, tự cấu hình biến, tự chạy |
| **08** | **Docker image trên Registry** | **Không gì cả** — `docker pull` rồi `docker run` |

**Lời hứa của Session 08:**

> Sau khi đẩy image lên Registry, **bất kỳ máy nào** — Windows, Linux, Mac, máy chủ đám mây — chỉ cần có Docker là **pull về chạy được ngay**. Không cài Java. Không cài Gradle. Không build lại. Không "máy tôi chạy được mà".

## 6.2 · Giả lập "một máy hoàn toàn mới"

Xoá sạch mọi image của buổi này để chắc chắn không còn dấu vết gì của lần build trước.

**Bước 1 — xem trước sẽ xoá những gì** (bước này chưa xoá gì cả):

```bash
docker images --format '{{.Repository}}:{{.Tag}}' --filter 'reference=user-service:*' --filter 'reference=ghcr.io/caotv1512/user-service:*'
```

**Phải thấy** các bản đã tạo trong buổi: `user-service:1.0.0`, `user-service:single`, và các bản đã pull ở BÀI 5: `ghcr.io/caotv1512/user-service:1.0.0`, `:latest`.

**Bước 2 — xoá từng bản một:**

```bash
docker images --format '{{.Repository}}:{{.Tag}}' --filter 'reference=user-service:*' --filter 'reference=ghcr.io/caotv1512/user-service:*' | while read -r r; do docker rmi -f "$r"; done
```
```bash
docker images --format '{{.Repository}}:{{.Tag}}' --filter 'reference=user-service:*' --filter 'reference=ghcr.io/caotv1512/user-service:*' | grep . || echo "Sach - khong con image nao cua buoi nay"
```

**Phải thấy:** `Sach - khong con image nao cua buoi nay`

*(Dùng lại đúng bộ lọc ở Bước 1 nên kết quả dứt khoát. Nếu máy bạn còn image của buổi trước như `quickbite-user-service:v1` thì nó **vẫn ở đó và không sao cả** — xem giải thích #2 bên dưới.)*

> 💡 Từ giờ trở đi, **mọi thứ chạy được đều đến từ Registry**, không phải từ máy bạn.

### 🔍 Ba chi tiết trong lệnh xoá — đều có lý do

**1. Vì sao không gõ tay danh sách tên?**
Ở BÀI 5 bạn đã pull cả tag `:1.0.0`, cả `:latest`, **và** pull bằng digest. Nếu chỉ xoá vài tên bạn còn nhớ, máy vẫn giữ image cũ — và khi `docker run` ở bước sau, **Docker dùng bản có sẵn, không tải từ Registry**. Cả lập luận "mọi thứ đến từ Registry" sụp ngay tại đó mà **không ai nhận ra**. Để bộ lọc tự liệt kê thì không sót bản nào.

**2. Vì sao dùng `--filter reference=...` chứ không `grep user-service`?**
Máy bạn có thể còn image của các buổi trước — `quickbite-user-service:v1` (Session 04), `stack-user-service:latest` (Session 05). Lọc bằng `grep user-service` sẽ **bắt luôn những image đó và xoá mất demo của buổi khác**. Bộ lọc `reference` chỉ khớp đúng hai kho ta muốn:

| Bộ lọc | Khớp | Không khớp |
|---|---|---|
| `reference=user-service:*` | `user-service:1.0.0`, `user-service:single` | `quickbite-user-service:v1` |
| `reference=ghcr.io/caotv1512/user-service:*` | `ghcr.io/caotv1512/user-service:latest` | image của người khác |

> Hai cờ `--filter reference=` đi cùng nhau mang nghĩa **HOẶC** — khớp kho này *hoặc* kho kia.

**3. Vì sao phải `while read` xoá từng cái, không truyền hết một lượt?**
Đây là chỗ dễ vấp. `:latest` và `:1.0.0` thường là **cùng một image, hai nhãn**. Nếu truyền cả danh sách cho một lệnh `docker rmi` duy nhất, nhãn đầu bị xoá làm image biến mất, các nhãn sau trở thành tham chiếu không còn tồn tại, và Docker trả về lỗi rất khó hiểu:

```
Error response from daemon: 404 page not found
```

Xoá **từng tên một** thì Docker xử lý đúng: những nhãn đầu chỉ `Untagged`, tới nhãn cuối cùng mới thật sự `Deleted`. Bạn sẽ thấy rõ điều đó trong kết quả:

```
Untagged: ghcr.io/caotv1512/user-service:1.0.0
Untagged: ghcr.io/caotv1512/user-service:latest
Deleted:  sha256:826eafe331cab428...
```

> 💡 **Rút ra:** `Untagged` = bóc nhãn, image vẫn còn. `Deleted` = nhãn cuối đã bóc, **giờ mới thật sự mất image**. Đúng ý tưởng của BÀI 5: nhãn và image là hai thứ khác nhau.
>
> ⚠️ Lệnh này chạy lại nhiều lần **không lỗi** — danh sách rỗng thì vòng lặp không chạy lần nào.

## 6.3 · Kéo image về — không cần đăng nhập

```bash
docker pull --platform linux/amd64 ghcr.io/caotv1512/user-service:latest
```

**Phải thấy:** các layer tải về, kết thúc bằng `Status: Downloaded newer image`

> 💡 **Không cần `docker login`** vì package này để chế độ public. Với package private thì phải login trước — nhưng luồng còn lại y hệt.

```bash
docker image inspect ghcr.io/caotv1512/user-service:latest --format '{{.Created}} | {{.Architecture}} | {{.Os}}'
```
**Phải thấy:** thời điểm tạo là lúc **CI chạy trên máy chủ GitHub**, không phải lúc bạn build.

## 6.4 · Dựng database rồi chạy image

```bash
docker network create qb-demo-net
```

```bash
docker run -d --platform linux/amd64 --name qb-pg --network qb-demo-net   -e POSTGRES_USER=quickbite_user   -e POSTGRES_PASSWORD=quickbite_user   -e POSTGRES_DB=quickbite_user_db   postgres:15-alpine
```

Đợi PostgreSQL sẵn sàng:
```bash
until docker exec qb-pg pg_isready -U quickbite_user; do sleep 2; done
```

Giờ chạy image **kéo từ Registry**:
```bash
docker run -d --platform linux/amd64 --name qb-app --network qb-demo-net -p 8099:8081   -e DB_HOST=qb-pg -e DB_PORT=5432 -e DB_NAME=quickbite_user_db   -e DB_USERNAME=quickbite_user -e DB_PASSWORD=quickbite_user   ghcr.io/caotv1512/user-service:latest
```

Đợi ứng dụng khởi động:
```bash
until curl -fsS http://localhost:8099/actuator/health; do sleep 3; done
```
**Phải thấy:** `{"status":"UP","components":{"db":{"status":"UP"...` — thường sau khoảng 10 giây

## 6.5 · Kiểm chứng đầy đủ

```bash
curl -s http://localhost:8099/api/users | head -c 300; echo
```
**Phải thấy:** 3 bản ghi thật đọc từ PostgreSQL

```bash
docker run --rm --platform linux/amd64 --entrypoint sh ghcr.io/caotv1512/user-service:latest -c "java -version 2>&1 && ls /app"
```
**Phải thấy:** Java 17 và `app.jar` — **Java nằm sẵn trong image**, máy bạn không cần cài

```bash
java -version
```
> Máy bạn có Java hay không **cũng không ảnh hưởng gì**. Ứng dụng đang chạy bằng Java bên trong container.

## 6.6 · Chốt lại với lớp

Dừng lại đây và hỏi sinh viên:

> *"Vừa rồi ta đã làm gì trên máy này?"*

| Việc | Có làm không |
|---|---|
| Cài Java 17 | ❌ Không |
| Cài Gradle | ❌ Không |
| Tải mã nguồn về | ❌ Không |
| Chạy `./gradlew bootJar` | ❌ Không |
| Sửa cấu hình gì đó cho hợp máy | ❌ Không |
| **`docker pull` rồi `docker run`** | ✅ **Chỉ có vậy** |

> **Đó chính là lời hứa được thực hiện.** Image này do máy chủ GitHub build từ một commit đã qua kiểm tra. Nó chạy y hệt trên máy CI, trên Mac này, và sẽ chạy y hệt trên máy chủ production.

<div class="keybox">
<span class="lbl">Câu chốt viết lên bảng</span>
<p><strong>"Build một lần, chạy mọi nơi."</strong></p>
<p>Không phải khẩu hiệu — đó là thứ các em vừa tự tay chứng minh.</p>
</div>

### Quay lại khung ở phần A1b — tick từng dòng

Mở lại **A1b** đầu tài liệu. Đây là bảng ta đã vẽ trước khi học. Giờ tick:

| Bài | Câu hỏi | Đã trả lời bằng gì | |
|---|---|---|---|
| **1** | Đóng gói app cho gọn và sạch? | Multi-stage — image cuối **không có `javac`, không có `src/`** | ✅ |
| **2** | Đưa image ra khỏi máy mình? | Đã push lên `ghcr.io`, xem được trên trang Packages | ✅ |
| **3** | Ai build? | **Máy chủ GitHub** build, không phải máy cá nhân ai | ✅ |
| **4** | Sao biết image chạy được? | Workflow 07 pull về **Runner trắng** và health check `UP` | ✅ |
| **5** | Chỉ đúng một bản? | Pull được bằng **digest** — không ai đổi được | ✅ |
| **6** | Máy trắng chạy được không? | **Vừa xoá sạch image, pull lại, app lên `UP`** | ✅ |

### Ba câu hỏi để biết sinh viên có thật sự hiểu

Hỏi lần lượt, đừng đưa đáp án ngay:

> **1. "Máy này không cài Java. Vậy `java -jar` chạy bằng Java nào?"**
> → Java **nằm trong image**, ở tầng `jre-alpine`. Container dùng Java của chính nó, hoàn toàn không liên quan tới máy chủ. Đây là điểm khác biệt cốt tử so với file JAR ở Session 07.

> **2. "Nếu bạn cùng lớp pull image này, có chạy được ngay không?"**
> → Chạy được ứng dụng, **nhưng cần database riêng**. Image chứa *ứng dụng*, không chứa *dữ liệu*. Đó là lý do ở 6.4 ta phải dựng `qb-pg` trước. Thí nghiệm 8 cho các em tự làm chuyện này với nhau.

> **3. "Vậy Docker Compose ở Session 04 giờ còn dùng làm gì?"**
> → Session 04 dùng Compose để **build và chạy tại máy**. Giờ Compose chỉ cần `image: ghcr.io/...` thay cho `build: .` — **không ai phải build nữa**, chỉ pull rồi chạy. Đó là bước tiến của cả buổi học.

## 6.7 · Dọn dẹp

```bash
docker rm -f qb-app qb-pg
```
```bash
docker network rm qb-demo-net
```

---

## 🧪 Thí nghiệm 8 — Đưa image sang máy bạn cùng lớp

Đây là bài chứng minh thuyết phục nhất — **làm theo cặp**.

**Bạn A** (đã push image lên GHCR) đọc to tên image của mình:
```
ghcr.io/<username-cua-A>/user-service:latest
```

**Bạn B** — máy chưa từng đụng tới dự án này — gõ đúng 2 lệnh:

```bash
docker pull --platform linux/amd64 ghcr.io/<username-cua-A>/user-service:latest
```
```bash
docker run --rm --platform linux/amd64 --entrypoint sh ghcr.io/<username-cua-A>/user-service:latest -c "java -version 2>&1 && ls -la /app"
```

**Phải thấy:** Java 17 và `app.jar` — trên máy chưa hề cài Java, chưa hề có mã nguồn.

> ⚠️ **Điều kiện:** package của A phải để **Public**. Vào `github.com/<username>?tab=packages` → chọn package → *Package settings* → *Change visibility* → **Public**.
>
> Nếu để Private, B phải `docker login ghcr.io` bằng PAT có quyền `read:packages` và được A cấp quyền truy cập.

**Câu hỏi cho cả lớp sau thí nghiệm:**

> *"Nếu thay máy bạn B bằng một máy chủ ở Singapore, có gì khác không?"*
> → **Không có gì khác.** Cùng 2 lệnh đó. Đây chính là cách các hệ thống thật triển khai phần mềm.

---

# BÀI 7 — TÌM LỖI

## Bước 1 — Image có trên Registry chưa?

```bash
docker pull --platform linux/amd64 ghcr.io/caotv1512/user-service:latest
```
Lỗi `unauthorized` → chưa login hoặc thiếu quyền `read:packages`
Lỗi `manifest unknown` → tag không tồn tại, kiểm tra lại tên và nhãn

## Bước 2 — Đang đăng nhập bằng tài khoản nào?

```bash
cat ~/.docker/config.json | grep -A2 ghcr
```

> **Không in ra gì** = chưa từng `docker login ghcr.io` trên máy này. Với image **công khai** thì vẫn `pull` được bình thường; chỉ khi image **riêng tư** mới bắt buộc phải login.
```bash
docker logout ghcr.io && printf '%s' "$CR_PAT" | docker login ghcr.io -u caotv1512 --password-stdin
```

## Bước 3 — Image build ra có đúng không?

```bash
docker history ghcr.io/caotv1512/user-service:latest --no-trunc | head -8
```
```bash
docker run --rm --platform linux/amd64 --entrypoint sh ghcr.io/caotv1512/user-service:latest -c "ls -la /app && java -version"
```

## Bước 4 — Container chạy được không?

```bash
docker run -d --platform linux/amd64 --name debug-img -p 8093:8081 ghcr.io/caotv1512/user-service:latest
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
| Xem bên trong image | `docker run --rm --entrypoint sh user-service:1.0.0 -c "ls -la /app"` |
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

## 8 thí nghiệm trong tài liệu này

| # | Triệu chứng | Nguyên nhân | Sửa |
|---|---|---|---|
| 1 | Hai image dung lượng xấp xỉ nhau | Cùng dùng `jre-alpine` làm tầng cuối | Không phải lỗi — giá trị nằm ở chỗ multi-stage **tự biên dịch** |
| 2 | Build lại vẫn tải lại thư viện | `COPY . .` quá sớm | Chép file cấu hình trước `src/` |
| 3 | `repository name must be lowercase` | Tên image có chữ hoa | `tr '[:upper:]' '[:lower:]'` |
| 4 | `latest` trỏ sang bản khác lúc nào không hay | Bản chất của `latest` | Dùng tag cố định cho production |
| 5 | `denied: permission_denied: write_package` | Thiếu `packages: write` | Thêm vào khối `permissions` |
| 6 | `Connection refused` ngay sau `docker run -d` | App chưa khởi động xong | Vòng lặp thử lại 12 × 5 giây |
| 7 | Container rác ở lại trên Runner | Thiếu `if: always()` | Thêm bước dọn có `if: always()` |
| 8 | Máy bạn pull về nhưng `docker run` lại khởi động Spring Boot thay vì mở shell | `ENTRYPOINT` biến tham số thành đối số của `java` | Dùng `--entrypoint sh` rồi mới `-c "..."` |

## Lỗi khác

| Triệu chứng | Sửa |
|---|---|
| `unauthorized` khi pull | Chưa login, hoặc thiếu `packages: read` |
| `manifest unknown` | Tag không tồn tại — kiểm tra lại tên và nhãn |
| `COPY --from` không tìm thấy file | Sai đường dẫn ở builder stage — kiểm tra `WORKDIR` |
| `no matching manifest for linux/arm64` | Mac Apple Silicon — thêm `--platform linux/amd64` |
| `404 page not found` khi `docker rmi` | Truyền nhiều nhãn cùng lúc — xoá **từng nhãn một** (xem 6.2) |
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
- [ ] **BÀI 6:** xoá sạch image rồi pull lại từ Registry và chạy được
- [ ] **BÀI 6:** giải thích được vì sao máy không cần cài Java mà app vẫn chạy
- [ ] **Thí nghiệm 8:** đưa image sang máy bạn khác và chạy được ở đó
- [ ] Trả lời được: *"Ta đã cài gì lên máy này? — Không gì cả, chỉ pull và run"*
