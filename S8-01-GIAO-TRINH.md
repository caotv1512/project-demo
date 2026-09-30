# GIÁO TRÌNH BUỔI DẠY — SESSION 08
# Đóng gói Docker Image & Đẩy lên Registry

> **Thời lượng:** 180 phút (3 tiếng)
> **Điều kiện tiên quyết:** Session 04 (Dockerfile, Compose) và Session 07 (GitHub Actions, job, artifact, đọc log lỗi).
> **Mục tiêu đầu ra:** sinh viên viết được Dockerfile multi-stage, build image ngay trong CI, đẩy lên GitHub Container Registry có gắn phiên bản, rồi kéo về chạy và kiểm chứng tự động.

> 🔗 **Repo demo có thật:** `github.com/caotv1512/project-demo` — workflow `06` và `07` đã chạy thật, dùng để chiếu trực tiếp trên lớp.

---

## 0. BẢNG PHÂN BỔ THỜI GIAN

| Phần | Nội dung | Thời lượng | Hình thức |
|---|---|---|---|
| 0 | **Session 08 khác Session 07 chỗ nào** | 15' | Hỏi đáp + đối chiếu |
| 1 | Vì sao image phải được build trong pipeline | 25' | Lý thuyết + demo |
| 2 | Multi-stage build — tách môi trường build khỏi môi trường chạy | 35' | Lý thuyết + demo |
| — | **NGHỈ GIẢI LAO** | 10' | |
| 3 | Tên image, tag, digest và đẩy lên Registry | 30' | Lý thuyết + demo |
| 4 | Dùng image từ Registry trong luồng CI/CD | 30' | Demo |
| 5 | Kịch bản thực hành tổng hợp | 25' | Thực hành |
| 6 | Tổng kết – Q&A – Giao bài tập | 10' | |

---

# PHẦN 0 — SESSION 08 KHÁC SESSION 07 CHỖ NÀO? (15 phút)

> **Đây là phần quan trọng nhất để mở đầu.** Sinh viên vừa học xong Session 07 và đang nghĩ *"CI/CD học rồi, buổi này học lại à?"*. Phải xoá ngay suy nghĩ đó trong 15 phút đầu.

## 0.1. Câu hỏi mở màn

Viết lên bảng, để lớp suy nghĩ 2 phút:

> *"Buổi trước ta đã build được file JAR tự động trên CI và tải nó về từ mục Artifacts. Vậy giờ đưa file JAR đó lên máy chủ khách hàng, chuyện gì có thể sai?"*

Gợi ý dẫn dắt nếu lớp im lặng:
- Máy chủ đó có cài sẵn Java 17 chưa? Nếu nó chỉ có Java 11 thì sao?
- Biến môi trường, cổng, thư mục làm việc — ai cấu hình?
- Ba tháng sau cần cài lại đúng bản đó, lấy file JAR ở đâu? Artifact đã hết hạn rồi.

## 0.2. Bảng đối chiếu hai buổi — chiếu lên và giảng kỹ

| | **Session 07** | **Session 08** |
|---|---|---|
| **Câu hỏi trung tâm** | *"Làm sao tự động kiểm tra và đóng gói?"* | *"Đóng gói xong rồi thì cất ở đâu và giao cho ai?"* |
| **Sản phẩm cuối** | File **JAR** | **Docker image** |
| **Nơi lưu** | **Artifact** của GitHub | **Registry** (GHCR) |
| **Thời gian sống** | 3–7 ngày rồi tự xoá | **Lâu dài**, tới khi bạn xoá |
| **Cách lấy về** | Bấm nút tải trên web, giải nén bằng tay | `docker pull` — một lệnh |
| **Chạy được ngay không?** | **Không.** Máy đích phải có sẵn đúng Java | **Có.** Java nằm sẵn trong image |
| **Định danh phiên bản** | Tên file, không có chuẩn | **Tag** và **digest** có chuẩn rõ ràng |
| **Máy khác dùng được không?** | Phải tự lo môi trường | Pull về là chạy, không cần cài gì |

> **Câu chốt nên viết lên bảng:**
> **Session 07 trả lời *"code có chạy được không?"*. Session 08 trả lời *"làm sao giao thứ chạy được đó cho người khác?"***

## 0.3. Ba thứ đã học giờ được nối lại với nhau

Sinh viên hay học rời rạc từng buổi. Hãy vẽ sơ đồ này lên bảng để họ thấy bức tranh chung:

```
Session 04–05        Session 07              Session 08
────────────         ────────────            ────────────
Viết Dockerfile  →   CI tự build JAR    →    CI tự build IMAGE
Chạy Compose         Lưu vào Artifact        Đẩy lên Registry
ở MÁY MÌNH           (tạm, thủ công)         (lâu dài, tự động)
                                                    │
                                                    ▼
                                            Máy nào cũng
                                            pull về chạy được
```

| Buổi | Đã có gì | Còn thiếu gì |
|---|---|---|
| **04–05** | Biết viết Dockerfile, biết chạy container | Mọi thứ làm **bằng tay trên máy mình** |
| **07** | CI tự chạy test, tự đóng gói JAR | Sản phẩm là **JAR tạm bợ**, máy đích vẫn phải tự cài Java |
| **08** | CI tự đóng gói **image**, đẩy lên Registry có phiên bản | *(đây là đích của chuỗi bài)* |

## 0.4. Ba khái niệm mới hoàn toàn của buổi này

Nói trước để sinh viên biết mình sắp học gì — đây là những thứ Session 07 **chưa hề nhắc tới**:

| # | Khái niệm mới | Giải quyết vấn đề gì |
|---|---|---|
| **1** | **Multi-stage build** | Image chứa cả JDK và mã nguồn thì vừa nặng vừa lộ code. Tách làm hai tầng: tầng build dùng JDK, tầng chạy chỉ giữ JRE và JAR |
| **2** | **Registry, tag, digest** | Artifact không có chuẩn đánh phiên bản. Registry cho phép gắn `1.0.0`, `sha-a1b2c3d` và có mã băm `digest` không thể giả mạo |
| **3** | **Xác thực với Registry** | Đẩy image lên cần đăng nhập. Ở máy dùng **PAT**, trong CI dùng **`GITHUB_TOKEN`** tự sinh theo từng job |

## 0.5. Một thứ tưởng giống nhưng khác hẳn

Sinh viên rất hay nhầm chỗ này — phải phân biệt ngay:

| | **Artifact** (Session 07) | **Registry** (Session 08) |
|---|---|---|
| Lưu gì | File bất kỳ — JAR, báo cáo, ảnh chụp | **Chỉ container image** |
| Ai lấy được | Người có quyền vào repo, tải bằng tay | Máy chủ, Kubernetes, bất kỳ ai có quyền — bằng `docker pull` |
| Có phiên bản không | Không có chuẩn | **Có** — tag và digest |
| Tự hết hạn | **Có**, mặc định 90 ngày, ta đặt 3 ngày | Không, giữ tới khi xoá |
| Dùng để | **Kiểm tra trong lúc phát triển** | **Phát hành thật** |

> **Ẩn dụ nên dùng:** Artifact giống **hộp đựng đồ ăn mang về** — dùng ngay trong ngày rồi bỏ. Registry giống **kho hàng có mã vạch** — hàng nằm đó lâu dài, ai cần thì quét mã lấy đúng lô hàng mình muốn.

---

# PHẦN 1 — VÌ SAO IMAGE PHẢI ĐƯỢC BUILD TRONG PIPELINE (25 phút)

## 1.1. Hai cách làm, hai kết quả

**Cách 1 — Build image ở máy cá nhân:**

| Vấn đề | Biểu hiện |
|---|---|
| **Chỉ xác nhận JAR** | CI chỉ xác nhận file JAR được build từ commit đã push. Image thì không ai kiểm chứng |
| **Dễ lệch nguồn** | Image có thể được tạo từ source, Dockerfile hoặc JAR **đang thay đổi** trên máy cá nhân |
| **Khó truy vết** | Gặp lỗi thì cực kỳ khó khẳng định image đã phát hành tương ứng với commit nào |

**Cách 2 — Build image trong pipeline:**

| Lợi ích | Ý nghĩa |
|---|---|
| **Quản lý tập trung** | Đóng gói trở thành một job có log, có trạng thái, có điều kiện chạy rõ ràng |
| **Nhất quán tuyệt đối** | Image được tạo từ **đúng revision** mã nguồn đã vượt qua kiểm tra CI |
| **Gắn nhãn rõ ràng** | Tag image tạo ra làm đầu vào nhận diện được cho Registry hoặc bước tiếp theo |

**Sơ đồ đối chiếu — nên vẽ lên bảng:**

```
✓ ĐÚNG    Commit & Push → CI build JAR → CI build Image  → nhất quán tuyệt đối
✗ SAI     Commit & Push → CI build JAR → tạo image tay   → image lệch pha
```

### 🔍 GIẢI THÍCH TƯỜNG TẬN — "Lệch pha" nghĩa là gì?

Đây là từ trừu tượng, phải cho ví dụ cụ thể.

**Tình huống thật hay xảy ra:**

1. 9h00 — Bạn sửa code, chạy `docker build` ở máy, image chứa bản sửa đó
2. 9h05 — Bạn thấy chưa ưng, sửa tiếp 2 dòng nữa
3. 9h10 — Bạn `git push` — Git chỉ ghi nhận bản **9h05**
4. 9h15 — Bạn `docker push` image — nhưng image này là bản **9h00**

Kết quả: image trên Registry **không tương ứng với bất kỳ commit nào**. Ba tháng sau có lỗi ở production, bạn không thể tìm ra code nào sinh ra image đó.

> **Câu hỏi nên đặt cho lớp:** *"Vậy ai phát hiện ra chuyện này?"*
> → **Không ai cả.** Đó chính là chỗ nguy hiểm. Image vẫn chạy được, vẫn có vẻ đúng. Chỉ khi cần truy vết mới phát hiện ra không lần được về đâu.

**Build trong CI thì không thể lệch pha**, vì Runner chỉ có đúng một thứ: mã nguồn tại commit vừa push. Nó **không có** bản sửa nào chưa commit của bạn.

## 1.2. Hai job và điểm chuyển giao từ JAR sang image

**Cơ chế trao đổi Artifact:**

- **Job `build_jar`** — biên dịch mã nguồn, lưu file JAR dưới tên artifact `app-jar`
- **Job `build_image`** — chỉ chạy khi `build_jar` thành công, nhờ `needs`
- **Bản chất Artifact** — cơ chế truyền file **có chủ đích** giữa các job độc lập

> ⚠️ **Nhắc lại bài học Session 07:** không được giả định workspace của job trước còn nguyên ở job sau. Mỗi job là một máy ảo mới tinh. Muốn chuyển file thì **bắt buộc** qua artifact.

```yaml
build_image:
  needs: build_jar
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v5
    - uses: actions/download-artifact@v5
      with: { name: app-jar, path: build/libs }
    - run: docker build -t user-service:ci .
```

> 💡 **Nhưng có một cách hay hơn.** Nếu Dockerfile là **multi-stage** (Phần 2), bạn không cần job `build_jar` riêng nữa — image tự biên dịch bên trong nó. Phần 2 sẽ giải thích vì sao đó là cách tốt hơn.

## 1.3. Docker socket — vừa là năng lực, vừa là quyền nhạy cảm

| Lợi ích vận hành | Rủi ro phải kiểm soát |
|---|---|
| Runner mount `/var/run/docker.sock` để `docker build` nói chuyện trực tiếp với host | Job truy cập socket có **quyền kiểm soát tuyệt đối** toàn bộ tiến trình trên Docker host |
| Dùng được cache layer sẵn có, không cần Docker-in-Docker phức tạp | Chỉ cho phép chạy mã nguồn, workflow và action từ **nguồn hoàn toàn đáng tin cậy** |
| Hiệu năng vượt trội khi Runner nội bộ và bảo mật tốt | **Tuyệt đối không** xem Docker socket như một volume lưu trữ thông thường |

> ⚠️ **Đây là lý do tuyệt đối không dùng self-hosted runner cho repo public.** Ai gửi Pull Request cũng chạy được code tuỳ ý — mà code đó có quyền kiểm soát toàn bộ Docker host. Nhắc lại cảnh báo này từ Session 07, giờ hậu quả còn nghiêm trọng hơn.

> 💡 **Với GitHub-hosted runner thì sao?** Không phải lo — mỗi job một máy ảo riêng, huỷ sau khi xong. Đây là một lý do nữa để chọn GitHub-hosted khi chưa có nhu cầu đặc biệt.

---

# PHẦN 2 — MULTI-STAGE BUILD (35 phút)

## 2.1. Vấn đề của Dockerfile một tầng

Nhắc lại Dockerfile Session 04:

```dockerfile
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY build/libs/user-service.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Nó có một giả định ngầm rất lớn:** file `build/libs/user-service.jar` **đã tồn tại sẵn**. Ai tạo ra nó? Bạn, bằng tay, bằng `./gradlew bootJar` trên máy mình.

> **Câu hỏi dẫn dắt:** *"Vậy nếu muốn image tự biên dịch luôn thì sao? Thêm JDK và Gradle vào image được không?"*
> → Được. Nhưng image sẽ phình từ ~180MB lên ~500MB, **chứa cả mã nguồn của bạn**, và có đủ công cụ để kẻ tấn công biên dịch thêm thứ khác bên trong.

## 2.2. Ý tưởng multi-stage: hai tầng, chỉ JAR đi qua

| | **Builder stage** | **Runtime stage** |
|---|---|---|
| Base image | **JDK** (có trình biên dịch) | **JRE** (chỉ chạy được) |
| Chứa gì | Gradle Wrapper, mã nguồn, toàn bộ dependency | Chỉ **JRE + file JAR** |
| Nhiệm vụ | Chạy `./gradlew bootJar` | Chạy `java -jar app.jar` |
| Đặc điểm | Nặng, nhiều công cụ thừa cho vận hành | Siêu nhẹ, bề mặt tấn công tối thiểu |
| Có trong image cuối? | **KHÔNG** | **CÓ** |

**Chỉ duy nhất file JAR đi từ builder sang runtime**, qua `COPY --from=builder`.

## 2.3. Dockerfile multi-stage của user-service

```dockerfile
# ---------- TẦNG 1: BUILDER ----------
FROM eclipse-temurin:17-jdk-alpine AS builder
WORKDIR /app
COPY gradlew ./
COPY gradle ./gradle
COPY build.gradle settings.gradle ./
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon
COPY src ./src
RUN ./gradlew bootJar --no-daemon

# ---------- TẦNG 2: RUNTIME ----------
FROM eclipse-temurin:17-jre-alpine AS runtime
WORKDIR /app
COPY --from=builder /app/build/libs/user-service.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Nhất quán phiên bản:** `user-service` chạy Java 17 — dùng JDK 17 để build và JRE 17 để chạy.

> ⚠️ **Với các service khác phải đổi:** `restaurant-service`, `order-service`, `notification-service` dùng **Java 21**. Bắt buộc đổi base image ở **cả hai tầng** thành `eclipse-temurin:21-...`. Đổi một tầng quên tầng kia là lỗi rất khó nhận ra.

### 🔍 GIẢI THÍCH TƯỜNG TẬN — `COPY --from=builder` hoạt động thế nào?

Sinh viên hay hỏi *"Sao lại có hai chữ `FROM` trong một file?"*.

**Hiểu đúng: mỗi `FROM` bắt đầu một image hoàn toàn mới, từ số không.**

```
FROM ...jdk... AS builder     ← bắt đầu image A
  ... làm việc trong image A ...
                                    │
FROM ...jre... AS runtime     ← VỨT BỎ image A, bắt đầu image B TRỐNG
  COPY --from=builder ...     ← chỉ với tay sang image A lấy đúng 1 file
```

**Ba điều rút ra:**

| # | Điều rút ra | Hệ quả |
|---|---|---|
| 1 | Tầng runtime bắt đầu từ image **sạch** | Mã nguồn, JDK, Gradle **không có** trong image cuối |
| 2 | `--from=builder` là **cây cầu duy nhất** | Chỉ những gì bạn `COPY` sang mới đi qua được |
| 3 | Image cuối chỉ là tầng **cuối cùng** | Docker tự vứt các tầng trung gian |

**Cách chỉ cho sinh viên thấy ngay:**

```bash
docker history user-service:multi
```

Lịch sử layer **không hề có** bước `./gradlew bootJar` hay `COPY src`. Chúng nằm ở image builder đã bị vứt đi.

## 2.4. Thứ tự layer quyết định tốc độ build

```dockerfile
COPY gradlew ./
COPY gradle ./gradle
COPY build.gradle settings.gradle ./
RUN ./gradlew dependencies --no-daemon     ← tải thư viện, thành 1 layer riêng

COPY src ./src                              ← mã nguồn để CUỐI
RUN ./gradlew bootJar --no-daemon
```

- **Tối ưu layer:** file cấu hình Gradle ít thay đổi hơn `src/` nên layer dependency được tái dùng tối đa
- **Giới hạn cache:** cache chỉ có hiệu lực khi builder cục bộ còn hợp lệ; multi-stage **không tự động** tăng tốc mọi lần build mới hoàn toàn
- **`.dockerignore`:** nên loại bỏ `.git/`, `.gradle/`, `build/` để bảo mật và giữ build context gọn

### 🔍 GIẢI THÍCH TƯỜNG TẬN — Vì sao thứ tự lại quan trọng đến thế?

Docker cache theo **layer**, và có một quy tắc sắt:

> **Một layer bị đổi thì mọi layer phía SAU nó đều phải làm lại.**

Minh hoạ bằng hai cách viết:

**Cách SAI — copy hết một lần:**
```dockerfile
COPY . .                              ← sửa 1 dòng Java là layer này đổi
RUN ./gradlew bootJar --no-daemon     ← phải tải lại TOÀN BỘ thư viện
```
Sửa một dấu chấm phẩy → tải lại 100MB thư viện → chờ 3 phút.

**Cách ĐÚNG — copy theo tần suất thay đổi:**
```dockerfile
COPY build.gradle settings.gradle ./  ← hiếm khi đổi
RUN ./gradlew dependencies            ← layer này được TÁI DÙNG
COPY src ./src                        ← đổi liên tục
RUN ./gradlew bootJar                 ← chỉ layer này làm lại
```
Sửa một dấu chấm phẩy → dùng lại cache thư viện → chờ 30 giây.

> **Nguyên tắc chung áp dụng cho mọi ngôn ngữ:** *chép file ít thay đổi trước, file thay đổi nhiều sau*. Node.js thì `package.json` trước `src/`. Python thì `requirements.txt` trước code.

## 2.5. So sánh single-stage và multi-stage

```bash
docker build -t user-service:single -f Dockerfile.single .
docker build -t user-service:multi .
docker image ls user-service
docker history user-service:multi
```

**Quan sát thành phần runtime, đừng chỉ nhìn dung lượng:**

- **Nhận JAR từ builder:** runtime image chỉ nhận đúng file JAR chuyển giao từ builder
- **Lược bỏ tệp thừa:** lịch sử layer cho thấy mã nguồn và Gradle Wrapper **hoàn toàn không hiện diện**
- **Lưu ý hiệu năng:** không cam kết cố định về thời gian build hay dung lượng — phụ thuộc base image, cơ chế cache và mức độ thay đổi mã nguồn

> 💡 **Điểm nên nhấn:** lợi ích lớn nhất của multi-stage **không phải dung lượng** mà là **bề mặt tấn công**. Image không có `javac`, không có Gradle, không có mã nguồn — kẻ xâm nhập được vào container cũng không có công cụ gì để làm tiếp.

---

## ☕ NGHỈ GIẢI LAO (10 phút)

---

# PHẦN 3 — TÊN IMAGE, TAG, DIGEST VÀ REGISTRY (30 phút)

## 3.1. Ba thành phần định danh một image

```
ghcr.io/caotv1512/user-service : 1.0.0
└──┬──┘ └───┬────┘ └────┬─────┘  └─┬─┘
registry namespace   tên image    tag
```

| Thành phần | Ví dụ | Vai trò |
|---|---|---|
| **Image name** | `ghcr.io/<namespace>/user-service` | Xác định package và **địa chỉ host** nơi image được lưu |
| **Tag** | `1.0.0` hoặc `latest` | Nhãn phiên bản **dễ đọc với con người**. Nhưng **có thể bị ghi đè** |
| **Digest** | `sha256:a1b2c3...` | Mã băm **duy nhất** của nội dung thực tế. Dùng khi cần tái lập chính xác 100% |

**Mô hình ánh xạ:**
```
IMAGE: ghcr.io/<namespace>/user-service
   ├── tag: 1.0.0   ──┐
   ├── tag: latest  ──┼──► cùng trỏ tới MỘT digest tại thời điểm push gần nhất
   └── digest: sha256:...
```

### 🔍 GIẢI THÍCH TƯỜNG TẬN — Vì sao `latest` là cái bẫy?

Sinh viên thấy `latest` thì nghĩ "bản mới nhất" — **sai hoàn toàn**.

**`latest` chỉ là một cái tên.** Nó không tự động trỏ tới bản mới. Nó trỏ tới **bản cuối cùng có ai đó push kèm nhãn `latest`**. Nếu không ai push kèm nhãn đó, `latest` đứng yên mãi mãi ở bản cũ.

**Ba tai hoạ thật do `latest` gây ra:**

| Tình huống | Hậu quả |
|---|---|
| Production đang chạy `latest`. Đồng nghiệp push bản lỗi kèm `latest` | Lần restart tiếp theo, production **tự động lấy bản lỗi** |
| Cần rollback về "bản hôm qua" | Không có cách nào — `latest` đã bị ghi đè, bản cũ không còn nhãn nào trỏ tới |
| Hai máy chủ pull `latest` cách nhau 1 giờ | **Chạy hai phiên bản khác nhau** mà không ai biết |

> **Quy tắc bắt buộc:** production **luôn** dùng tag cố định (`1.0.0`) hoặc digest. `latest` chỉ dùng cho môi trường dev, nơi hỏng cũng không sao.

### 🔍 GIẢI THÍCH TƯỜNG TẬN — Digest khác tag ra sao?

| | **Tag** | **Digest** |
|---|---|---|
| Ai đặt | Con người | **Máy tự tính** từ nội dung |
| Đổi được không | **Có** — push đè là đổi | **Không thể** — đổi nội dung là ra digest khác |
| Ví dụ | `1.0.0` | `sha256:9f8e7d...` |
| Dùng khi | Chọn bản để triển khai | **Chứng minh** đúng nội dung đã kiểm duyệt |

**Ẩn dụ dễ hiểu:** tag là **cái nhãn dán trên hộp** — bóc ra dán sang hộp khác được. Digest là **vân tay của thứ bên trong hộp** — không thể giả.

**Tại sao quan trọng?** Kiểm toán bảo mật hỏi *"bản chạy ở production có đúng bản đã qua kiểm duyệt không?"*. Tag không trả lời được. Digest thì trả lời chắc chắn.

## 3.2. Đăng nhập GHCR và push image từ máy

```bash
export CR_PAT='<token lưu ngoài repository>'
printf '%s' "$CR_PAT" | docker login ghcr.io -u <github_username> --password-stdin

docker tag user-service:1.0.0 ghcr.io/<namespace>/user-service:1.0.0
docker push ghcr.io/<namespace>/user-service:1.0.0
```

**Nguyên tắc an toàn — nói kỹ, đây là chỗ sinh viên hay sai:**

| Nguyên tắc | Vì sao |
|---|---|
| Dùng **PAT classic** với quyền tối thiểu: `write:packages` để push, `read:packages` để pull | Nguyên tắc đặc quyền tối thiểu |
| **Tuyệt đối không** dùng mật khẩu tài khoản GitHub | Lộ mật khẩu là mất toàn bộ tài khoản, không chỉ một repo |
| **Không** đặt token vào Dockerfile, YAML, `.env` bị commit, ảnh slide hoặc log | Bot quét GitHub tìm ra trong vài phút |
| Dùng `--password-stdin` thay vì `-p <token>` | Gõ token thẳng vào lệnh sẽ lưu vào lịch sử shell |
| **Ghi lại digest** mà Docker trả về sau khi push | Đây là bằng chứng xác thực duy nhất cho nội dung image |

> ⚠️ **Nhắc lại bài học `.env` từ Session 04:** Git lưu **toàn bộ lịch sử**. Commit nhầm token rồi xoá đi thì token vẫn đọc được bằng `git log -p`. Phải thu hồi token đó ngay, không phải chỉ xoá file.

## 3.3. Local để thực hành, CI để phát hành

| | **Local push** | **CI publish** |
|---|---|---|
| Mục đích | **Học** quy trình: login, tag, push | **Phát hành thật** |
| Nguồn image | Máy cá nhân — **có thể chứa thay đổi chưa commit** | Commit đã qua kiểm duyệt và test tự động |
| Xác thực | PAT cá nhân | **`GITHUB_TOKEN`** sinh tự động theo job |
| Truy vết | Khó | Chính xác tới commit |

> **Câu chốt:** *local push chỉ để hiểu CLI. CI mới là đích phát hành đáng tin cậy.*

### 🔍 GIẢI THÍCH TƯỜNG TẬN — `GITHUB_TOKEN` hơn PAT ở chỗ nào?

| | **PAT cá nhân** | **`GITHUB_TOKEN`** |
|---|---|---|
| Ai tạo | Bạn tạo bằng tay | GitHub **tự sinh cho từng job** |
| Sống bao lâu | Tới khi bạn thu hồi — có thể **nhiều năm** | **Hết job là hết hiệu lực** |
| Quyền hạn | Theo checkbox bạn tick, thường quá rộng | Khai báo `permissions:` ngay trong YAML |
| Lộ ra ngoài thì sao | Kẻ xấu dùng được **tới khi bạn phát hiện** | Gần như vô dụng — token đã chết |
| Phải làm gì để dùng | Tạo, copy, lưu vào Secrets | **Không làm gì cả**, có sẵn |

> **Đây là lý do nên dạy sinh viên ưu tiên `GITHUB_TOKEN`.** Nó vừa an toàn hơn, vừa ít việc hơn. PAT chỉ dùng khi làm ở máy cá nhân, nơi không có `GITHUB_TOKEN`.

---

# PHẦN 4 — DÙNG IMAGE TỪ REGISTRY TRONG CI/CD (30 phút)

## 4.1. Luồng bốn bước

```
cấp quyền  →  đăng nhập  →  pull  →  xác nhận
```

```yaml
jobs:
  pull_image:
    permissions:
      packages: read              # quyền tối thiểu: chỉ ĐỌC
    env:
      IMAGE_REF: ghcr.io/ns/user-service:1.0.0
    steps:
      - name: Đăng nhập GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Pull và kiểm tra image
        run: |
          docker pull "$IMAGE_REF"
          docker image inspect "$IMAGE_REF"
```

| Thành phần | Vai trò |
|---|---|
| `packages: read` | Token của job **chỉ đọc** được GHCR — không xoá, không ghi đè được gì |
| `docker/login-action` | Tự dùng `GITHUB_TOKEN`, loại bỏ hoàn toàn việc cấu hình PAT thủ công |
| `IMAGE_REF` | Tham chiếu tường minh: registry + namespace + tên + tag |
| `docker pull` + `inspect` | Tải layer về Runner rồi xác nhận image sẵn sàng cục bộ |

> 💡 **Mỗi job nhận một token riêng, vòng đời ngắn, chỉ hiệu lực trong phiên chạy đó.** Job kết thúc là token chết.

## 4.2. Pull xong phải chạy thử và kiểm tra health

Pull về mà không chạy thử thì chưa chứng minh được gì. Image có thể tải về được nhưng **khởi động là sập**.

```yaml
- name: Chạy và kiểm tra user-service
  run: |
    docker run -d --name verify_user_service \
      --network quickbite-net \
      --env-file .env -p 8081:8081 \
      "$IMAGE_REF"

    for i in {1..12}; do
      curl --fail http://localhost:8081/actuator/health && exit 0
      sleep 5
    done
    docker logs verify_user_service && exit 1

- name: Dọn container
  if: always()
  run: docker rm -f verify_user_service || true
```

| Cơ chế | Giải thích |
|---|---|
| **Môi trường** | PostgreSQL phải chạy trong network `quickbite-net`, `.env` chứa đúng cấu hình DB |
| **Vòng lặp health check** | Chờ tối đa 60 giây (12 lần × 5 giây) cho Spring Boot khởi động |
| **Xử lý lỗi** | Thất bại thì `docker logs` tự in lỗi ra màn hình trước khi dừng job |
| **`if: always()`** | Đảm bảo dọn container **bất kể** thành công hay thất bại |

### 🔍 GIẢI THÍCH TƯỜNG TẬN — Vì sao phải có vòng lặp chờ?

Sinh viên hay viết thế này rồi thắc mắc sao lúc chạy được lúc không:

```bash
docker run -d ...
curl http://localhost:8081/actuator/health    # ❌ gần như chắc chắn fail
```

**Vì `docker run -d` trả về ngay lập tức** — nó chỉ báo "container đã được tạo", không phải "ứng dụng đã sẵn sàng". Spring Boot cần thêm 10–20 giây để khởi động Tomcat và kết nối database.

**Ba cách xử lý, từ tệ tới tốt:**

| Cách | Vấn đề |
|---|---|
| `sleep 30` rồi curl | Máy nhanh thì phí 20 giây. Máy chậm thì vẫn fail |
| Vòng lặp thử lại 12 lần × 5 giây | **Tốt** — sẵn sàng lúc nào thì đi tiếp lúc đó, tối đa vẫn có giới hạn |
| Dùng `HEALTHCHECK` trong Dockerfile | Tốt nhất, nhưng cần thêm kiến thức — để dành bài nâng cao |

> 💡 **`if: always()` là thói quen tốt cần dạy.** Không có nó, khi health check fail thì step dọn dẹp bị bỏ qua, container rác nằm lại trên Runner. Với self-hosted runner, rác tích tụ dần cho tới khi đầy đĩa.

---

# PHẦN 5 — KỊCH BẢN THỰC HÀNH TỔNG HỢP (25 phút)

## 5.1. Bốn bước theo đúng thứ tự

| Bước | Việc làm |
|---|---|
| **01 · Build local image** | Viết Dockerfile multi-stage, build `user-service:1.0.0` tại máy |
| **02 · Đăng nhập & Push** | Dùng PAT đăng nhập GHCR từ Docker CLI, gắn tag, push image |
| **03 · Chuẩn bị Runner** | Thiết lập PostgreSQL, network `quickbite-net`, secret `USER_SERVICE_ENV` |
| **04 · CI Pull & Verify** | Cập nhật `ci.yml` để login GHCR, pull image, health check, dọn dẹp |

> ⚠️ **Lưu ý quan trọng phải nói rõ:** quy trình "local build/push rồi CI pull/verify" chỉ dùng để **học từng thao tác**. Trong thực tế, toàn bộ build, push và deploy **nên chạy tự động hoàn toàn trên CI/CD**.

## 5.2. Bước 1 — Build tại máy

```bash
# Chạy tại thư mục gốc của user-service
docker build -t user-service:1.0.0 .
```

**Điều kiện chuyển bước tiếp theo:**
- Build hoàn thành không có lỗi cú pháp hoặc lỗi đóng gói
- `docker images | grep user-service` xác nhận image tồn tại

> **Không push mã nguồn hoặc làm bước 2 khi chưa kiểm tra Dockerfile ở local.**

## 5.3. Bước 2 và 3 — PAT login, tag, push

```bash
docker login ghcr.io -u <github_username>
docker tag user-service:1.0.0 ghcr.io/<namespace>/user-service:1.0.0
docker push ghcr.io/<namespace>/user-service:1.0.0
```

- **PAT classic** với đủ `read:packages` và `write:packages`
- **Tuyệt đối không** dùng mật khẩu chính của tài khoản
- Thay `<namespace>` bằng đúng username hoặc tên Organization sở hữu package
- Xác nhận: vào mục **Packages** trên trang cá nhân GitHub, kiểm tra image có tag `1.0.0`

## 5.4. Bước 4 — CI pull và verify

```yaml
jobs:
  test_image:
    runs-on: [self-hosted, quickbite]
    permissions:
      packages: read
    env:
      IMAGE_REF: ghcr.io/<namespace>/user-service:1.0.0
      USER_SERVICE_ENV: ${{ secrets.USER_SERVICE_ENV }}
    steps:
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Pull và kiểm tra user-service
        run: |
          printf '%s' "$USER_SERVICE_ENV" > "$RUNNER_TEMP/user-service.env"
          docker pull "$IMAGE_REF"
          docker run -d --name verify_user_service \
            --network quickbite-net \
            --env-file "$RUNNER_TEMP/user-service.env" \
            -p 8081:8081 "$IMAGE_REF"
          for i in {1..12}; do
            curl --silent --fail http://localhost:8081/actuator/health && exit 0
            sleep 5
          done
          docker logs verify_user_service
          exit 1

      - name: Dọn tài nguyên
        if: always()
        run: |
          docker rm -f verify_user_service || true
          rm -f "$RUNNER_TEMP/user-service.env"
```

| Điểm cần giải thích | Nội dung |
|---|---|
| **Secret `USER_SERVICE_ENV`** | Chứa các biến `DB_*`. Ghi ra file tạm trong `$RUNNER_TEMP`, xoá sau khi dùng |
| **`$RUNNER_TEMP`** | Thư mục tạm do GitHub cấp, tự dọn sau job — an toàn hơn `/tmp` |
| **Điều kiện pass** | `/actuator/health` phản hồi thành công trong tối đa 60 giây |
| **Khi lỗi** | Tự in `docker logs` ra console trước khi báo lỗi |
| **`if: always()`** | Luôn xoá container và file env tạm khỏi self-hosted Runner |

---

# PHẦN 6 — TỔNG KẾT (10 phút)

## 6.1. Quay lại câu hỏi đầu buổi

> *"Đưa file JAR lên máy chủ khách hàng, chuyện gì có thể sai?"*

| Rủi ro | Docker image giải quyết thế nào |
|---|---|
| Máy chủ không có đúng Java | **JRE nằm sẵn trong image** |
| Không ai biết cấu hình gì | Cấu hình khai báo trong image + biến môi trường |
| Ba tháng sau không tìm lại được bản đó | Registry giữ lâu dài, có **tag và digest** |
| Không biết image từ commit nào | CI build từ commit đã kiểm duyệt, tag `sha-xxxxxxx` |

## 6.2. Checklist kiến thức

- ❏ Build image **trong CI** để bảo đảm đúng phiên bản mã nguồn đã kiểm tra
- ❏ Multi-stage: dùng **JDK để build**, chỉ giữ **JRE và JAR** ở runtime
- ❏ Tag dùng để quản lý phiên bản; **GHCR** lưu trữ và phân phối image
- ❏ Máy local dùng **PAT**; workflow dùng **`GITHUB_TOKEN`** theo từng job
- ❏ `ci.yml` thực hiện pull image, chạy verify và dọn dẹp container

## 6.3. Bản đồ 7 kiến thức cốt lõi — dùng kiểm tra sinh viên

| # | Kiến thức cốt lõi | Hiểu rồi thì trả lời được | Quay lại phần |
|---|---|---|---|
| **1** | **Session 08 giao *thứ chạy được*, Session 07 chỉ giao *file*** | "Artifact và Registry khác nhau ở đâu?" | Phần 0 |
| **2** | **Build ở máy cá nhân thì image lệch pha với commit** | "Vì sao build trong CI thì không thể lệch pha?" | Phần 1.1 |
| **3** | **Mỗi `FROM` bắt đầu một image mới từ số không** | "Vì sao mã nguồn không có trong image cuối?" | Phần 2.3 |
| **4** | **Layer đổi thì mọi layer sau phải làm lại** | "Vì sao chép `build.gradle` trước `src/`?" | Phần 2.4 |
| **5** | **Tag đổi được, digest thì không** | "Vì sao `latest` không dùng cho production?" | Phần 3.1 |
| **6** | **`GITHUB_TOKEN` sống theo job, PAT sống nhiều năm** | "Lộ token nào nguy hiểm hơn? Vì sao?" | Phần 3.3 |
| **7** | **`docker run -d` trả về ngay, app chưa sẵn sàng** | "Vì sao phải có vòng lặp chờ health check?" | Phần 4.2 |

## 6.4. Ba hiểu nhầm phải phá bỏ

**① "`latest` là bản mới nhất."**
→ Sai. `latest` chỉ là **một cái tên**, trỏ tới bản cuối cùng có ai đó push kèm nhãn đó. Không ai push thì nó đứng yên mãi.

**② "Multi-stage để image nhẹ hơn."**
→ Đúng một nửa. Lợi ích lớn nhất là **bề mặt tấn công**: image không có `javac`, không có Gradle, không có mã nguồn.

**③ "Pull image về được là xong."**
→ Sai. Pull được chỉ chứng minh **tải về được**. Phải chạy thử và gọi health endpoint mới chứng minh **dùng được**.

## 6.5. Bảng khái niệm hay nhầm

| Cặp | Khác nhau ở chỗ |
|---|---|
| Artifact ↔ Registry | File tạm, tải tay ↔ image lâu dài, `docker pull` |
| Single-stage ↔ Multi-stage | Cần JAR sẵn, image nặng ↔ tự biên dịch, image sạch |
| JDK ↔ JRE | Biên dịch được ↔ chỉ chạy được |
| Tag ↔ Digest | Nhãn dán, đổi được ↔ vân tay nội dung, không đổi được |
| PAT ↔ `GITHUB_TOKEN` | Bạn tạo, sống lâu ↔ tự sinh theo job, chết ngay |
| `docker build` ↔ `docker push` | Tạo image ở máy ↔ đẩy lên Registry |
| Local push ↔ CI publish | Để học CLI ↔ để phát hành thật |

## 6.6. Mười lỗi thường gặp

| # | Triệu chứng | Nguyên nhân | Xử lý |
|---|---|---|---|
| 1 | `denied: permission_denied` khi push | Thiếu quyền `packages: write` | Thêm vào khối `permissions` |
| 2 | `invalid reference format` | Tên image có **chữ hoa** | Chuyển toàn bộ sang chữ thường |
| 3 | `unauthorized` khi pull | Chưa login, hoặc thiếu `packages: read` | Thêm `docker/login-action` và quyền |
| 4 | `COPY --from` không tìm thấy file | Sai đường dẫn trong builder stage | Kiểm tra `WORKDIR` và vị trí JAR |
| 5 | Build lại vẫn chậm như lần đầu | Thứ tự layer sai — `COPY . .` quá sớm | Chép file cấu hình trước `src/` |
| 6 | Health check luôn fail | Gọi `curl` ngay sau `docker run -d` | Thêm vòng lặp thử lại |
| 7 | Container rác đầy Runner | Thiếu `if: always()` ở bước dọn | Thêm bước dọn có `if: always()` |
| 8 | App chạy được ở máy, sập trong CI | Không có database ở CI | Dùng service container hoặc chuẩn bị Runner |
| 9 | Image chạy sai phiên bản Java | Chỉ đổi base image một trong hai tầng | Đổi **cả hai** tầng |
| 10 | Rollback không được | Chỉ dùng tag `latest` | Luôn gắn thêm tag cố định và `sha-xxxxxxx` |

## 6.7. Bài tập về nhà

**Bài 1 (bắt buộc).** Viết Dockerfile multi-stage cho `restaurant-service` dùng **Java 21**. Chỉ rõ những dòng nào phải đổi so với `user-service` và vì sao.

**Bài 2 (bắt buộc).** Build cả hai bản `Dockerfile.single` và `Dockerfile` (multi-stage), chạy `docker image ls` và `docker history` cho cả hai. Lập bảng so sánh: dung lượng, số layer, và **những gì có mặt trong runtime**.

**Bài 3 (bắt buộc).** Cố tình đảo thứ tự — đặt `COPY src ./src` lên **trước** `COPY build.gradle`. Build hai lần, đo thời gian lần thứ hai. Giải thích con số quan sát được.

**Bài 4 (nâng cao).** Thêm `HEALTHCHECK` vào Dockerfile để chính Docker tự kiểm tra sức khoẻ container. So sánh với cách dùng vòng lặp `curl` trong workflow — mỗi cách mạnh ở đâu.

**Bài 5 (nâng cao).** Tìm hiểu cách pull image **bằng digest** thay vì tag. Giải thích vì sao hệ thống production nghiêm túc lại triển khai theo digest.

## 6.8. Câu hỏi vấn đáp nhanh

1. Session 08 khác Session 07 ở sản phẩm cuối là gì? *(JAR trong Artifact → Docker image trên Registry)*
2. Vì sao không nên build image ở máy cá nhân? *(Image lệch pha với commit, không truy vết được)*
3. Multi-stage có mấy tầng, mỗi tầng dùng base image gì? *(2 tầng: builder dùng JDK, runtime dùng JRE)*
4. `COPY --from=builder` làm gì? *(Lấy file từ tầng builder sang tầng runtime — cây cầu duy nhất)*
5. Vì sao chép `build.gradle` trước `src/`? *(File ít đổi để trước, tận dụng cache layer)*
6. Tag và digest khác nhau ở đâu? *(Tag đổi được, digest là vân tay nội dung không đổi được)*
7. Vì sao `latest` nguy hiểm ở production? *(Bị ghi đè, không rollback được, mỗi máy có thể pull bản khác)*
8. Trong CI nên dùng PAT hay `GITHUB_TOKEN`? *(`GITHUB_TOKEN` — tự sinh theo job, hết job là chết)*
9. Vì sao pull image xong phải chạy thử? *(Tải về được không chứng minh chạy được)*

---

**Hết giáo trình — chuyển sang `S8-02-LAB` để thực hành.**
