# TÀI LIỆU HỌC — SESSION 04

<div class="hero">
<div class="tri"></div>
<h1>Dockerfile &amp; Docker Compose</h1>
<p class="sub">Đóng gói một dịch vụ Spring Boot và dựng cả hệ thống nhiều container — qua dự án <strong>QuickBite</strong>.</p>
<p style="margin:14px 0 0"><span class="pill">Session 04</span><span class="pill s">Thời lượng 3 tiếng</span><span class="pill g">Có bài tập tự kiểm tra</span></p>
</div>

## Sau buổi học này, bạn sẽ làm được gì?

<div class="grid2">
<div class="card">
<h4>1 · Viết được Dockerfile</h4>
<p>Đóng gói một service Spring Boot thành image chạy được ở bất cứ máy nào — không còn cảnh "máy tao chạy được mà".</p>
</div>
<div class="card">
<h4>2 · Viết được docker-compose.yml</h4>
<p>Khai báo cả cụm Database + Backend trong một file, bật lên bằng <strong>một lệnh duy nhất</strong>.</p>
</div>
<div class="card ok">
<h4>3 · Kết nối các container</h4>
<p>Hiểu vì sao container gọi nhau bằng <strong>tên</strong> chứ không bằng địa chỉ IP, và giữ dữ liệu không bị mất.</p>
</div>
<div class="card ok">
<h4>4 · Vận hành hệ thống</h4>
<p>Bật, tắt, xem log, tìm lỗi — và quan trọng nhất: biết lệnh nào sẽ <strong>xoá sạch dữ liệu</strong>.</p>
</div>
</div>

---

# Bối cảnh: dự án QuickBite

QuickBite là ứng dụng đặt đồ ăn. Ở buổi này ta dựng **3 thành phần** chạy trên máy cá nhân:

<figure class="dg">
<svg viewBox="0 0 700 300" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Sơ đồ ba container của QuickBite">
  <rect x="8" y="8" width="684" height="284" rx="14" fill="#F9FAFC" stroke="#E3E7EC"/>
  <text x="26" y="34" font-family="Inter,sans-serif" font-size="13" font-weight="700" fill="#5B6572">QuickBite · chạy trên máy của bạn</text>

  <rect x="52" y="58" width="252" height="78" rx="11" fill="#fff" stroke="#BD2728" stroke-width="2"/>
  <text x="178" y="86" text-anchor="middle" font-family="Inter,sans-serif" font-size="15" font-weight="750" fill="#1B1F24">user-service</text>
  <text x="178" y="107" text-anchor="middle" font-family="Inter,sans-serif" font-size="12.5" fill="#5B6572">Java 17 · cổng 8081</text>
  <text x="178" y="125" text-anchor="middle" font-family="Inter,sans-serif" font-size="12" fill="#8A929C">quản lý người dùng</text>

  <rect x="396" y="58" width="252" height="78" rx="11" fill="#fff" stroke="#BD2728" stroke-width="2"/>
  <text x="522" y="86" text-anchor="middle" font-family="Inter,sans-serif" font-size="15" font-weight="750" fill="#1B1F24">restaurant-service</text>
  <text x="522" y="107" text-anchor="middle" font-family="Inter,sans-serif" font-size="12.5" fill="#5B6572">Java 21 · cổng 8082</text>
  <text x="522" y="125" text-anchor="middle" font-family="Inter,sans-serif" font-size="12" fill="#8A929C">quản lý nhà hàng</text>

  <path d="M178 136 L178 176 L350 176 L350 200" fill="none" stroke="#44546A" stroke-width="2"/>
  <path d="M522 136 L522 176 L350 176" fill="none" stroke="#44546A" stroke-width="2"/>
  <path d="M344 194 L350 204 L356 194 Z" fill="#44546A"/>

  <rect x="224" y="204" width="252" height="70" rx="11" fill="#E8F5E9" stroke="#2E7D32" stroke-width="2"/>
  <text x="350" y="232" text-anchor="middle" font-family="Inter,sans-serif" font-size="15" font-weight="750" fill="#1B3A1E">quickbite-db</text>
  <text x="350" y="253" text-anchor="middle" font-family="Inter,sans-serif" font-size="12.5" fill="#3B5C3E">PostgreSQL 15 · cổng 5432</text>

  <text x="366" y="170" font-family="Inter,sans-serif" font-size="11.5" font-style="italic" fill="#8A929C">cùng nối vào 1 database</text>
</svg>
<figcaption>Ba container độc lập, nói chuyện với nhau qua mạng ảo do Docker tạo ra.</figcaption>
</figure>

<div class="keybox">
<span class="lbl">Để ý điểm này</span>
<p>Hai service dùng <strong>hai phiên bản Java khác nhau</strong>: 17 và 21. Nếu cài trực tiếp lên máy, bạn phải đổi <code>JAVA_HOME</code> qua lại mỗi lần chuyển service. Với container, <strong>mỗi service mang theo Java riêng của nó</strong> — không đụng nhau, không đụng cả máy bạn.</p>
</div>

---

# Phần 1 · Vì sao cần Dockerfile?

## Hãy thử làm theo cách thủ công trước

Giả sử chưa biết Dockerfile. Để chạy QuickBite, bạn phải gõ:

```bash
# Bước 1: bật Database
docker run -d --name quickbite-db -e POSTGRES_PASSWORD=secret postgres:15-alpine

# Bước 2: đi tìm địa chỉ IP của container database vừa chạy
docker inspect quickbite-db
# Giả sử tìm được: 172.17.0.2

# Bước 3: bật User Service — nhét cứng cái IP vừa tìm được vào
docker run -d --name user-service -p 8081:8081 \
  -v /path/to/user-service/build/libs:/app -w /app \
  -e DB_HOST=172.17.0.2 -e DB_PORT=5432 \
  -e DB_NAME=quickbite_user_db \
  -e DB_USERNAME=quickbite_user -e DB_PASSWORD=quickbite_user \
  eclipse-temurin:17-jre-alpine java -jar user-service.jar
```

Nhìn có vẻ chạy được. Nhưng có **3 vấn đề nghiêm trọng**:

<div class="grid3">
<div class="card no">
<h4>Khó quản lý</h4>
<p>Phiên bản Java, số cổng, tên biến… nằm rải rác trong lịch sử terminal. Người mới vào dự án <strong>không có cách nào biết</strong> hệ thống thực sự cần gì.</p>
</div>
<div class="card no">
<h4>Dễ sai sót</h4>
<p>Lệnh dài 6–8 dòng. Gõ nhầm <code>DB_USERNAME</code> thành <code>DB_USER</code> là mất cả buổi chiều đi tìm lỗi.</p>
</div>
<div class="card no">
<h4>Thiếu ổn định</h4>
<p><code>172.17.0.2</code> là IP <strong>động</strong>. Container DB restart một cái là Docker cấp IP khác → app mất kết nối, dù bạn <strong>không sửa một dòng code nào</strong>.</p>
</div>
</div>

<div class="keybox">
<span class="lbl">Thử ngay trên máy</span>
<p>Chạy <code>docker inspect quickbite-db</code> ghi lại IP. Rồi <code>docker compose down &amp;&amp; docker compose up -d</code> và inspect lại. Bạn sẽ thấy IP đổi. <strong>Đây chính là lý do không bao giờ được nhét cứng IP vào cấu hình.</strong></p>
</div>

## Giải pháp: gom tất cả vào Dockerfile

**Dockerfile là tờ "công thức nấu ăn"** mô tả cách dựng môi trường chạy cho một dịch vụ. Nó nằm **ngay trong mã nguồn**, được quản lý bởi Git như mọi file code khác.

Nhờ vậy:

- Ai clone repo về cũng dựng được môi trường **giống hệt**.
- Nâng Java 17 → 21 trở thành **một commit**, có review, có lịch sử.
- Không còn câu *"máy tao chạy được mà"*.

## Đọc Dockerfile — chỉ 5 dòng

```dockerfile
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY build/libs/user-service.jar app.jar
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
```

Đọc như một câu chuyện, từ trên xuống:

<div class="grid2">
<div class="card">
<h4><span class="stepnum">1</span>FROM</h4>
<p><em>"Bắt đầu từ một máy Linux tí hon đã cài sẵn Java 17."</em></p>
<p>Bạn không dựng từ số 0 — bạn đứng trên vai người khác.</p>
</div>
<div class="card">
<h4><span class="stepnum">2</span>WORKDIR</h4>
<p><em>"Tạo thư mục <code>/app</code> và bước vào đó làm việc."</em></p>
<p>Giống lệnh <code>cd</code>. Mọi bước sau tính từ đây.</p>
</div>
<div class="card">
<h4><span class="stepnum">3</span>COPY</h4>
<p><em>"Chép file JAR từ máy tôi vào trong hộp, đặt tên là <code>app.jar</code>."</em></p>
<p>Đây là bước đưa <strong>code của bạn</strong> vào image.</p>
</div>
<div class="card">
<h4><span class="stepnum">4</span>EXPOSE</h4>
<p><em>"Dán nhãn: dịch vụ này nghe ở cổng 8081."</em></p>
<p>Chỉ là <strong>tờ nhãn dán</strong> — nó KHÔNG mở cổng. Xem kỹ phần dưới.</p>
</div>
</div>

<div class="card" style="margin:17px 0">
<h4><span class="stepnum">5</span>ENTRYPOINT</h4>
<p><em>"Khi hộp được bật lên, chạy lệnh <code>java -jar app.jar</code>."</em></p>
<p>Đây là <strong>trái tim của container</strong>. Tiến trình này sống thì container sống; nó kết thúc thì container tắt. Nhớ viết dạng mảng JSON <code>["java","-jar","app.jar"]</code> chứ đừng viết thành chuỗi — lý do ở ghi chú bên dưới.</p>
</div>

> **Vì sao `jre-alpine` mà không phải `jdk`?**
> `jdk` có cả trình biên dịch (~450MB), `jre` chỉ có phần *chạy* (~180MB). Code đã biên dịch thành JAR rồi, container không cần compile lại. `alpine` là bản Linux siêu nhẹ (~5MB) thay cho Debian (~120MB).
> Image nhỏ ⇒ tải nhanh hơn ⇒ deploy nhanh hơn ⇒ ít lỗ hổng bảo mật hơn. **Ba lợi ích chỉ từ việc chọn đúng tag.**

> ⚠️ **Vì sao ENTRYPOINT phải viết dạng mảng?**
> Viết `ENTRYPOINT ["java","-jar","app.jar"]` → `java` là tiến trình số 1, nhận được tín hiệu dừng khi bạn gõ `docker stop` → Spring Boot kịp đóng kết nối database, ghi nốt log rồi mới tắt.
> Viết `ENTRYPOINT java -jar app.jar` (dạng chuỗi) → `/bin/sh` mới là tiến trình số 1, tín hiệu dừng **không truyền xuống Java** → sau 10 giây container bị giết ngang, mất dữ liệu đang xử lý.

## EXPOSE và -p — chỗ nhầm nhiều nhất

<figure class="dg">
<svg viewBox="0 0 700 250" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="So sánh EXPOSE và cờ -p">
  <text x="170" y="22" text-anchor="middle" font-family="Inter,sans-serif" font-size="13.5" font-weight="750" fill="#B06000">Chỉ có EXPOSE 8081</text>
  <rect x="24" y="36" width="292" height="190" rx="12" fill="#FFF8F0" stroke="#E5C9A6"/>
  <circle cx="72" cy="92" r="21" fill="#fff" stroke="#8A929C" stroke-width="1.6"/>
  <text x="72" y="97" text-anchor="middle" font-size="17">🌐</text>
  <text x="72" y="130" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" fill="#5B6572">Trình duyệt</text>
  <rect x="186" y="62" width="104" height="112" rx="9" fill="#fff" stroke="#BD2728" stroke-width="1.8"/>
  <text x="238" y="88" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" font-weight="700" fill="#1B1F24">container</text>
  <text x="238" y="112" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" fill="#5B6572">app chạy</text>
  <text x="238" y="130" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" fill="#5B6572">bình thường</text>
  <text x="238" y="152" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" fill="#2E7D32">✓ :8081</text>
  <line x1="98" y1="92" x2="176" y2="92" stroke="#C9553B" stroke-width="2.2" stroke-dasharray="6 5"/>
  <line x1="128" y1="76" x2="150" y2="108" stroke="#C9553B" stroke-width="3"/>
  <line x1="150" y1="76" x2="128" y2="108" stroke="#C9553B" stroke-width="3"/>
  <text x="170" y="206" text-anchor="middle" font-family="Inter,sans-serif" font-size="12" font-weight="650" fill="#B06000">Không vào được — cổng vẫn đóng</text>

  <text x="530" y="22" text-anchor="middle" font-family="Inter,sans-serif" font-size="13.5" font-weight="750" fill="#2E7D32">Thêm cờ -p 8081:8081</text>
  <rect x="384" y="36" width="292" height="190" rx="12" fill="#F2FAF3" stroke="#BFE0C3"/>
  <circle cx="432" cy="92" r="21" fill="#fff" stroke="#8A929C" stroke-width="1.6"/>
  <text x="432" y="97" text-anchor="middle" font-size="17">🌐</text>
  <text x="432" y="130" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" fill="#5B6572">Trình duyệt</text>
  <rect x="546" y="62" width="104" height="112" rx="9" fill="#fff" stroke="#BD2728" stroke-width="1.8"/>
  <text x="598" y="88" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" font-weight="700" fill="#1B1F24">container</text>
  <text x="598" y="112" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" fill="#5B6572">app chạy</text>
  <text x="598" y="130" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" fill="#5B6572">bình thường</text>
  <text x="598" y="152" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" fill="#2E7D32">✓ :8081</text>
  <line x1="458" y1="92" x2="536" y2="92" stroke="#2E7D32" stroke-width="2.4"/>
  <path d="M530 86 L542 92 L530 98 Z" fill="#2E7D32"/>
  <text x="497" y="80" text-anchor="middle" font-family="Inter,sans-serif" font-size="10.5" fill="#2E7D32">cửa mở</text>
  <text x="530" y="206" text-anchor="middle" font-family="Inter,sans-serif" font-size="12" font-weight="650" fill="#2E7D32">Vào được</text>
</svg>
<figcaption>Trong cả hai trường hợp app đều chạy tốt. Khác nhau chỉ ở chỗ có mở cửa ra ngoài hay không.</figcaption>
</figure>

| | `EXPOSE 8081` trong Dockerfile | `-p 8081:8081` khi chạy |
|---|---|---|
| Bản chất | Tờ nhãn dán, để người đọc biết | Mở cổng thật trên máy bạn |
| Có mở cổng không? | **KHÔNG** | **CÓ** |
| Bỏ đi thì sao? | Vẫn chạy bình thường | Không vào được từ trình duyệt |

<div class="keybox">
<span class="lbl">Câu thần chú</span>
<p><strong>EXPOSE là NÓI. Cờ -p là LÀM.</strong> Chỉ nói thôi thì cửa vẫn đóng.</p>
</div>

## Quy trình đóng gói — đúng thứ tự

```bash
./gradlew bootJar                                    # 1. Java → file JAR
docker build -t quickbite-user-service:v1 .          # 2. JAR → image
docker run -d -p 8081:8081 --name user-service \
  quickbite-user-service:v1                          # 3. image → container
docker logs -f user-service                          # 4. kiểm tra đã chạy chưa
```

> ⚠️ **Thứ tự này không được đảo.** Bước 2 cần file JAR do bước 1 tạo ra.
> Lỗi phổ biến nhất của sinh viên: sửa code Java xong build image ngay, **quên chạy `./gradlew bootJar`**. Kết quả: image mới tinh nhưng bên trong là JAR cũ → *"code em sửa rồi mà sao không chạy?"*

---

# Phần 2 · Từ 1 container đến cả hệ thống

## Vì sao chia nhỏ thành nhiều container?

<div class="grid3">
<div class="card ok">
<h4>Đa dạng công nghệ</h4>
<p>user-service dùng Java 17, restaurant-service nâng lên Java 21 để dùng Virtual Threads. <strong>Nâng cấp một cái không cần đụng cái kia.</strong></p>
</div>
<div class="card ok">
<h4>Mở rộng độc lập</h4>
<p>Giờ cao điểm 11h–13h chỉ restaurant-service bị dồn request. Chạy 5 bản restaurant-service, giữ nguyên 1 user-service. Monolith thì phải nhân bản cả ứng dụng.</p>
</div>
<div class="card ok">
<h4>Cô lập lỗi</h4>
<p>restaurant-service tràn bộ nhớ và chết → người dùng <strong>vẫn đăng nhập, vẫn xem được đơn cũ</strong>. Chỉ mất chức năng tìm quán.</p>
</div>
</div>

## Nhưng quản lý thủ công thì rất cực

Chỉ với 3 container thôi:

- 3 lệnh `docker run` dài, phải chạy **đúng thứ tự** (DB trước, app sau)
- Phải `docker inspect` lấy IP rồi truyền tay sang lệnh tiếp theo
- Muốn dừng: 3 lệnh. Muốn xoá: 3 lệnh nữa

Dự án thật có 15 microservices. **Không thể làm bằng tay.**

## Docker Compose: đổi cách ra lệnh

<figure class="dg">
<svg viewBox="0 0 700 214" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="So sánh cách ra lệnh tuần tự và cách mô tả trạng thái">
  <rect x="16" y="14" width="316" height="184" rx="12" fill="#FFF8F0" stroke="#E5C9A6"/>
  <text x="174" y="42" text-anchor="middle" font-family="Inter,sans-serif" font-size="14" font-weight="780" fill="#B06000">Cách cũ — ra lệnh từng bước</text>
  <text x="174" y="66" text-anchor="middle" font-family="Inter,sans-serif" font-size="12" font-style="italic" fill="#7A6A52">"Rẽ trái, đi 200m, rồi rẽ phải…"</text>
  <rect x="44" y="84" width="260" height="25" rx="6" fill="#fff" stroke="#E0D2BE"/>
  <text x="56" y="101" font-family="monospace" font-size="11.5" fill="#5B6572">docker run … quickbite-db</text>
  <rect x="44" y="114" width="260" height="25" rx="6" fill="#fff" stroke="#E0D2BE"/>
  <text x="56" y="131" font-family="monospace" font-size="11.5" fill="#5B6572">docker inspect … (tìm IP)</text>
  <rect x="44" y="144" width="260" height="25" rx="6" fill="#fff" stroke="#E0D2BE"/>
  <text x="56" y="161" font-family="monospace" font-size="11.5" fill="#5B6572">docker run … user-service</text>
  <text x="174" y="187" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" font-weight="650" fill="#B06000">Bạn phải nhớ thứ tự</text>

  <rect x="368" y="14" width="316" height="184" rx="12" fill="#F2FAF3" stroke="#BFE0C3"/>
  <text x="526" y="42" text-anchor="middle" font-family="Inter,sans-serif" font-size="14" font-weight="780" fill="#2E7D32">Cách mới — mô tả kết quả</text>
  <text x="526" y="66" text-anchor="middle" font-family="Inter,sans-serif" font-size="12" font-style="italic" fill="#4A6B4D">"Đưa tôi tới số 5 Nguyễn Trãi."</text>
  <rect x="396" y="84" width="260" height="55" rx="6" fill="#fff" stroke="#C6E2C9"/>
  <text x="408" y="103" font-family="monospace" font-size="11.5" fill="#5B6572">docker-compose.yml</text>
  <text x="408" y="124" font-family="monospace" font-size="11" fill="#8A929C">(mô tả hệ thống mong muốn)</text>
  <rect x="396" y="144" width="260" height="25" rx="6" fill="#2E7D32"/>
  <text x="526" y="161" text-anchor="middle" font-family="monospace" font-size="12" font-weight="700" fill="#fff">docker compose up</text>
  <text x="526" y="187" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" font-weight="650" fill="#2E7D32">Compose lo thứ tự giúp bạn</text>
</svg>
<figcaption>Bạn mô tả <em>hệ thống trông như thế nào</em>, Compose tự lo <em>làm thế nào để đạt được</em>.</figcaption>
</figure>

**Quy trình 3 bước:**

| | Bước | Việc phải làm |
|---|---|---|
| **01** | Đóng gói | Viết `Dockerfile` cho từng dịch vụ |
| **02** | Khai báo | Viết `docker-compose.yml` mô tả service, network, volume, biến môi trường |
| **03** | Vận hành | Gõ `docker compose up` — xong |

> 💡 **Lưu ý về tên lệnh:** dùng `docker compose` (có **khoảng trắng**) — đây là bản V2 hiện hành.
> Bản cũ `docker-compose` (có **gạch nối**) đã ngừng hỗ trợ từ tháng 7/2023.

---

# Phần 3 · Đọc hiểu file docker-compose.yml

## Bốn quy tắc YAML phải nhớ

<div class="grid2">
<div class="card no">
<h4>1 · Cấm dùng phím Tab</h4>
<p>Thụt lề bằng <strong>dấu cách</strong>, thống nhất <strong>2 space</strong> mỗi cấp. Dùng Tab là lỗi cú pháp ngay.</p>
</div>
<div class="card no">
<h4>2 · Thụt lề = quan hệ cha–con</h4>
<p>Sai thụt lề không phải "xấu code" mà là <strong>sai cấu trúc dữ liệu</strong>.</p>
</div>
<div class="card no">
<h4>3 · Dấu <code>-</code> là phần tử danh sách</h4>
<p><code>- "8081:8081"</code> nghĩa là một mục trong danh sách các cổng.</p>
</div>
<div class="card no">
<h4>4 · Sau dấu <code>:</code> phải có khoảng trắng</h4>
<p>Viết <code>image: postgres</code>, không viết <code>image:postgres</code>.</p>
</div>
</div>

> 💡 **Mẹo:** bật `"editor.renderWhitespace": "all"` trong VS Code để **nhìn thấy** dấu cách và Tab. Cài thêm extension YAML để được báo lỗi ngay khi gõ.

## Mổ xẻ một file thật

```yaml
version: '3.8'
services:                      # ① danh sách các container
  quickbite-user:              # ② tên service — cũng là "địa chỉ" trong mạng nội bộ
    build:                     # ③ tự đóng gói từ Dockerfile
      context: ./user-service
    ports:
      - "8081:8081"            # ④ "cổng_máy_bạn:cổng_trong_container"
    environment:
      - DB_HOST=quickbite-db   # ⑤ cấu hình truyền vào app
    networks:
      - quickbite-net          # ⑥ đấu vào mạng ảo nào
networks:
  quickbite-net:
    external: true             # ⑦ dùng mạng đã có sẵn, đừng tạo mới
```

| # | Dòng | Nghĩa là gì |
|---|---|---|
| ① | `services:` | Bắt đầu liệt kê các container trong cụm |
| ② | `quickbite-user:` | Tên service. **Cực kỳ quan trọng** — đây chính là tên mà container khác dùng để gọi tới |
| ③ | `build:` | "Đây là code của tôi, hãy tự build image." Dùng `image:` khi lấy đồ có sẵn như Postgres, Redis |
| ④ | `ports:` | Mở cổng ra máy thật. Vế **trái** là cổng bạn gõ trên trình duyệt |
| ⑤ | `environment:` | Cấu hình chuyển vào bên trong container cho app đọc |
| ⑥ | `networks:` | Container này nằm trong mạng ảo nào |
| ⑦ | `external: true` | "Mạng này đã tồn tại rồi, đừng tạo mới" → **bắt buộc bật stack database trước** |

> **`image` hay `build`?**
> Dùng `image:` khi lấy đồ người khác làm sẵn (Postgres, Redis, Nginx).
> Dùng `build:` khi đó là code của chính bạn.

## Vì sao Database phải tách riêng?

Trong project mẫu, Database nằm ở **một stack riêng**, bật lên **trước**, và hầu như không bao giờ tắt.

<div class="grid2">
<div class="card">
<h4>Backend rebuild liên tục</h4>
<p>Cả ngày bạn sửa code và restart backend hàng chục lần. Tách riêng thì database <strong>không bị dựng lại theo</strong> → nhanh hơn nhiều.</p>
</div>
<div class="card">
<h4>Tiết kiệm tài nguyên</h4>
<p><strong>Một</strong> container Postgres chứa nhiều database con cho từng service, thay vì mỗi service một container riêng.</p>
</div>
<div class="card no">
<h4>Bảo vệ dữ liệu ⭐</h4>
<p>Đây là lý do quan trọng nhất. Lỡ gõ <code>docker compose down -v</code> ở stack backend → dữ liệu database <strong>nằm ở stack khác nên không hề hấn gì</strong>.</p>
</div>
<div class="card">
<h4>Giống môi trường thật</h4>
<p>Lên production, đổi <code>DB_HOST</code> sang địa chỉ AWS RDS là xong. <strong>Không sửa một dòng code nào.</strong></p>
</div>
</div>

## Database tự tạo sẵn dữ liệu

File `init-db.sql`:

```sql
CREATE USER quickbite_user WITH PASSWORD 'quickbite_user';
CREATE DATABASE quickbite_user_db OWNER quickbite_user;
GRANT ALL PRIVILEGES ON DATABASE quickbite_user_db TO quickbite_user;
```

Trong compose, ta "gắn" file này vào một chỗ đặc biệt:

```yaml
volumes:
  - ./init-db.sql:/docker-entrypoint-initdb.d/init-db.sql
```

Image Postgres có quy ước: **mọi file `.sql` nằm trong thư mục `/docker-entrypoint-initdb.d/` sẽ được chạy tự động** khi container khởi động lần đầu. Nhờ vậy người mới clone repo về chỉ cần `docker compose up` là có sẵn database đúng cấu hình — không ai phải vào gõ tay.

> ⚠️ **Cái bẫy ai cũng dính một lần**
> Script này **chỉ chạy đúng MỘT LẦN**, khi thư mục dữ liệu còn rỗng.
> Bạn sửa `init-db.sql` rồi `docker compose restart` → **không có tác dụng gì cả**, vì dữ liệu đã tồn tại.
> Muốn chạy lại phải xoá sạch dữ liệu: `docker compose down -v` rồi `up` lại.

---

# Phần 4 · Mật khẩu và file .env

## Đừng bao giờ commit mật khẩu lên Git

Viết thẳng mật khẩu vào `docker-compose.yml` rồi push lên Git là **lỗi bảo mật nghiêm trọng**.

<div class="keybox">
<span class="lbl">Vì sao nghiêm trọng đến vậy?</span>
<p>Git lưu <strong>toàn bộ lịch sử</strong>. Bạn commit nhầm mật khẩu, rồi commit tiếp để xoá đi — mật khẩu <strong>vẫn nằm trong lịch sử</strong>, ai cũng đọc được bằng <code>git log -p</code>. Với repo public, các bot quét GitHub tìm ra trong <strong>vài phút</strong>. Đã có rất nhiều vụ hoá đơn cloud hàng chục nghìn đô phát sinh chỉ vì một khoá bị lộ như vậy.</p>
</div>

## Cách làm đúng: tách ra file .env

File `.env` (**không** commit lên Git):

```dotenv
DB_HOST=quickbite-db
DB_PORT=5432
USER_DB_NAME=quickbite_user_db
USER_DB_USERNAME=quickbite_user
USER_DB_PASSWORD=quickbite_user
USER_SERVER_PORT=8081
```

Trong `docker-compose.yml`, dùng `${TÊN_BIẾN}` để gọi ra:

```yaml
ports:
  - "${USER_SERVER_PORT}:${USER_SERVER_PORT}"
environment:
  - DB_HOST=${DB_HOST}
  - DB_PASSWORD=${USER_DB_PASSWORD}
```

Và **bắt buộc** có file `.gitignore`:

```gitignore
.env
```

Kèm theo một file mẫu `.env.example` **được** commit — có tên biến, không có giá trị thật. Người mới vào dự án chỉ cần `cp .env.example .env` rồi điền.

## Cấu hình đi qua 4 chặng

<figure class="dg">
<svg viewBox="0 0 700 132" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Chuỗi truyền cấu hình từ file env tới Spring Boot">
  <rect x="6" y="34" width="146" height="58" rx="9" fill="#fff" stroke="#BD2728" stroke-width="1.8"/>
  <text x="79" y="58" text-anchor="middle" font-family="monospace" font-size="12.5" font-weight="700" fill="#BD2728">.env</text>
  <text x="79" y="77" text-anchor="middle" font-family="Inter,sans-serif" font-size="10.5" fill="#5B6572">trên máy bạn</text>

  <rect x="188" y="34" width="146" height="58" rx="9" fill="#fff" stroke="#44546A" stroke-width="1.8"/>
  <text x="261" y="56" text-anchor="middle" font-family="monospace" font-size="11.5" font-weight="700" fill="#44546A">compose.yml</text>
  <text x="261" y="75" text-anchor="middle" font-family="monospace" font-size="11" fill="#5B6572">${...}</text>

  <rect x="370" y="34" width="146" height="58" rx="9" fill="#fff" stroke="#44546A" stroke-width="1.8"/>
  <text x="443" y="56" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" font-weight="700" fill="#44546A">biến trong</text>
  <text x="443" y="74" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" font-weight="700" fill="#44546A">container</text>

  <rect x="552" y="34" width="142" height="58" rx="9" fill="#E8F5E9" stroke="#2E7D32" stroke-width="1.8"/>
  <text x="623" y="56" text-anchor="middle" font-family="monospace" font-size="11.5" font-weight="700" fill="#1B3A1E">application</text>
  <text x="623" y="74" text-anchor="middle" font-family="monospace" font-size="11.5" font-weight="700" fill="#1B3A1E">.yml</text>

  <line x1="152" y1="63" x2="182" y2="63" stroke="#8A929C" stroke-width="2"/><path d="M178 58 L188 63 L178 68 Z" fill="#8A929C"/>
  <line x1="334" y1="63" x2="364" y2="63" stroke="#8A929C" stroke-width="2"/><path d="M360 58 L370 63 L360 68 Z" fill="#8A929C"/>
  <line x1="516" y1="63" x2="546" y2="63" stroke="#8A929C" stroke-width="2"/><path d="M542 58 L552 63 L542 68 Z" fill="#8A929C"/>

  <text x="350" y="118" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" font-style="italic" fill="#8A929C">Đổi giá trị ở chặng đầu, cả chuỗi tự đổi theo — không cần build lại JAR</text>
</svg>
</figure>

**Hai thứ rất dễ nhầm:**

| | File `.env` | Khối `environment:` |
|---|---|---|
| Ai đọc nó? | **Docker Compose** (trên máy bạn) | **Container** (app đọc) |
| Để làm gì? | Điền giá trị vào các chỗ `${...}` trong file YAML | Đưa biến vào bên trong container |
| App có thấy trực tiếp không? | Không | Có |

---

# Phần 5 · Dữ liệu và kết nối

## Volume — để dữ liệu không bốc hơi

<div class="keybox">
<span class="lbl">Sự thật cần biết</span>
<p>Mặc định, mọi thứ container ghi ra <strong>sẽ mất sạch khi container bị xoá</strong>. Với database thì đây là thảm hoạ. <strong>Volume</strong> sinh ra để giải quyết đúng chuyện này: nó là vùng lưu trữ nằm <em>ngoài</em> container, nên container chết đi dữ liệu vẫn còn.</p>
</div>

Có hai loại, dùng cho hai mục đích khác nhau:

<div class="grid2">
<div class="card ok">
<h4>Named Volume — Docker tự quản</h4>
<pre style="margin:9px 0"><code>volumes:
  - db-data:/var/lib/postgresql/data</code></pre>
<p>Bạn chỉ đặt <strong>tên</strong>, Docker tự lo cất ở đâu.</p>
<p><span class="pill g">Nhanh</span><span class="pill g">An toàn</span> → dùng cho <strong>dữ liệu database</strong>.</p>
</div>
<div class="card">
<h4>Bind Mount — bạn chỉ đường</h4>
<pre style="margin:9px 0"><code>volumes:
  - ./init-db.sql:/docker-entrypoint-initdb.d/init-db.sql</code></pre>
<p>Bạn trỏ thẳng tới một file/thư mục trên máy mình.</p>
<p><span class="pill s">Sửa được ngay</span> → dùng cho <strong>file cấu hình</strong>.</p>
</div>
</div>

> 💡 **Mẹo phân biệt trong 1 giây:** nhìn vế **bên trái** dấu hai chấm.
> Có dấu `/` hoặc `./` → **Bind Mount** (là đường dẫn).
> Chỉ là một cái tên trơn → **Named Volume**.

## Network — vì sao gọi nhau bằng tên?

Đây là phần trả lời trọn vẹn cho vấn đề "IP động" ở đầu buổi học.

<figure class="dg">
<svg viewBox="0 0 700 236" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Cơ chế Service Discovery bằng DNS nội bộ của Docker">
  <rect x="14" y="14" width="672" height="208" rx="13" fill="#F9FAFC" stroke="#E3E7EC" stroke-dasharray="7 5"/>
  <text x="34" y="40" font-family="Inter,sans-serif" font-size="12.5" font-weight="700" fill="#5B6572">mạng ảo: quickbite-net</text>

  <rect x="56" y="64" width="176" height="76" rx="10" fill="#fff" stroke="#BD2728" stroke-width="2"/>
  <text x="144" y="92" text-anchor="middle" font-family="Inter,sans-serif" font-size="13.5" font-weight="750" fill="#1B1F24">user-service</text>
  <text x="144" y="116" text-anchor="middle" font-family="monospace" font-size="11" fill="#5B6572">DB_HOST=quickbite-db</text>

  <rect x="286" y="76" width="128" height="52" rx="10" fill="#44546A"/>
  <text x="350" y="99" text-anchor="middle" font-family="Inter,sans-serif" font-size="12.5" font-weight="750" fill="#fff">DNS nội bộ</text>
  <text x="350" y="116" text-anchor="middle" font-family="Inter,sans-serif" font-size="10.5" fill="#C8D2DE">của Docker</text>

  <rect x="468" y="64" width="176" height="76" rx="10" fill="#E8F5E9" stroke="#2E7D32" stroke-width="2"/>
  <text x="556" y="92" text-anchor="middle" font-family="Inter,sans-serif" font-size="13.5" font-weight="750" fill="#1B3A1E">quickbite-db</text>
  <text x="556" y="116" text-anchor="middle" font-family="monospace" font-size="11" fill="#3B5C3E">172.21.0.2 (đổi liên tục)</text>

  <line x1="232" y1="102" x2="280" y2="102" stroke="#BD2728" stroke-width="2.2"/><path d="M276 97 L286 102 L276 107 Z" fill="#BD2728"/>
  <text x="256" y="92" text-anchor="middle" font-family="Inter,sans-serif" font-size="10" fill="#BD2728">hỏi tên</text>
  <line x1="414" y1="102" x2="462" y2="102" stroke="#2E7D32" stroke-width="2.2"/><path d="M458 97 L468 102 L458 107 Z" fill="#2E7D32"/>
  <text x="438" y="92" text-anchor="middle" font-family="Inter,sans-serif" font-size="10" fill="#2E7D32">trả IP</text>

  <rect x="112" y="168" width="476" height="40" rx="9" fill="#FDECEC" stroke="#F3C9C9"/>
  <text x="350" y="193" text-anchor="middle" font-family="Inter,sans-serif" font-size="12.5" font-weight="650" fill="#8C1D1A">IP đổi bao nhiêu lần cũng được — cái tên thì không bao giờ đổi</text>
</svg>
<figcaption>Bạn chỉ cần nhớ <strong>tên service</strong>. Phần IP để Docker lo.</figcaption>
</figure>

| Lúc đầu buổi (khổ sở) | Bây giờ (nhẹ nhàng) |
|---|---|
| `docker inspect quickbite-db` tìm IP | Không cần |
| `DB_HOST=172.17.0.2` — restart là hỏng | `DB_HOST=quickbite-db` — luôn đúng |

> ⚠️ **Bẫy chết người: `localhost` bên trong container KHÔNG phải máy của bạn.**
> Mỗi container có không gian mạng riêng, `localhost` của nó trỏ vào **chính nó**.
> ```
> user-service → quickbite-db:5432    ✅ ĐÚNG
> user-service → localhost:5432       ❌ SAI
> ```
> Đây là lỗi số một khi bạn copy file `application.yml` từ lúc chạy trực tiếp sang chạy bằng Docker.

---

# Phần 6 · Vận hành hệ thống

## Vòng đời của một cụm container

<figure class="dg">
<svg viewBox="0 0 700 204" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Sơ đồ vòng đời container">
  <rect x="26" y="74" width="132" height="56" rx="10" fill="#fff" stroke="#C3CAD3" stroke-width="1.8" stroke-dasharray="5 4"/>
  <text x="92" y="100" text-anchor="middle" font-family="Inter,sans-serif" font-size="12.5" font-weight="700" fill="#8A929C">chưa tồn tại</text>
  <text x="92" y="118" text-anchor="middle" font-family="Inter,sans-serif" font-size="10.5" fill="#A8AFB8">(máy sạch)</text>

  <rect x="278" y="74" width="132" height="56" rx="10" fill="#E8F5E9" stroke="#2E7D32" stroke-width="2"/>
  <text x="344" y="100" text-anchor="middle" font-family="Inter,sans-serif" font-size="13" font-weight="750" fill="#1B3A1E">ĐANG CHẠY</text>
  <text x="344" y="118" text-anchor="middle" font-family="Inter,sans-serif" font-size="10.5" fill="#3B5C3E">Up</text>

  <rect x="530" y="74" width="132" height="56" rx="10" fill="#FFF8F0" stroke="#E07C00" stroke-width="2"/>
  <text x="596" y="100" text-anchor="middle" font-family="Inter,sans-serif" font-size="13" font-weight="750" fill="#8A5000">ĐÃ DỪNG</text>
  <text x="596" y="118" text-anchor="middle" font-family="Inter,sans-serif" font-size="10.5" fill="#A06A20">Exited · dữ liệu còn</text>

  <line x1="158" y1="92" x2="272" y2="92" stroke="#2E7D32" stroke-width="2.2"/><path d="M268 87 L278 92 L268 97 Z" fill="#2E7D32"/>
  <text x="215" y="82" text-anchor="middle" font-family="monospace" font-size="11.5" font-weight="700" fill="#2E7D32">up -d</text>

  <line x1="410" y1="88" x2="524" y2="88" stroke="#E07C00" stroke-width="2.2"/><path d="M520 83 L530 88 L520 93 Z" fill="#E07C00"/>
  <text x="467" y="78" text-anchor="middle" font-family="monospace" font-size="11.5" font-weight="700" fill="#E07C00">stop</text>
  <line x1="524" y1="116" x2="410" y2="116" stroke="#2E7D32" stroke-width="2.2"/><path d="M414 111 L404 116 L414 121 Z" fill="#2E7D32"/>
  <text x="467" y="136" text-anchor="middle" font-family="monospace" font-size="11.5" font-weight="700" fill="#2E7D32">start</text>

  <path d="M344 130 L344 166 L92 166 L92 134" fill="none" stroke="#BD2728" stroke-width="2.2"/>
  <path d="M87 138 L92 128 L97 138 Z" fill="#BD2728"/>
  <text x="218" y="182" text-anchor="middle" font-family="monospace" font-size="11.5" font-weight="700" fill="#BD2728">down</text>
  <text x="272" y="182" font-family="Inter,sans-serif" font-size="10.5" fill="#8A929C">(xoá container, GIỮ dữ liệu)</text>
</svg>
</figure>

## ⚠️ Bảng phải học thuộc

| Lệnh | Container | Mạng ảo | **Dữ liệu database** |
|---|---|---|---|
| `docker compose stop` | Giữ lại (Exited) | Giữ | **Giữ** ✅ |
| `docker compose down` | Xoá | Xoá | **GIỮ** ✅ |
| `docker compose down -v` | Xoá | Xoá | **XOÁ SẠCH** ⚠️ |

> ⚠️⚠️ **Chữ `-v` nhỏ xíu nhưng xoá sạch toàn bộ dữ liệu.**
> Không hoàn tác được. Không có thùng rác. Không có Ctrl+Z.
> Đây chính là lý do ta **tách database ra một stack riêng** — để lỡ tay ở stack backend cũng không chạm được vào dữ liệu.

## `up` và `start` khác nhau thế nào?

| | `docker compose up` | `docker compose start` |
|---|---|---|
| Đọc lại file YAML? | **Có** | **Không** |
| Tạo container mới nếu chưa có? | Có | Không |
| Áp dụng thay đổi cấu hình? | Có | **Không** |

> 💡 Sửa file YAML rồi gõ `start` → **thay đổi không có tác dụng**. Phải dùng `up`.

## Thứ tự bật/tắt

<div class="keybox">
<span class="lbl">Quy tắc vàng</span>
<p><strong>Database lên TRƯỚC, xuống SAU.</strong> Vì stack database là bên <em>tạo ra</em> mạng ảo, còn backend chỉ <em>dùng nhờ</em>. Ai tạo ra tài nguyên thì phải sống lâu hơn người dùng tài nguyên đó.</p>
</div>

```bash
# Đầu ngày — bật
cd quickbite-db       && docker compose up -d
cd ../quickbite-backend && docker compose up -d --build

# Cuối ngày — tắt (thứ tự ngược lại)
cd quickbite-backend  && docker compose down
cd ../quickbite-db    && docker compose stop
```

Bật sai thứ tự sẽ gặp lỗi này — và đó là lỗi **hữu ích**, nó nhắc bạn đúng chỗ:

```
network quickbite-net declared as external, but could not be found
```

## Khi có lỗi: 4 bước thu hẹp phạm vi

Đừng đoán mò. Hãy loại trừ có hệ thống:

<div class="grid2">
<div class="card">
<h4><span class="stepnum">1</span>Container còn sống không?</h4>
<pre style="margin:9px 0"><code>docker compose ps</code></pre>
<p>Rẻ nhất, nhanh nhất. Thấy <code>Exited</code> thì mọi giả thuyết về code đều vô nghĩa.</p>
</div>
<div class="card">
<h4><span class="stepnum">2</span>App báo lỗi gì?</h4>
<pre style="margin:9px 0"><code>docker compose logs --tail=100</code></pre>
<p>Đọc dòng <code>Caused by:</code> <strong>cuối cùng</strong> — đó mới là nguyên nhân gốc.</p>
</div>
<div class="card">
<h4><span class="stepnum">3</span>Cấu hình thực tế là gì?</h4>
<pre style="margin:9px 0"><code>docker compose exec quickbite-user env</code></pre>
<p>Xem biến môi trường <strong>thật sự</strong> bên trong container. Đây là sự thật cuối cùng.</p>
</div>
<div class="card">
<h4><span class="stepnum">4</span>Mạng có thông không?</h4>
<pre style="margin:9px 0"><code>docker compose exec quickbite-user \
  ping -c 3 quickbite-db</code></pre>
<p>Ping fail → lỗi mạng. Ping OK mà app vẫn lỗi → lỗi cổng hoặc mật khẩu.</p>
</div>
</div>

---

# Tự kiểm tra

Trả lời trong đầu trước, rồi bấm để xem đáp án.

<details class="q"><summary><span><code>EXPOSE 8081</code> trong Dockerfile có mở cổng ra máy tôi không?</span></summary>
<div class="ans">
<p><strong>Không.</strong> Nó chỉ là tờ nhãn dán, mang tính tài liệu hoá. Muốn truy cập được từ trình duyệt, bắt buộc phải có <code>-p 8081:8081</code> khi chạy (hoặc khai báo <code>ports:</code> trong compose).</p>
</div></details>

<details class="q"><summary><span><code>docker compose down</code> có làm mất dữ liệu database không?</span></summary>
<div class="ans">
<p><strong>Không.</strong> Nó chỉ xoá container và mạng ảo; named volume vẫn còn nguyên.</p>
<p>Chỉ khi thêm cờ <code>-v</code> — tức <code>docker compose down -v</code> — thì volume mới bị xoá và <strong>dữ liệu mất sạch, không khôi phục được</strong>.</p>
</div></details>

<details class="q"><summary><span>Container A muốn gọi container B thì dùng địa chỉ gì?</span></summary>
<div class="ans">
<p>Dùng <strong>tên service</strong> khai báo trong <code>docker-compose.yml</code>, ví dụ <code>quickbite-db</code>.</p>
<p>Docker có sẵn DNS nội bộ, tự dịch tên đó thành IP hiện tại của container. Nhờ vậy IP có đổi bao nhiêu lần cũng không ảnh hưởng gì.</p>
</div></details>

<details class="q"><summary><span>Vì sao không được dùng <code>localhost</code> để container app gọi tới database?</span></summary>
<div class="ans">
<p>Vì mỗi container có không gian mạng riêng. Bên trong container app, <code>localhost</code> trỏ vào <strong>chính container đó</strong>, không phải máy thật và cũng không phải container database.</p>
<p>Phải dùng tên service: <code>DB_HOST=quickbite-db</code>.</p>
</div></details>

<details class="q"><summary><span>Sửa code Java xong cần chạy những lệnh gì?</span></summary>
<div class="ans">
<p>Hai lệnh, theo đúng thứ tự:</p>
<pre><code>./gradlew bootJar
docker compose up -d --build</code></pre>
<p>Thiếu lệnh đầu → JAR vẫn là bản cũ. Thiếu cờ <code>--build</code> → Compose dùng lại image cũ. Cả hai trường hợp đều dẫn tới <em>"em sửa rồi mà sao không chạy?"</em></p>
</div></details>

<details class="q"><summary><span>Tôi sửa <code>init-db.sql</code> nhưng chạy lại không thấy thay đổi. Vì sao?</span></summary>
<div class="ans">
<p>Vì PostgreSQL <strong>chỉ chạy script khởi tạo đúng một lần</strong> — khi thư mục dữ liệu còn rỗng. Volume của bạn đã có dữ liệu nên script bị bỏ qua.</p>
<p>Muốn chạy lại: <code>docker compose down -v &amp;&amp; docker compose up -d</code> (chấp nhận mất dữ liệu cũ).</p>
</div></details>

<details class="q"><summary><span><code>external: true</code> trong khối <code>networks</code> nghĩa là gì?</span></summary>
<div class="ans">
<p>Nghĩa là: <em>"mạng ảo này đã tồn tại sẵn rồi, đừng tạo mới, hãy gắn service của tôi vào đó."</em></p>
<p>Hệ quả: <strong>stack tạo ra mạng (database) phải được bật trước</strong>. Bật sai thứ tự sẽ báo <code>network ... could not be found</code>.</p>
</div></details>

<details class="q"><summary><span>Vì sao dữ liệu PostgreSQL bắt buộc phải để trong volume?</span></summary>
<div class="ans">
<p>Vì hệ thống file bên trong container là <strong>tạm thời</strong> — xoá container là mất sạch những gì đã ghi.</p>
<p>Volume nằm <em>ngoài</em> container nên sống sót qua các lần xoá và dựng lại container.</p>
</div></details>

---

# Bảng tra nhanh

| Việc cần làm | Lệnh |
|---|---|
| Kiểm tra file compose có lỗi cú pháp không | `docker compose config` |
| Bật cụm, chạy nền | `docker compose up -d` |
| Bật cụm + build lại image (sau khi sửa code) | `docker compose up -d --build` |
| Xem container nào đang chạy | `docker compose ps` |
| Xem log tất cả service, theo dõi realtime | `docker compose logs -f --tail=50` |
| Xem log riêng một service | `docker compose logs -f quickbite-user` |
| Chạy một lệnh bên trong container | `docker compose exec <service> <lệnh>` |
| Vào hẳn bên trong container xem xét | `docker compose exec <service> sh` |
| Tạm dừng, giữ nguyên container | `docker compose stop` |
| Xoá container + mạng, **giữ dữ liệu** | `docker compose down` |
| Xoá tất cả, **kể cả dữ liệu** ⚠️ | `docker compose down -v` |
| Kiểm tra PostgreSQL đã sẵn sàng chưa | `docker exec quickbite-db pg_isready -U postgres` |
| Liệt kê các database đang có | `docker compose exec quickbite-db psql -U postgres -c "\l"` |
| Xem Docker đang chiếm bao nhiêu dung lượng | `docker system df` |

> 💡 Bảng lệnh **đầy đủ**, kèm lý do dùng từng tham số và biến thể cho Windows / Ubuntu, nằm ở file **`02-Lab-Cac-lenh-thuc-hanh.html`**.

---

# Mười cặp khái niệm hay nhầm

| Cặp | Khác nhau ở chỗ nào |
|---|---|
| `EXPOSE` ↔ `-p` / `ports` | Dán nhãn ↔ mở cổng thật |
| `image` ↔ `build` | Lấy image có sẵn ↔ tự đóng gói từ Dockerfile |
| Named Volume ↔ Bind Mount | Docker tự quản ↔ bạn chỉ đường dẫn |
| `stop` ↔ `down` | Giữ container ↔ xoá container |
| `down` ↔ `down -v` | **Giữ dữ liệu** ↔ **xoá sạch dữ liệu** |
| `up` ↔ `start` | Đọc lại YAML & tạo mới ↔ chỉ bật lại |
| Ra lệnh tuần tự ↔ Mô tả trạng thái | `docker run` ↔ `docker-compose.yml` |
| `localhost` ↔ tên service | Chính container đó ↔ container khác trong cụm |
| `jdk` ↔ `jre` | Có trình biên dịch ↔ chỉ chạy được (nhẹ hơn nhiều) |
| `docker-compose` ↔ `docker compose` | Bản cũ đã ngừng hỗ trợ ↔ bản V2 hiện hành |

---

# Bài tập về nhà

<div class="grid2">
<div class="card">
<h4>Bài 1 · Bắt buộc</h4>
<p>Viết Dockerfile cho <code>restaurant-service</code> chạy <strong>Java 21</strong>, cổng <code>8082</code>. Thêm service này vào stack backend.</p>
</div>
<div class="card">
<h4>Bài 2 · Bắt buộc</h4>
<p>Mở rộng <code>init-db.sql</code> để tạo thêm user và database cho restaurant-service. Viết vào README: <strong>vì sao phải <code>down -v</code> thì script mới chạy lại?</strong></p>
</div>
<div class="card">
<h4>Bài 3 · Bắt buộc</h4>
<p>Chuyển toàn bộ giá trị cứng trong file compose sang <code>.env</code>. Tạo <code>.env.example</code> và thêm <code>.env</code> vào <code>.gitignore</code>.</p>
</div>
<div class="card ok">
<h4>Bài 4 · Nâng cao</h4>
<p>Tìm hiểu <code>depends_on</code> kết hợp <code>healthcheck</code>. Giải thích vì sao <code>depends_on</code> <strong>đứng một mình là không đủ</strong>.</p>
</div>
</div>

<div class="card ok" style="margin:17px 0">
<h4>Bài 5 · Nâng cao</h4>
<p>Tìm hiểu <strong>multi-stage build</strong>: viết Dockerfile tự chạy <code>gradle bootJar</code> ngay bên trong image, để không cần build JAR trên máy host nữa. So sánh kích thước image với cách hiện tại và giải thích chênh lệch.</p>
</div>

---

# Checklist trước khi rời lớp

Bạn đã **tự làm được** và **giải thích được** những điều sau chưa?

- [ ] Viết Dockerfile cho một service Spring Boot và giải thích được cả 5 chỉ thị
- [ ] Giải thích được khác nhau giữa `EXPOSE` và `-p`
- [ ] Viết `docker-compose.yml` có `build`, `ports`, `environment`, `networks`
- [ ] Giải thích được vì sao Database nên chạy ở stack riêng
- [ ] Tách được mật khẩu ra `.env` và biết vì sao phải làm vậy
- [ ] Phân biệt được Named Volume và Bind Mount
- [ ] Giải thích được vì sao container gọi nhau bằng tên chứ không bằng IP
- [ ] Nhớ chính xác: `stop` vs `down` vs `down -v` — cái nào mất dữ liệu
- [ ] Biết thứ tự bật/tắt đúng và lý do đằng sau
- [ ] Biết 4 bước thu hẹp phạm vi khi hệ thống lỗi
