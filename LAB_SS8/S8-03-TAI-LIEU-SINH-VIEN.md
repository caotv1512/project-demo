# TÀI LIỆU HỌC — SESSION 08

<div class="hero">
<div class="tri"></div>
<h1>Đóng gói Docker Image &amp; Đẩy lên Registry</h1>
<p class="sub">Buổi trước ta giao <em>file</em>. Buổi này ta giao <em>thứ chạy được</em> — máy nào pull về cũng chạy, không cần cài gì thêm.</p>
<p style="margin:14px 0 0"><span class="pill">Session 08</span><span class="pill s">Thời lượng 3 tiếng</span><span class="pill g">Có repo demo chạy thật</span></p>
</div>

# Buổi này khác buổi trước ở chỗ nào?

Trước khi học gì mới, phải trả lời câu này — nếu không bạn sẽ nghĩ *"CI/CD học rồi mà"*.

<div class="keybox">
<span class="lbl">Câu hỏi mở màn</span>
<p>Buổi trước ta build được file JAR tự động trên CI và tải nó về từ mục Artifacts.</p>
<p><strong>Vậy giờ đưa file JAR đó lên máy chủ khách hàng, chuyện gì có thể sai?</strong></p>
</div>

Ba thứ có thể sai:

<div class="grid3">
<div class="card no">
<h4>Máy chủ thiếu Java</h4>
<p>File JAR cần đúng Java 17. Máy chủ chỉ có Java 11 thì <strong>không chạy được</strong>. Ai cài? Cài bản nào?</p>
</div>
<div class="card no">
<h4>Không ai biết cấu hình</h4>
<p>Cổng nào? Biến môi trường gì? Thư mục làm việc ở đâu? File JAR <strong>không mang theo</strong> những thông tin đó.</p>
</div>
<div class="card no">
<h4>Ba tháng sau tìm lại không có</h4>
<p>Artifact <strong>tự xoá sau 3–7 ngày</strong>. Cần cài lại đúng bản đó thì lấy ở đâu?</p>
</div>
</div>

## Bảng đối chiếu hai buổi

| | **Session 07** | **Session 08** |
|---|---|---|
| Câu hỏi trung tâm | *"Làm sao tự động kiểm tra và đóng gói?"* | *"Đóng gói xong thì cất ở đâu và giao cho ai?"* |
| Sản phẩm cuối | File **JAR** | **Docker image** |
| Nơi lưu | **Artifact** của GitHub | **Registry** (GHCR) |
| Thời gian sống | 3–7 ngày rồi tự xoá | **Lâu dài**, tới khi bạn xoá |
| Cách lấy về | Bấm nút tải, giải nén tay | `docker pull` — một lệnh |
| Chạy được ngay? | **Không** — máy đích phải có sẵn Java | **Có** — Java nằm trong image |
| Đánh phiên bản | Không có chuẩn | **Tag** và **digest** |

<div class="keybox">
<span class="lbl">Câu chốt phải nhớ</span>
<p><strong>Session 07 trả lời "code có chạy được không?".<br>
Session 08 trả lời "làm sao giao thứ chạy được đó cho người khác?"</strong></p>
</div>

## Ba buổi nối lại thành một chuỗi

<figure class="dg">
<svg viewBox="0 0 720 250" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Chuỗi ba buổi học nối tiếp nhau">
  <g font-family="Inter,sans-serif">
    <rect x="16" y="40" width="200" height="104" rx="11" fill="#fff" stroke="#8A929C" stroke-width="1.8"/>
    <text x="116" y="30" text-anchor="middle" font-size="12" font-weight="800" fill="#8A929C">SESSION 04–05</text>
    <text x="116" y="68" text-anchor="middle" font-size="13" font-weight="750" fill="#1B1F24">Viết Dockerfile</text>
    <text x="116" y="88" text-anchor="middle" font-size="13" font-weight="750" fill="#1B1F24">Chạy Compose</text>
    <text x="116" y="114" text-anchor="middle" font-size="11.5" fill="#8A929C">làm TAY, ở MÁY MÌNH</text>

    <rect x="258" y="40" width="200" height="104" rx="11" fill="#FFF4E5" stroke="#E07C00" stroke-width="1.8"/>
    <text x="358" y="30" text-anchor="middle" font-size="12" font-weight="800" fill="#B06000">SESSION 07</text>
    <text x="358" y="68" text-anchor="middle" font-size="13" font-weight="750" fill="#8A5000">CI tự build JAR</text>
    <text x="358" y="88" text-anchor="middle" font-size="13" font-weight="750" fill="#8A5000">Lưu vào Artifact</text>
    <text x="358" y="114" text-anchor="middle" font-size="11.5" fill="#A06A20">TỰ ĐỘNG, nhưng file TẠM</text>

    <rect x="500" y="40" width="204" height="104" rx="11" fill="#E8F5E9" stroke="#2E7D32" stroke-width="2.2"/>
    <text x="602" y="30" text-anchor="middle" font-size="12" font-weight="800" fill="#2E7D32">SESSION 08</text>
    <text x="602" y="68" text-anchor="middle" font-size="13" font-weight="750" fill="#1B3A1E">CI tự build IMAGE</text>
    <text x="602" y="88" text-anchor="middle" font-size="13" font-weight="750" fill="#1B3A1E">Đẩy lên Registry</text>
    <text x="602" y="114" text-anchor="middle" font-size="11.5" fill="#3B5C3E">LÂU DÀI, có phiên bản</text>
  </g>
  <g stroke="#44546A" stroke-width="2.2">
    <line x1="216" y1="92" x2="250" y2="92"/><line x1="458" y1="92" x2="492" y2="92"/>
  </g>
  <g fill="#44546A">
    <path d="M246 87 L258 92 L246 97 Z"/><path d="M488 87 L500 92 L488 97 Z"/>
  </g>
  <rect x="258" y="176" width="446" height="56" rx="10" fill="#F9FAFC" stroke="#E3E7EC"/>
  <text x="481" y="200" text-anchor="middle" font-family="Inter,sans-serif" font-size="12.5" font-weight="750" fill="#5B6572">Đích của cả chuỗi</text>
  <text x="481" y="220" text-anchor="middle" font-family="Inter,sans-serif" font-size="12" fill="#2E7D32">Máy nào cũng pull về chạy được, không cần cài gì thêm</text>
  <line x1="602" y1="144" x2="602" y2="170" stroke="#2E7D32" stroke-width="2" stroke-dasharray="4 3"/>
  <path d="M596 166 L602 178 L608 166 Z" fill="#2E7D32"/>
</svg>
</figure>

## Ba khái niệm mới hoàn toàn

| # | Khái niệm | Giải quyết vấn đề gì |
|---|---|---|
| **1** | **Multi-stage build** | Image chứa cả JDK và mã nguồn thì vừa nặng vừa lộ code. Tách hai tầng: tầng build dùng JDK, tầng chạy chỉ giữ JRE và JAR |
| **2** | **Registry, tag, digest** | Artifact không có chuẩn phiên bản. Registry cho gắn `1.0.0`, `sha-a1b2c3d` và có mã băm `digest` không thể giả |
| **3** | **Xác thực với Registry** | Đẩy image lên cần đăng nhập. Ở máy dùng **PAT**, trong CI dùng **`GITHUB_TOKEN`** tự sinh theo job |

## Artifact và Registry — đừng nhầm

| | **Artifact** (S07) | **Registry** (S08) |
|---|---|---|
| Lưu gì | File bất kỳ — JAR, báo cáo, ảnh | **Chỉ container image** |
| Ai lấy được | Người vào được repo, tải tay | Máy chủ, Kubernetes, ai có quyền — bằng `docker pull` |
| Có phiên bản | Không có chuẩn | **Có** — tag và digest |
| Tự hết hạn | **Có** | Không |
| Dùng để | **Kiểm tra lúc phát triển** | **Phát hành thật** |

<div class="keybox">
<span class="lbl">Ẩn dụ dễ nhớ</span>
<p><strong>Artifact</strong> giống <strong>hộp đựng đồ ăn mang về</strong> — dùng ngay trong ngày rồi bỏ.</p>
<p><strong>Registry</strong> giống <strong>kho hàng có mã vạch</strong> — hàng nằm đó lâu dài, ai cần thì quét mã lấy đúng lô mình muốn.</p>
</div>

---

# Phần 1 · Vì sao image phải build trong CI?

## Hai cách làm, hai kết quả

<div class="grid2">
<div class="card no">
<h4>Build ở máy cá nhân</h4>
<p><strong>Chỉ xác nhận JAR.</strong> CI kiểm chứng file JAR, còn image thì không ai kiểm.</p>
<p><strong>Dễ lệch nguồn.</strong> Image có thể tạo từ code đang sửa dở trên máy bạn.</p>
<p><strong>Khó truy vết.</strong> Gặp lỗi không biết image nào ứng với commit nào.</p>
</div>
<div class="card ok">
<h4>Build trong pipeline</h4>
<p><strong>Quản lý tập trung.</strong> Đóng gói thành một job có log, trạng thái rõ ràng.</p>
<p><strong>Nhất quán tuyệt đối.</strong> Image tạo từ đúng commit đã qua kiểm tra CI.</p>
<p><strong>Gắn nhãn rõ ràng.</strong> Tag nhận diện được cho Registry và bước sau.</p>
</div>
</div>

## "Lệch pha" là gì? — kể theo mốc thời gian

| Giờ | Bạn làm gì | Kết quả |
|---|---|---|
| 9h00 | Sửa code, chạy `docker build` | Image chứa bản **9h00** |
| 9h05 | Thấy chưa ưng, sửa tiếp 2 dòng | Máy có bản **9h05** |
| 9h10 | `git push` | Git ghi nhận bản **9h05** |
| 9h15 | `docker push` | Registry nhận image bản **9h00** |

**Kết quả:** image trên Registry **không tương ứng với bất kỳ commit nào**.

<div class="keybox">
<span class="lbl">Chỗ nguy hiểm nhất</span>
<p><strong>Không ai phát hiện ra.</strong> Image vẫn chạy được, vẫn có vẻ đúng. Chỉ khi cần truy vết mới biết không lần về đâu được.</p>
<p>Build trong CI thì <strong>không thể lệch pha</strong> — Runner chỉ có đúng mã nguồn tại commit vừa push, nó <strong>không có</strong> bản sửa dở nào của bạn.</p>
</div>

---

# Phần 2 · Multi-stage build

## Vấn đề của Dockerfile một tầng

Nhắc lại bản Session 04:

```dockerfile
FROM eclipse-temurin:17-jre-alpine
COPY build/libs/user-service.jar app.jar     ← giả định JAR ĐÃ có sẵn
ENTRYPOINT ["java", "-jar", "app.jar"]
```

Nó có một **giả định ngầm rất lớn**: file JAR đã tồn tại. Ai tạo? **Bạn, bằng tay**, bằng `./gradlew bootJar`.

> **Vậy thêm JDK và Gradle vào image để nó tự build được không?**
> Được — nhưng image phình từ ~180MB lên ~500MB, **chứa cả mã nguồn của bạn**, và có đủ công cụ để kẻ tấn công biên dịch thêm thứ khác bên trong.

## Ý tưởng: hai tầng, chỉ JAR đi qua

<figure class="dg">
<svg viewBox="0 0 720 290" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Sơ đồ multi-stage build hai tầng">
  <rect x="16" y="26" width="310" height="196" rx="12" fill="#FFF4E5" stroke="#E07C00" stroke-width="2"/>
  <text x="171" y="52" text-anchor="middle" font-family="Inter,sans-serif" font-size="14" font-weight="800" fill="#B06000">TẦNG 1 · BUILDER</text>
  <text x="171" y="72" text-anchor="middle" font-family="monospace" font-size="11.5" fill="#8A5000">eclipse-temurin:17-jdk-alpine</text>
  <g font-family="Inter,sans-serif" font-size="12" fill="#6B4A20">
    <rect x="40" y="88" width="262" height="26" rx="6" fill="#fff" stroke="#E5C9A6"/>
    <text x="171" y="105" text-anchor="middle">JDK · trình biên dịch</text>
    <rect x="40" y="120" width="262" height="26" rx="6" fill="#fff" stroke="#E5C9A6"/>
    <text x="171" y="137" text-anchor="middle">Gradle Wrapper + dependency</text>
    <rect x="40" y="152" width="262" height="26" rx="6" fill="#fff" stroke="#E5C9A6"/>
    <text x="171" y="169" text-anchor="middle">toàn bộ mã nguồn src/</text>
    <rect x="40" y="184" width="262" height="26" rx="6" fill="#FDECEC" stroke="#F0C4C4"/>
    <text x="171" y="201" text-anchor="middle" font-weight="700" fill="#8C1D1A">./gradlew bootJar → app.jar</text>
  </g>

  <rect x="394" y="26" width="310" height="196" rx="12" fill="#E8F5E9" stroke="#2E7D32" stroke-width="2.4"/>
  <text x="549" y="52" text-anchor="middle" font-family="Inter,sans-serif" font-size="14" font-weight="800" fill="#1B3A1E">TẦNG 2 · RUNTIME</text>
  <text x="549" y="72" text-anchor="middle" font-family="monospace" font-size="11.5" fill="#3B5C3E">eclipse-temurin:17-jre-alpine</text>
  <g font-family="Inter,sans-serif" font-size="12" fill="#3B5C3E">
    <rect x="418" y="88" width="262" height="26" rx="6" fill="#fff" stroke="#A8CFAB"/>
    <text x="549" y="105" text-anchor="middle">JRE · chỉ chạy được</text>
    <rect x="418" y="120" width="262" height="26" rx="6" fill="#fff" stroke="#A8CFAB"/>
    <text x="549" y="137" text-anchor="middle" font-weight="700">app.jar</text>
    <rect x="418" y="152" width="262" height="58" rx="6" fill="#F2FAF3" stroke="#C6E2C9" stroke-dasharray="4 4"/>
    <text x="549" y="176" text-anchor="middle" font-style="italic">KHÔNG có JDK</text>
    <text x="549" y="196" text-anchor="middle" font-style="italic">KHÔNG có Gradle, KHÔNG có mã nguồn</text>
  </g>

  <line x1="326" y1="124" x2="386" y2="124" stroke="#BD2728" stroke-width="2.8"/>
  <path d="M382 118 L394 124 L382 130 Z" fill="#BD2728"/>
  <rect x="300" y="92" width="112" height="24" rx="12" fill="#fff" stroke="#BD2728"/>
  <text x="356" y="109" text-anchor="middle" font-family="monospace" font-size="10.5" font-weight="700" fill="#BD2728">COPY --from</text>

  <text x="360" y="258" text-anchor="middle" font-family="Inter,sans-serif" font-size="12.5" font-weight="700" fill="#5B6572">Chỉ DUY NHẤT file JAR đi qua cây cầu này</text>
  <text x="360" y="278" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" font-style="italic" fill="#8A929C">Tầng builder bị vứt bỏ hoàn toàn sau khi build xong</text>
</svg>
</figure>

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

<div class="keybox">
<span class="lbl">Hiểu đúng hai chữ FROM</span>
<p><strong>Mỗi <code>FROM</code> bắt đầu một image hoàn toàn mới, từ số không.</strong></p>
<p>Tầng runtime <strong>không kế thừa</strong> gì từ tầng builder. Nó bắt đầu sạch trơn, rồi <code>COPY --from=builder</code> với tay sang lấy đúng một file.</p>
</div>

**Tự chứng minh trên máy:**

```bash
docker run --rm --platform linux/amd64 --entrypoint sh user-service:1.0.0 -c "ls -la /app"
```
Chỉ có `app.jar` — không có `src/`, không có `gradlew`.

```bash
docker run --rm --platform linux/amd64 --entrypoint sh user-service:1.0.0 -c "which javac || echo 'KHONG co javac'"
```
Không có `javac` → image chỉ có JRE.

> ⚠️ **Hai cờ trong lệnh trên đều bắt buộc, đừng bỏ bớt:**
>
> **`--entrypoint sh`** — Dockerfile của ta kết thúc bằng `ENTRYPOINT ["java", "-jar", "app.jar"]`. Nếu viết `docker run user-service:1.0.0 sh -c "..."` thì Docker **không** chạy `sh`, mà nối chuỗi đó vào sau `java -jar app.jar` như đối số → **Spring Boot khởi động** thay vì mở shell cho bạn xem. Phải `--entrypoint sh` để **thay** lệnh mặc định, rồi `-c "..."` đặt **sau** tên image.
>
> **`--platform linux/amd64`** — image nền `eclipse-temurin:17-jre-alpine` **không có bản ARM**, nên trên Mac Apple Silicon (M1–M4) thiếu cờ này là lỗi ngay `no match for platform in manifest`. Trên Ubuntu / Windows / Mac Intel thì cờ này **vô hại** (máy vốn đã là amd64), nên cứ để nguyên — cả lớp dùng chung một lệnh.

<div class="keybox">
<span class="lbl">Lợi ích lớn nhất không phải dung lượng</span>
<p>Mà là <strong>bề mặt tấn công</strong>. Image không có <code>javac</code>, không có Gradle, không có mã nguồn — kẻ xâm nhập được vào container cũng <strong>không có công cụ gì để làm tiếp</strong>.</p>
</div>

## Thứ tự layer quyết định tốc độ build

Docker cache theo **layer**, và có một quy tắc sắt:

> **Một layer bị đổi thì mọi layer phía SAU nó đều phải làm lại.**

<div class="grid2">
<div class="card no">
<h4>Cách SAI</h4>
<pre style="margin:9px 0"><code>COPY . .
RUN ./gradlew bootJar</code></pre>
<p>Sửa <strong>một dấu chấm phẩy</strong> → layer đổi → <strong>tải lại 100MB thư viện</strong> → chờ 3 phút.</p>
</div>
<div class="card ok">
<h4>Cách ĐÚNG</h4>
<pre style="margin:9px 0"><code>COPY build.gradle settings.gradle ./
RUN ./gradlew dependencies
COPY src ./src
RUN ./gradlew bootJar</code></pre>
<p>Sửa một dấu chấm phẩy → <strong>dùng lại cache thư viện</strong> → chờ 30 giây.</p>
</div>
</div>

> 💡 **Nguyên tắc áp dụng cho mọi ngôn ngữ:** chép file **ít thay đổi trước**, file **thay đổi nhiều sau**. Node.js thì `package.json` trước `src/`. Python thì `requirements.txt` trước code.

---

# Phần 3 · Tên image, tag và digest

```
ghcr.io / caotv1512 / user-service : 1.0.0
└──┬──┘   └───┬───┘   └─────┬────┘   └─┬─┘
registry   namespace    tên image     tag
```

| Thành phần | Vai trò |
|---|---|
| **Image name** | Xác định package và **địa chỉ host** nơi image được lưu |
| **Tag** | Nhãn phiên bản **dễ đọc với người**. Nhưng **có thể bị ghi đè** |
| **Digest** | Mã băm `sha256:...` **duy nhất** của nội dung. Dùng khi cần tái lập chính xác 100% |

## `latest` là cái bẫy

Thấy `latest` thì nghĩ "bản mới nhất" — **sai hoàn toàn**.

**`latest` chỉ là một cái tên.** Nó trỏ tới **bản cuối cùng có ai đó push kèm nhãn `latest`**. Không ai push kèm nhãn đó thì nó đứng yên mãi mãi.

| Tình huống | Hậu quả |
|---|---|
| Production chạy `latest`, đồng nghiệp push bản lỗi kèm `latest` | Lần restart tiếp theo **tự động lấy bản lỗi** |
| Cần rollback về "bản hôm qua" | **Không có cách nào** — nhãn đã bị ghi đè |
| Hai máy chủ pull `latest` cách nhau 1 giờ | **Chạy hai phiên bản khác nhau** mà không ai biết |

<div class="keybox">
<span class="lbl">Quy tắc bắt buộc</span>
<p>Production <strong>luôn</strong> dùng tag cố định (<code>1.0.0</code>) hoặc digest. <code>latest</code> chỉ dùng cho môi trường dev, nơi hỏng cũng không sao.</p>
</div>

## Tag và digest khác nhau ra sao

| | **Tag** | **Digest** |
|---|---|---|
| Ai đặt | Con người | **Máy tự tính** từ nội dung |
| Đổi được không | **Có** — push đè là đổi | **Không thể** |
| Dùng khi | Chọn bản để triển khai | **Chứng minh** đúng nội dung đã kiểm duyệt |

> **Ẩn dụ:** tag là **nhãn dán trên hộp** — bóc ra dán sang hộp khác được. Digest là **vân tay của thứ bên trong hộp** — không thể giả.

## PAT và `GITHUB_TOKEN`

| | **PAT cá nhân** | **`GITHUB_TOKEN`** |
|---|---|---|
| Ai tạo | Bạn tạo bằng tay | GitHub **tự sinh cho từng job** |
| Sống bao lâu | Tới khi thu hồi — có thể **nhiều năm** | **Hết job là chết** |
| Quyền hạn | Theo checkbox, thường quá rộng | Khai báo `permissions:` trong YAML |
| Lộ ra ngoài | Kẻ xấu dùng được **tới khi bạn phát hiện** | Gần như vô dụng — token đã chết |

> ⚠️ **Ba điều tuyệt đối không làm với token:**
> 1. Không dán vào Dockerfile, YAML, `.env` bị commit, ảnh slide hay log
> 2. Không dùng mật khẩu tài khoản GitHub thay token
> 3. Không gõ token thẳng vào lệnh — dùng `--password-stdin`

---

# Phần 4 · Dùng image từ Registry trong CI

## Luồng bốn bước

```
cấp quyền  →  đăng nhập  →  pull  →  chạy thử và kiểm tra
```

```yaml
permissions:
  packages: read              # quyền tối thiểu: CHỈ ĐỌC

steps:
  - uses: docker/login-action@v3
    with:
      registry: ghcr.io
      username: ${{ github.actor }}
      password: ${{ secrets.GITHUB_TOKEN }}

  - run: |
      docker pull "$IMAGE_REF"
      docker image inspect "$IMAGE_REF"
```

## Pull về rồi phải chạy thử

Pull được **chỉ chứng minh tải về được**. Image có thể tải về ngon lành nhưng khởi động là sập.

```yaml
- run: |
    docker run -d --name verify_user_service -p 8081:8081 "$IMAGE_REF"

    for i in {1..12}; do
      curl --fail http://localhost:8081/actuator/health && exit 0
      sleep 5
    done
    docker logs verify_user_service && exit 1

- name: Dọn container
  if: always()
  run: docker rm -f verify_user_service || true
```

<div class="keybox">
<span class="lbl">Vì sao phải có vòng lặp chờ?</span>
<p><code>docker run -d</code> trả về <strong>ngay lập tức</strong> — nó chỉ báo "container đã được tạo", <strong>không phải</strong> "ứng dụng đã sẵn sàng". Spring Boot cần thêm 10–20 giây.</p>
<p>Gọi <code>curl</code> ngay sau đó thì gần như chắc chắn nhận <code>Connection refused</code>.</p>
</div>

| Cách xử lý | Vấn đề |
|---|---|
| `sleep 30` rồi curl | Máy nhanh thì phí 20 giây, máy chậm vẫn fail |
| **Vòng lặp 12 lần × 5 giây** | **Tốt** — sẵn sàng lúc nào đi tiếp lúc đó |
| `HEALTHCHECK` trong Dockerfile | Tốt nhất, để dành bài nâng cao |

> 💡 **`if: always()` là thói quen tốt.** Không có nó, khi health check fail thì bước dọn bị bỏ qua, container rác nằm lại trên Runner. Với self-hosted runner, rác tích tụ cho tới khi **đầy đĩa**.

---

# Tự kiểm tra

<details class="q"><summary><span>Session 08 khác Session 07 ở sản phẩm cuối là gì?</span></summary>
<div class="ans">
<p>Session 07 tạo ra <strong>file JAR</strong> lưu trong <strong>Artifact</strong> — tạm bợ, 3–7 ngày là tự xoá, phải tải tay, máy đích vẫn phải tự cài Java.</p>
<p>Session 08 tạo ra <strong>Docker image</strong> lưu trên <strong>Registry</strong> — lâu dài, có phiên bản, <code>docker pull</code> về là chạy được ngay vì Java nằm sẵn trong image.</p>
</div></details>

<details class="q"><summary><span>Vì sao không nên build image ở máy cá nhân?</span></summary>
<div class="ans">
<p>Vì image có thể được tạo từ code <strong>đang sửa dở</strong>, chưa commit. Khi đó image trên Registry <strong>không tương ứng với bất kỳ commit nào</strong> — gọi là "lệch pha".</p>
<p>Nguy hiểm ở chỗ <strong>không ai phát hiện ra</strong>: image vẫn chạy được, vẫn có vẻ đúng. Chỉ khi cần truy vết mới biết không lần về đâu được.</p>
</div></details>

<details class="q"><summary><span>Multi-stage có mấy tầng, mỗi tầng dùng base image gì?</span></summary>
<div class="ans">
<p><strong>Hai tầng.</strong> Tầng <code>builder</code> dùng <strong>JDK</strong> (có trình biên dịch) để chạy <code>./gradlew bootJar</code>. Tầng <code>runtime</code> dùng <strong>JRE</strong> (chỉ chạy được) và chỉ nhận đúng file JAR.</p>
</div></details>

<details class="q"><summary><span>Vì sao mã nguồn không có trong image cuối?</span></summary>
<div class="ans">
<p>Vì <strong>mỗi <code>FROM</code> bắt đầu một image hoàn toàn mới, từ số không</strong>. Tầng runtime không kế thừa gì từ tầng builder.</p>
<p><code>COPY --from=builder</code> là <strong>cây cầu duy nhất</strong> — chỉ những gì bạn chép sang mới đi qua được. Tầng builder chứa mã nguồn bị vứt bỏ hoàn toàn.</p>
</div></details>

<details class="q"><summary><span>Vì sao chép <code>build.gradle</code> trước <code>src/</code>?</span></summary>
<div class="ans">
<p>Vì Docker cache theo layer, và <strong>một layer đổi thì mọi layer phía sau phải làm lại</strong>.</p>
<p><code>build.gradle</code> ít thay đổi nên layer tải thư viện được tái dùng. <code>src/</code> đổi liên tục nên để cuối — sửa code chỉ phải chạy lại bước đóng gói, không phải tải lại 100MB thư viện.</p>
</div></details>

<details class="q"><summary><span>Tag và digest khác nhau ở đâu?</span></summary>
<div class="ans">
<p><strong>Tag</strong> do con người đặt, <strong>có thể bị ghi đè</strong> bất cứ lúc nào — như nhãn dán trên hộp.</p>
<p><strong>Digest</strong> là mã băm máy tự tính từ nội dung, <strong>không thể đổi</strong> — như vân tay của thứ bên trong hộp. Đổi nội dung là ra digest khác.</p>
</div></details>

<details class="q"><summary><span>Vì sao <code>latest</code> nguy hiểm ở production?</span></summary>
<div class="ans">
<p>Vì <code>latest</code> <strong>không có nghĩa là "bản mới nhất"</strong> — nó chỉ là một cái tên trỏ tới bản cuối cùng có ai đó push kèm nhãn đó.</p>
<p>Ba hậu quả: đồng nghiệp push bản lỗi thì production tự lấy bản lỗi khi restart; cần rollback thì không còn nhãn nào trỏ tới bản cũ; hai máy pull cách nhau một giờ có thể chạy hai phiên bản khác nhau.</p>
</div></details>

<details class="q"><summary><span>Trong CI nên dùng PAT hay <code>GITHUB_TOKEN</code>?</span></summary>
<div class="ans">
<p><strong><code>GITHUB_TOKEN</code></strong>. Nó được GitHub tự sinh cho <strong>từng job</strong> và <strong>chết ngay khi job kết thúc</strong>. Lộ ra ngoài cũng gần như vô dụng.</p>
<p>PAT sống nhiều năm, quyền thường quá rộng, và lộ ra là kẻ xấu dùng được tới khi bạn phát hiện. PAT chỉ dùng ở máy cá nhân, nơi không có <code>GITHUB_TOKEN</code>.</p>
</div></details>

<details class="q"><summary><span>Vì sao pull image xong phải chạy thử?</span></summary>
<div class="ans">
<p>Vì pull được <strong>chỉ chứng minh tải về được</strong>. Image có thể tải ngon lành nhưng khởi động là sập — thiếu biến môi trường, sai phiên bản Java, không kết nối được database.</p>
<p>Phải chạy container và gọi <code>/actuator/health</code> mới chứng minh được image <strong>dùng được</strong>.</p>
</div></details>

<details class="q"><summary><span>Vì sao gọi <code>curl</code> ngay sau <code>docker run -d</code> thì thất bại?</span></summary>
<div class="ans">
<p>Vì <code>docker run -d</code> trả về <strong>ngay lập tức</strong>, chỉ báo "container đã được tạo" chứ không phải "ứng dụng đã sẵn sàng". Spring Boot cần thêm 10–20 giây để khởi động Tomcat và kết nối database.</p>
<p>Giải pháp: vòng lặp thử lại 12 lần, mỗi lần cách 5 giây — sẵn sàng lúc nào thì đi tiếp lúc đó.</p>
</div></details>

---

# Bảng tra nhanh

| Việc | Lệnh |
|---|---|
| Build image multi-stage | `docker build --platform linux/amd64 -t user-service:1.0.0 .` |
| Xem lịch sử layer | `docker history user-service:1.0.0` |
| Xem bên trong image | `docker run --rm --platform linux/amd64 --entrypoint sh user-service:1.0.0 -c "ls -la /app"` |
| Đăng nhập GHCR | `printf '%s' "$CR_PAT" \| docker login ghcr.io -u <user> --password-stdin` |
| Gắn tag | `docker tag user-service:1.0.0 ghcr.io/<ns>/user-service:1.0.0` |
| Đẩy lên | `docker push ghcr.io/<ns>/user-service:1.0.0` |
| Kéo về | `docker pull --platform linux/amd64 ghcr.io/<ns>/user-service:1.0.0` |
| Xem digest | `docker image inspect <image> --format '{{index .RepoDigests 0}}'` |

> 💡 **Vì sao lệnh nào cũng có `--platform linux/amd64`?** Vì image nền chỉ có bản amd64. Trên Mac Apple Silicon cờ này **bắt buộc**; trên Ubuntu/Windows/Mac Intel nó **vô hại**. Để nguyên thì lệnh chạy được ở **mọi máy**.
>
> 💡 Bảng lệnh **đầy đủ** kèm 8 thí nghiệm gây lỗi nằm ở file **`S8-02-Lab-thuc-hanh.html`**.

---

# Bảy cặp khái niệm hay nhầm

| Cặp | Khác nhau ở chỗ |
|---|---|
| Artifact ↔ Registry | File tạm, tải tay ↔ image lâu dài, `docker pull` |
| Single-stage ↔ Multi-stage | Cần JAR sẵn ↔ tự biên dịch, image sạch |
| JDK ↔ JRE | Biên dịch được ↔ chỉ chạy được |
| Tag ↔ Digest | Nhãn dán, đổi được ↔ vân tay nội dung, không đổi được |
| PAT ↔ `GITHUB_TOKEN` | Bạn tạo, sống lâu ↔ tự sinh theo job, chết ngay |
| `docker build` ↔ `docker push` | Tạo image ở máy ↔ đẩy lên Registry |
| Local push ↔ CI publish | Để học CLI ↔ để phát hành thật |

---

# Bài tập về nhà

<div class="grid2">
<div class="card">
<h4>Bài 1 · Bắt buộc</h4>
<p>Viết Dockerfile multi-stage cho <code>restaurant-service</code> dùng <strong>Java 21</strong>. Chỉ rõ những dòng nào phải đổi so với <code>user-service</code> và vì sao.</p>
</div>
<div class="card">
<h4>Bài 2 · Bắt buộc</h4>
<p>Build cả <code>Dockerfile.single</code> và bản multi-stage. Chạy <code>docker image ls</code> và <code>docker history</code> cho cả hai, lập bảng so sánh: dung lượng, số layer, và <strong>những gì có mặt trong runtime</strong>.</p>
</div>
<div class="card">
<h4>Bài 3 · Bắt buộc</h4>
<p>Cố tình đảo thứ tự — đặt <code>COPY src ./src</code> lên <strong>trước</strong> <code>COPY build.gradle</code>. Build hai lần, đo thời gian lần thứ hai. Giải thích con số quan sát được.</p>
</div>
<div class="card ok">
<h4>Bài 4 · Nâng cao</h4>
<p>Thêm <code>HEALTHCHECK</code> vào Dockerfile để chính Docker tự kiểm tra sức khoẻ container. So sánh với cách dùng vòng lặp <code>curl</code> — mỗi cách mạnh ở đâu.</p>
</div>
</div>

<div class="card ok" style="margin:17px 0">
<h4>Bài 5 · Nâng cao</h4>
<p>Tìm hiểu cách pull image <strong>bằng digest</strong> thay vì tag. Giải thích vì sao hệ thống production nghiêm túc lại triển khai theo digest.</p>
</div>

---

# Checklist trước khi rời lớp

- [ ] Giải thích được Session 08 khác Session 07 ở sản phẩm cuối
- [ ] Phân biệt được Artifact và Registry
- [ ] Giải thích được "lệch pha" và vì sao build trong CI thì không thể lệch pha
- [ ] Đọc hiểu Dockerfile multi-stage, chỉ ra tầng nào JDK, tầng nào JRE
- [ ] Giải thích được vì sao mã nguồn không có trong image cuối
- [ ] Giải thích được vì sao thứ tự `COPY` quyết định tốc độ build
- [ ] Đọc được cấu trúc tên image: registry / namespace / tên / tag
- [ ] Phân biệt được tag và digest
- [ ] Giải thích được vì sao `latest` nguy hiểm ở production
- [ ] So sánh được PAT và `GITHUB_TOKEN`
- [ ] Giải thích được vì sao pull xong phải chạy thử và cần vòng lặp chờ
- [ ] Hiểu tác dụng của `if: always()`
