# TÀI LIỆU HỌC — SESSION 05

<div class="hero">
<div class="tri"></div>
<h1>Multi-container System &amp; API Gateway</h1>
<p class="sub">Từ 2 container lên 4 microservices + 1 cửa ngõ — và những vấn đề mới chỉ xuất hiện ở quy mô đó.</p>
<p style="margin:14px 0 0"><span class="pill">Session 05</span><span class="pill s">Thời lượng 3 tiếng</span><span class="pill g">Có bài tập tự kiểm tra</span></p>
</div>

## Ba câu hỏi buổi học này trả lời

<div class="grid3">
<div class="card">
<h4>① Dữ liệu nằm ở đâu?</h4>
<p>Đơn hàng cần tên khách và tên món. Nhưng khách ở <strong>user-service</strong>, món ở <strong>restaurant-service</strong>. Ba database tách rời, không <code>JOIN</code> được.</p>
</div>
<div class="card">
<h4>② Client gọi ai?</h4>
<p>Có 4 service ở 4 cổng. App mobile phải nhớ cả 4 địa chỉ? Mỗi service tự kiểm tra token đăng nhập?</p>
</div>
<div class="card">
<h4>③ Nửa chừng hỏng thì sao?</h4>
<p>Đã trừ tiền ví khách, nhưng nhà hàng báo hết nguyên liệu. Hai database khác nhau, không có <code>ROLLBACK</code>. Tiền đi đâu?</p>
</div>
</div>

---

# QuickBite đã lớn lên

Session 04 dừng ở 2 container. Giờ là **4 microservices + 1 gateway**.

<figure class="dg">
<svg viewBox="0 0 760 420" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Kiến trúc QuickBite với API Gateway và 4 microservices">
  <rect x="300" y="8" width="160" height="46" rx="10" fill="#fff" stroke="#8A929C" stroke-width="1.6"/>
  <text x="380" y="30" text-anchor="middle" font-family="Inter,sans-serif" font-size="13.5" font-weight="700" fill="#1B1F24">Client</text>
  <text x="380" y="45" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" fill="#8A929C">app / web</text>

  <line x1="380" y1="54" x2="380" y2="78" stroke="#BD2728" stroke-width="2.4"/><path d="M374 74 L380 86 L386 74 Z" fill="#BD2728"/>

  <rect x="248" y="88" width="264" height="54" rx="11" fill="#FDECEC" stroke="#BD2728" stroke-width="2.4"/>
  <text x="380" y="110" text-anchor="middle" font-family="Inter,sans-serif" font-size="14.5" font-weight="780" fill="#8C1D1A">API GATEWAY</text>
  <text x="380" y="130" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" fill="#A0413F">cổng 8080 — cửa ngõ DUY NHẤT mở ra ngoài</text>

  <path d="M380 142 L380 168" stroke="#44546A" stroke-width="2"/>
  <path d="M96 168 L664 168" stroke="#44546A" stroke-width="2"/>
  <g stroke="#44546A" stroke-width="2">
    <line x1="96" y1="168" x2="96" y2="190"/><line x1="285" y1="168" x2="285" y2="190"/>
    <line x1="475" y1="168" x2="475" y2="190"/><line x1="664" y1="168" x2="664" y2="190"/>
  </g>

  <g font-family="Inter,sans-serif">
    <rect x="22" y="192" width="148" height="62" rx="10" fill="#fff" stroke="#BD2728" stroke-width="1.8"/>
    <text x="96" y="216" text-anchor="middle" font-size="12.5" font-weight="750" fill="#1B1F24">user-service</text>
    <text x="96" y="234" text-anchor="middle" font-size="11" fill="#5B6572">:8081 · ví tiền</text>

    <rect x="211" y="192" width="148" height="62" rx="10" fill="#fff" stroke="#BD2728" stroke-width="1.8"/>
    <text x="285" y="216" text-anchor="middle" font-size="12.5" font-weight="750" fill="#1B1F24">restaurant-service</text>
    <text x="285" y="234" text-anchor="middle" font-size="11" fill="#5B6572">:8082 · thực đơn</text>

    <rect x="401" y="192" width="148" height="62" rx="10" fill="#fff" stroke="#BD2728" stroke-width="1.8"/>
    <text x="475" y="216" text-anchor="middle" font-size="12.5" font-weight="750" fill="#1B1F24">order-service</text>
    <text x="475" y="234" text-anchor="middle" font-size="11" fill="#5B6572">:8083 · đơn hàng</text>

    <rect x="590" y="192" width="148" height="62" rx="10" fill="#fff" stroke="#BD2728" stroke-width="1.8"/>
    <text x="664" y="216" text-anchor="middle" font-size="12.5" font-weight="750" fill="#1B1F24">notification-svc</text>
    <text x="664" y="234" text-anchor="middle" font-size="11" fill="#5B6572">:8084 · thông báo</text>
  </g>

  <g stroke="#2E7D32" stroke-width="1.8" stroke-dasharray="4 4">
    <line x1="96" y1="254" x2="96" y2="292"/><line x1="285" y1="254" x2="285" y2="292"/>
    <line x1="475" y1="254" x2="475" y2="292"/><line x1="664" y1="254" x2="664" y2="292"/>
  </g>

  <rect x="22" y="294" width="716" height="106" rx="12" fill="#E8F5E9" stroke="#2E7D32" stroke-width="2"/>
  <text x="380" y="318" text-anchor="middle" font-family="Inter,sans-serif" font-size="13" font-weight="750" fill="#1B3A1E">MỘT container PostgreSQL — BỐN database logic riêng</text>
  <g font-family="monospace" font-size="10.5" fill="#2A4A2D">
    <rect x="40" y="332" width="158" height="30" rx="6" fill="#fff" stroke="#A8CFAB"/>
    <text x="119" y="351" text-anchor="middle">quickbite_user_db</text>
    <rect x="216" y="332" width="176" height="30" rx="6" fill="#fff" stroke="#A8CFAB"/>
    <text x="304" y="351" text-anchor="middle">quickbite_restaurant_db</text>
    <rect x="410" y="332" width="158" height="30" rx="6" fill="#fff" stroke="#A8CFAB"/>
    <text x="489" y="351" text-anchor="middle">quickbite_order_db</text>
    <rect x="586" y="332" width="134" height="30" rx="6" fill="#fff" stroke="#A8CFAB"/>
    <text x="653" y="351" text-anchor="middle">quickbite_notif_db</text>
  </g>
  <text x="380" y="382" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" font-style="italic" fill="#3B5C3E">Mỗi service có user riêng — không đọc được dữ liệu của service khác</text>
</svg>
<figcaption>Bốn service độc lập, mỗi cái một database logic. Chỉ gateway mở cổng ra ngoài.</figcaption>
</figure>

---

# Phần 1 · Dữ liệu nằm ở đâu?

## Database-per-service

Mỗi microservice **sở hữu một database logic riêng**. Không khoá ngoại xuyên database, không `JOIN` xuyên database. Mọi trao đổi dữ liệu đi qua **REST API**.

<div class="keybox">
<span class="lbl">Điểm rất dễ hiểu nhầm</span>
<p>"Database riêng" nghĩa là <strong>database logic</strong>, <strong>không phải</strong> mỗi service một container Postgres riêng. Ta vẫn chạy <strong>một</strong> container chứa 4 database bên trong, mỗi cái có user riêng. Tiết kiệm tài nguyên mà vẫn cô lập được dữ liệu.</p>
</div>

Tự kiểm chứng sự cô lập:

```bash
# user-service thử đọc database của order-service
docker exec quickbite5-db psql -U quickbite_user -d quickbite_order_db -c "SELECT 1;"
# → FATAL: permission denied for database "quickbite_order_db"
```

## Vấn đề: JPA không nối được hai database

Trong monolith, bạn viết quen tay:

```java
@ManyToOne
@JoinColumn(name = "customer_id")
private User customer;      // ❌ không dùng được nữa
```

JPA **không hỗ trợ** `@ManyToOne` hay `@ManyToMany` xuyên cơ sở dữ liệu vật lý.

## Giải pháp 1: Liên kết lỏng (Soft Reference)

Chỉ lưu **số ID** thay vì ánh xạ quan hệ:

```java
private Long customerId;    // ✅ chỉ là một số nguyên bình thường
```

Khi cần thông tin chi tiết → **gọi HTTP** sang service quản lý thực thể đó.

<div class="grid2">
<div class="card ok">
<h4>Được gì</h4>
<p>Hai service hoàn toàn độc lập. Đổi schema bên này không ảnh hưởng bên kia. Deploy riêng, scale riêng.</p>
</div>
<div class="card no">
<h4>Mất gì</h4>
<p>Database <strong>không còn kiểm tra hộ bạn</strong>. <code>customerId = 999</code> trỏ tới user không tồn tại mà database <strong>không báo lỗi</strong>. Trách nhiệm chuyển sang tầng ứng dụng.</p>
</div>
</div>

## Giải pháp 2: Snapshot Pattern

**Tình huống:** hoá đơn chỉ lưu `menuItemId`. Tháng sau nhà hàng tăng giá món từ 75.000 lên 99.000đ. Khách mở lại hoá đơn cũ — thấy **99.000đ**. Sai hoàn toàn.

**Cách làm đúng:** tại thời điểm đặt hàng, **chụp lại** tên nhà hàng, tên món và giá, lưu cứng vào bảng đơn hàng.

```sql
CREATE TABLE orders (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL,       -- soft reference
    restaurant_id   BIGINT NOT NULL,       -- soft reference
    -- 3 cột dưới là SNAPSHOT — bản sao tĩnh lúc đặt hàng
    restaurant_name VARCHAR(150) NOT NULL,
    menu_item       VARCHAR(150) NOT NULL,
    price           BIGINT NOT NULL,
    status          VARCHAR(20) NOT NULL
);
```

<figure class="dg">
<svg viewBox="0 0 700 220" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="So sánh tham chiếu động và snapshot">
  <rect x="14" y="14" width="322" height="192" rx="12" fill="#FFF8F0" stroke="#E5C9A6"/>
  <text x="175" y="40" text-anchor="middle" font-family="Inter,sans-serif" font-size="13.5" font-weight="780" fill="#B06000">Tham chiếu động — SAI</text>
  <rect x="42" y="56" width="120" height="44" rx="8" fill="#fff" stroke="#E0D2BE"/>
  <text x="102" y="74" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" font-weight="700" fill="#5B6572">Hoá đơn #1</text>
  <text x="102" y="90" text-anchor="middle" font-family="monospace" font-size="10.5" fill="#8A929C">menuItemId = 1</text>
  <line x1="162" y1="78" x2="186" y2="78" stroke="#C9553B" stroke-width="2"/><path d="M182 73 L192 78 L182 83 Z" fill="#C9553B"/>
  <rect x="192" y="56" width="120" height="44" rx="8" fill="#fff" stroke="#E0D2BE"/>
  <text x="252" y="74" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" font-weight="700" fill="#5B6572">Thực đơn</text>
  <text x="252" y="90" text-anchor="middle" font-family="monospace" font-size="10.5" fill="#B06000">99.000đ (mới)</text>
  <text x="175" y="130" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" fill="#7A6A52">Nhà hàng đổi giá →</text>
  <rect x="42" y="142" width="270" height="44" rx="8" fill="#FDECEC" stroke="#F0C4C4"/>
  <text x="177" y="162" text-anchor="middle" font-family="Inter,sans-serif" font-size="12" font-weight="700" fill="#8C1D1A">Hoá đơn cũ hiện 99.000đ</text>
  <text x="177" y="178" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" fill="#A0413F">Khách trả 75.000đ — sai lệch</text>

  <rect x="364" y="14" width="322" height="192" rx="12" fill="#F2FAF3" stroke="#BFE0C3"/>
  <text x="525" y="40" text-anchor="middle" font-family="Inter,sans-serif" font-size="13.5" font-weight="780" fill="#2E7D32">Snapshot — ĐÚNG</text>
  <rect x="392" y="56" width="140" height="44" rx="8" fill="#fff" stroke="#C6E2C9"/>
  <text x="462" y="74" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" font-weight="700" fill="#5B6572">Hoá đơn #1</text>
  <text x="462" y="90" text-anchor="middle" font-family="monospace" font-size="10.5" fill="#2E7D32">price = 75.000đ</text>
  <rect x="552" y="56" width="110" height="44" rx="8" fill="#fff" stroke="#C6E2C9"/>
  <text x="607" y="74" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" font-weight="700" fill="#5B6572">Thực đơn</text>
  <text x="607" y="90" text-anchor="middle" font-family="monospace" font-size="10.5" fill="#B06000">99.000đ</text>
  <line x1="532" y1="78" x2="548" y2="78" stroke="#C3CAD3" stroke-width="2" stroke-dasharray="3 3"/>
  <text x="525" y="130" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" fill="#4A6B4D">Không liên kết động</text>
  <rect x="392" y="142" width="270" height="44" rx="8" fill="#E8F5E9" stroke="#A8CFAB"/>
  <text x="527" y="162" text-anchor="middle" font-family="Inter,sans-serif" font-size="12" font-weight="700" fill="#1B3A1E">Hoá đơn cũ vẫn 75.000đ</text>
  <text x="527" y="178" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" fill="#3B5C3E">Đúng với lúc giao dịch</text>
</svg>
<figcaption>Hoá đơn là chứng từ — phải phản ánh đúng thời điểm giao dịch, không chạy theo thực đơn hiện tại.</figcaption>
</figure>

<div class="keybox">
<span class="lbl">Câu hỏi bẫy</span>
<p>"Nhà hàng sửa lỗi chính tả tên món, hoá đơn cũ có sửa theo không?"<br>
→ <strong>Không.</strong> Và đó là <strong>đúng</strong>. Snapshot không phải bug — nó là yêu cầu nghiệp vụ.</p>
</div>

---

# Phần 2 · Cấu hình nhiều service

## Một file `.env`, tiền tố hoá theo service

```dotenv
USER_DB_NAME=quickbite_user_db
USER_DB_USERNAME=quickbite_user
USER_DB_PASSWORD=quickbite_user

RESTAURANT_DB_NAME=quickbite_restaurant_db
RESTAURANT_DB_USERNAME=quickbite_restaurant
RESTAURANT_DB_PASSWORD=quickbite_restaurant

ORDER_DB_NAME=quickbite_order_db
ORDER_DB_USERNAME=quickbite_order
ORDER_DB_PASSWORD=quickbite_order
```

<div class="keybox">
<span class="lbl">Vì sao bắt buộc tiền tố</span>
<p>Cả 4 service đều cần một biến nghĩa là "tên database". Nếu để chung là <code>DB_NAME</code>, chúng <strong>ghi đè lẫn nhau</strong> khi Compose nạp file. Tiền tố là cách rẻ nhất giữ không gian tên tách biệt mà vẫn chỉ quản lý một file duy nhất.</p>
</div>

## Cắm biến vào Compose

```yaml
services:
  user-service:
    build: ./user-service
    environment:
      - SPRING_DATASOURCE_URL=jdbc:postgresql://quickbite5-db:5432/${USER_DB_NAME}
      - SPRING_DATASOURCE_USERNAME=${USER_DB_USERNAME}
      - SPRING_DATASOURCE_PASSWORD=${USER_DB_PASSWORD}
    networks:
      - quickbite5-net
```

> 💡 **Vì sao tên biến là `SPRING_DATASOURCE_URL`?**
> Spring Boot có cơ chế **relaxed binding**: biến môi trường `SPRING_DATASOURCE_URL` tự động ánh xạ vào thuộc tính `spring.datasource.url`. Nhờ vậy **không cần viết gì trong `application.yml`** — cấu hình đi thẳng từ Compose vào Spring.

---

# Phần 3 · Các service gọi nhau thế nào?

## OpenFeign — gọi HTTP như gọi hàm Java

Khai báo một `interface`, Spring tự sinh phần gọi HTTP:

```java
@FeignClient(name = "restaurant-service", url = "http://restaurant-service:8082")
public interface RestaurantServiceClient {

    @GetMapping("/restaurants/{id}")
    Map<String, Object> getRestaurant(@PathVariable("id") Long id);
}
```

Dùng y như một bean bình thường:

```java
Map<String, Object> r = restaurantClient.getRestaurant(restaurantId);
```

> ⚠️ **Ba điều bắt buộc nhớ:**
> 1. `@EnableFeignClients` trên lớp `@SpringBootApplication` — thiếu là lỗi `NoSuchBeanDefinition`
> 2. Dependency `spring-cloud-starter-openfeign` **và** BOM `spring-cloud-dependencies` — thiếu BOM thì Gradle không biết lấy version nào
> 3. Host trong `url` phải khớp **chính xác** tên service trong `docker-compose.yml` — gõ nhầm sẽ cho `UnknownHostException`

<div class="keybox">
<span class="lbl">Điều dễ quên nhất về Feign</span>
<p>Feign chỉ là <em>đường dẫn nhanh về cú pháp</em>. Bên dưới vẫn là <strong>một cuộc gọi HTTP qua mạng</strong> — có độ trễ, có thể timeout, có thể thất bại. Code trông y hệt gọi hàm nội bộ nên rất dễ quên điều này. <strong>Mọi lời gọi Feign đều phải được coi là có thể hỏng.</strong></p>
</div>

## Internal Ports — giấu service khỏi thế giới bên ngoài

<div class="grid2">
<div class="card no">
<h4>Mối đe dọa</h4>
<p>Mở hết cổng 8081, 8082, 8083 ra máy thật → <strong>mở rộng bề mặt tấn công</strong>. Tin tặc quét cổng rồi gọi thẳng vào service, <strong>bỏ qua mọi kiểm tra bảo mật</strong> ở gateway.</p>
</div>
<div class="card ok">
<h4>Giải pháp</h4>
<p>Xoá khối <code>ports</code> khỏi các service nội bộ. Chúng chỉ nói chuyện với nhau <strong>bên trong</strong> mạng ảo. Chỉ <strong>một</strong> cổng của gateway mở ra ngoài.</p>
</div>
</div>

```yaml
services:
  api-gateway:
    ports:
      - "8080:8080"        # ✅ cửa ngõ duy nhất

  user-service:
    # ❌ KHÔNG có "ports" — cổng 8081 bị giấu khỏi máy host
    networks:
      - quickbite5-net
```

Tự kiểm chứng:

```bash
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

Chỉ gateway có dạng `0.0.0.0:8000->8080/tcp`. Bốn service còn lại chỉ hiện `8081/tcp` — **cổng chỉ tồn tại bên trong mạng ảo**.

```bash
curl http://localhost:8082/restaurants          # ❌ Connection refused
curl http://localhost:8000/api/v1/restaurants   # ✅ có dữ liệu
```

Nhưng service **vẫn sống** — gọi từ bên trong mạng thì được:

```bash
docker exec quickbite5-order wget -qO- http://restaurant-service:8082/restaurants
```

> 💡 Đây chính là bài `EXPOSE` vs `-p` của Session 04, nay dùng cho mục đích **bảo mật**.

---

# Phần 4 · Vì sao cần API Gateway?

## Ba nỗi đau khi Client gọi thẳng nhiều service

<div class="grid3">
<div class="card no">
<h4>1 · Quản lý endpoint</h4>
<p>App mobile phải lưu và quản lý <strong>hàng chục URL và port</strong> khác nhau. Đổi cổng một service là phải cập nhật app.</p>
</div>
<div class="card no">
<h4>2 · Lỗi CORS</h4>
<p>Trình duyệt chặn request gọi chéo cổng mạng → phải cấu hình CORS trên <strong>tất cả</strong> các service.</p>
</div>
<div class="card no">
<h4>3 · Trùng lặp bảo mật</h4>
<p>Logic xác thực JWT phải viết lặp lại ở <strong>mọi service</strong>.</p>
</div>
</div>

<div class="keybox">
<span class="lbl">Vấn đề số 3 là cái đau nhất</span>
<p>Không chỉ tốn công viết lại. Khi đổi thuật toán ký token, bạn phải sửa <strong>4 chỗ</strong>, deploy <strong>4 lần</strong>, và chỉ cần <strong>một</strong> service quên cập nhật là toàn hệ thống có lỗ hổng. Tập trung hoá bảo mật không phải để tiện — mà để <strong>an toàn</strong>.</p>
</div>

## API Gateway khác Nginx thế nào?

| | **Nginx** — hạ tầng | **Spring Cloud Gateway** — ứng dụng |
|---|---|---|
| Tầng hoạt động | TCP/UDP, HTTP thô | Nền Spring, hiểu logic ứng dụng |
| Mạnh ở | SSL/HTTPS, nén dữ liệu, file tĩnh | Filter viết bằng Java, can thiệp Header/Body, quyền hạn nghiệp vụ |
| Hạn chế | Khó can thiệp logic nghiệp vụ | Nặng hơn khi chỉ phục vụ file tĩnh |

<div class="keybox">
<span class="lbl">Đây KHÔNG phải câu hỏi "chọn cái nào"</span>
<p>Hai công cụ giải hai bài toán khác nhau và <strong>thường dùng cùng nhau</strong>:</p>
<p style="font-family:var(--mono);font-size:13px;margin-top:8px">Internet → <strong>Nginx</strong> (HTTPS, file tĩnh) → <strong>Spring Cloud Gateway</strong> (định tuyến, bảo mật) → microservices</p>
</div>

---

# Phần 5 · Spring Cloud Gateway

## Cơ chế: Predicate → Filter → Service

<figure class="dg">
<svg viewBox="0 0 720 200" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Cơ chế định tuyến Predicate Filter">
  <rect x="12" y="46" width="140" height="58" rx="10" fill="#fff" stroke="#44546A" stroke-width="1.8"/>
  <text x="82" y="70" text-anchor="middle" font-family="Inter,sans-serif" font-size="12.5" font-weight="750" fill="#1B1F24">Client Request</text>
  <text x="82" y="88" text-anchor="middle" font-family="monospace" font-size="10.5" fill="#5B6572">/api/v1/users/1</text>

  <line x1="152" y1="75" x2="188" y2="75" stroke="#44546A" stroke-width="2.2"/><path d="M184 70 L194 75 L184 80 Z" fill="#44546A"/>

  <rect x="196" y="46" width="150" height="58" rx="10" fill="#E8F5E9" stroke="#2E7D32" stroke-width="2"/>
  <text x="271" y="70" text-anchor="middle" font-family="Inter,sans-serif" font-size="12.5" font-weight="750" fill="#1B3A1E">Predicate</text>
  <text x="271" y="88" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" fill="#3B5C3E">Có khớp Path không?</text>

  <line x1="346" y1="75" x2="384" y2="75" stroke="#2E7D32" stroke-width="2.2"/><path d="M380 70 L390 75 L380 80 Z" fill="#2E7D32"/>
  <text x="365" y="64" text-anchor="middle" font-family="Inter,sans-serif" font-size="10.5" font-weight="700" fill="#2E7D32">Match</text>

  <rect x="392" y="46" width="150" height="58" rx="10" fill="#F4EEFB" stroke="#7B3FA0" stroke-width="2"/>
  <text x="467" y="70" text-anchor="middle" font-family="Inter,sans-serif" font-size="12.5" font-weight="750" fill="#4A1F66">Filter</text>
  <text x="467" y="88" text-anchor="middle" font-family="monospace" font-size="10.5" fill="#6B3A8C">StripPrefix=2</text>

  <line x1="542" y1="75" x2="578" y2="75" stroke="#7B3FA0" stroke-width="2.2"/><path d="M574 70 L584 75 L574 80 Z" fill="#7B3FA0"/>

  <rect x="586" y="46" width="124" height="58" rx="10" fill="#fff" stroke="#BD2728" stroke-width="1.8"/>
  <text x="648" y="70" text-anchor="middle" font-family="Inter,sans-serif" font-size="12" font-weight="750" fill="#1B1F24">user-service</text>
  <text x="648" y="88" text-anchor="middle" font-family="monospace" font-size="10" fill="#5B6572">/users/1</text>

  <path d="M271 104 L271 138 L150 138" fill="none" stroke="#C9553B" stroke-width="2" stroke-dasharray="5 4"/>
  <path d="M154 133 L144 138 L154 143 Z" fill="#C9553B"/>
  <text x="208" y="132" text-anchor="middle" font-family="Inter,sans-serif" font-size="10.5" font-weight="700" fill="#C9553B">No Match</text>
  <rect x="42" y="124" width="100" height="28" rx="7" fill="#FDECEC" stroke="#F0C4C4"/>
  <text x="92" y="143" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" font-weight="700" fill="#8C1D1A">404</text>

  <text x="360" y="184" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" font-style="italic" fill="#8A929C">Predicate hỏi "có khớp không?" — Filter hỏi "biến đổi thế nào?"</text>
</svg>
</figure>

## Cấu hình định tuyến

```yaml
server:
  port: 8080
spring:
  cloud:
    gateway:
      routes:
        - id: user_route
          uri: http://user-service:8081      # đích — dùng TÊN SERVICE
          predicates:
            - Path=/api/v1/users/**          # điều kiện khớp
          filters:
            - StripPrefix=2                  # bỏ 2 đoạn đầu
```

## `StripPrefix=2` làm gì?

```
Client gọi:       /api/v1/users/1
                   └┬─┘ └┬┘ └──┬──┘
                    1    2   giữ lại
StripPrefix=2  ──►  /users/1
Gateway gửi tới:  http://user-service:8081/users/1
```

<div class="keybox">
<span class="lbl">Vì sao phải bỏ tiền tố</span>
<p><code>/api/v1</code> là quy ước dành cho <strong>thế giới bên ngoài</strong> — nó cho client biết phiên bản API. Bản thân <code>user-service</code> không quan tâm, nó chỉ phục vụ <code>/users</code>. Filter làm nhiệm vụ <strong>dịch giữa hai thế giới đó</strong>.</p>
</div>

> ⚠️ **Đếm sai số là lỗi phổ biến nhất.** `StripPrefix=1` sẽ gửi `/v1/users/1` xuống service → service trả **404**.

**Lệnh debug quan trọng nhất của gateway:**

```bash
curl http://localhost:8000/actuator/gateway/routes
```

Khi bị 404, gõ nó trước tiên để xem route có được nạp không và path khớp là gì.

---

# Phần 6 · Một đơn hàng đi qua những đâu?

## Vòng đời 6 bước

<figure class="dg">
<svg viewBox="0 0 700 330" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Sáu bước của một đơn đặt hàng">
  <g font-family="Inter,sans-serif">
    <circle cx="40" cy="36" r="15" fill="#BD2728"/><text x="40" y="41" text-anchor="middle" font-size="13" font-weight="800" fill="#fff">1</text>
    <text x="66" y="32" font-size="13" font-weight="750" fill="#1B1F24">Gửi yêu cầu &amp; Routing</text>
    <text x="66" y="49" font-size="11.5" fill="#5B6572">Client → Gateway → order-service</text>

    <circle cx="40" cy="92" r="15" fill="#BD2728"/><text x="40" y="97" text-anchor="middle" font-size="13" font-weight="800" fill="#fff">2</text>
    <text x="66" y="88" font-size="13" font-weight="750" fill="#1B1F24">Khởi tạo đơn hàng</text>
    <text x="66" y="105" font-size="11.5" fill="#5B6572">order-service tạo đơn trạng thái PENDING</text>

    <circle cx="40" cy="148" r="15" fill="#E07C00"/><text x="40" y="153" text-anchor="middle" font-size="13" font-weight="800" fill="#fff">3</text>
    <text x="66" y="144" font-size="13" font-weight="750" fill="#8A5000">Thanh toán &amp; số dư</text>
    <text x="66" y="161" font-size="11.5" fill="#5B6572">order-service → user-service: TRỪ TIỀN VÍ</text>

    <circle cx="40" cy="204" r="15" fill="#E07C00"/><text x="40" y="209" text-anchor="middle" font-size="13" font-weight="800" fill="#fff">4</text>
    <text x="66" y="200" font-size="13" font-weight="750" fill="#8A5000">Chuẩn bị món ăn</text>
    <text x="66" y="217" font-size="11.5" fill="#5B6572">order-service → restaurant-service</text>

    <circle cx="40" cy="260" r="15" fill="#2E7D32"/><text x="40" y="265" text-anchor="middle" font-size="13" font-weight="800" fill="#fff">5</text>
    <text x="66" y="256" font-size="13" font-weight="750" fill="#1B1F24">Điều phối tài xế</text>
    <text x="66" y="273" font-size="11.5" fill="#5B6572">order-service → user-service</text>

    <circle cx="40" cy="310" r="15" fill="#2E7D32"/><text x="40" y="315" text-anchor="middle" font-size="13" font-weight="800" fill="#fff">6</text>
    <text x="66" y="306" font-size="13" font-weight="750" fill="#1B1F24">Gửi thông báo</text>
    <text x="66" y="323" font-size="11.5" fill="#5B6572">→ notification-service</text>
  </g>
  <rect x="418" y="128" width="268" height="96" rx="10" fill="#FFF4E5" stroke="#E5C9A6"/>
  <text x="552" y="152" text-anchor="middle" font-family="Inter,sans-serif" font-size="12.5" font-weight="780" fill="#8A5000">Vùng nguy hiểm</text>
  <text x="552" y="174" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" fill="#6B4A20">Bước 3 trừ tiền THÀNH CÔNG,</text>
  <text x="552" y="191" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" fill="#6B4A20">bước 4 nhà hàng TỪ CHỐI.</text>
  <text x="552" y="211" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" font-weight="700" fill="#B03000">Tiền của khách đi đâu?</text>
</svg>
</figure>

Tự chạy thử:

```bash
curl -X POST "http://localhost:8000/api/v1/orders?userId=1&restaurantId=1"
docker logs quickbite5-order | grep BUOC
```

Một lệnh `curl` duy nhất đã làm **bốn service** cùng làm việc và ghi vào **ba database khác nhau**.

## Bài toán dữ liệu phân tán

Trong monolith, `@Transactional` lo hết: lỗi giữa chừng thì database tự `ROLLBACK`.

Ở hệ phân tán, tiền nằm ở `quickbite_user_db`, đơn hàng nằm ở `quickbite_order_db`. **Hai database khác nhau** → không có `ROLLBACK` nào bao trùm cả hai. **Không còn ai lo hộ bạn nữa.**

## Giải pháp: Giao dịch bù (Compensating Transaction)

Lập trình viên phải **tự tay viết mã hoàn tác**:

```java
try {
    restaurantClient.acceptOrder(restaurantId);       // bước 4
} catch (FeignException e) {
    // ===== GIAO DỊCH BÙ =====
    // Tiền đã bị trừ ở bước 3. Không có rollback tự động.
    userClient.refundWallet(userId, price);
    jdbc.update("UPDATE orders SET status='CANCELLED' WHERE id=?", orderId);
    notificationClient.send(userId, "Đơn #" + orderId + " bị huỷ. Đã hoàn " + price + "đ.");
}
```

**Tự chứng minh trên máy:**

```bash
# 1. Cho nhà hàng #2 đóng cửa
curl -X POST "http://localhost:8000/api/v1/restaurants/2/toggle-open?open=false"

# 2. Ghi lại số dư ví
curl http://localhost:8000/api/v1/users/1

# 3. Đặt hàng ở nhà hàng đóng cửa
curl -X POST "http://localhost:8000/api/v1/orders?userId=1&restaurantId=2"

# 4. Xem lại số dư — KHÔNG ĐỔI, vì đã hoàn tiền
curl http://localhost:8000/api/v1/users/1
```

<div class="keybox">
<span class="lbl">Ba điều phải hiểu sau thí nghiệm này</span>
<p><strong>1. Nhất quán cuối cùng, không phải tức thời.</strong> Có một khoảnh khắc tiền đã bị trừ mà đơn chưa xác nhận. Hệ phân tán chấp nhận điều đó.</p>
<p><strong>2. Giao dịch bù cũng có thể thất bại.</strong> Nếu <code>user-service</code> chết đúng lúc hoàn tiền thì sao? Sản phẩm thật cần retry, hàng đợi và log đối soát.</p>
<p><strong>3. Đây là cái giá cố hữu của microservices</strong> — không phải nhược điểm do làm sai. Nếu nghiệp vụ không chịu được điều này, có lẽ nên dùng monolith.</p>
</div>

> 💡 **Lưu ý tinh tế:** nếu ví **không đủ tiền**, lỗi xảy ra ngay ở bước 3 — tiền chưa kịp bị trừ nên **không cần giao dịch bù**, chỉ cần huỷ đơn. Giao dịch bù chỉ cần khi đã có thao tác **thành công** cần hoàn tác.

---

# Tự kiểm tra

<details class="q"><summary><span>Vì sao không dùng <code>JOIN</code> giữa bảng <code>orders</code> và <code>users</code>?</span></summary>
<div class="ans">
<p>Vì hai bảng nằm ở <strong>hai database khác nhau</strong> (<code>quickbite_order_db</code> và <code>quickbite_user_db</code>). SQL không <code>JOIN</code> xuyên database được.</p>
<p>Thay vào đó: lưu <code>user_id</code> dưới dạng số (soft reference) và gọi HTTP sang <code>user-service</code> khi cần chi tiết.</p>
</div></details>

<details class="q"><summary><span>Snapshot Pattern giải quyết vấn đề gì?</span></summary>
<div class="ans">
<p>Giữ cho <strong>hoá đơn cũ không bị sai lệch</strong> khi nhà hàng đổi giá hoặc đổi tên.</p>
<p>Cách làm: tại thời điểm đặt hàng, sao chép tên nhà hàng, tên món và giá vào thẳng bảng <code>orders</code> thay vì tham chiếu động.</p>
</div></details>

<details class="q"><summary><span>Vì sao chỉ API Gateway được khai báo <code>ports</code>?</span></summary>
<div class="ans">
<p>Để <strong>thu hẹp bề mặt tấn công</strong>. Nếu mở hết cổng service ra máy thật, tin tặc có thể quét cổng và gọi thẳng vào service, bỏ qua mọi kiểm tra bảo mật ở gateway.</p>
<p>Service vẫn chạy và vẫn nghe cổng của nó — chỉ là không có cửa ra máy thật.</p>
</div></details>

<details class="q"><summary><span><code>StripPrefix=2</code> biến <code>/api/v1/users/1</code> thành gì?</span></summary>
<div class="ans">
<p>Thành <code>/users/1</code> — bỏ 2 đoạn đầu là <code>api</code> và <code>v1</code>.</p>
<p>Gateway sẽ gửi tới <code>http://user-service:8081/users/1</code>. Nếu đặt nhầm <code>StripPrefix=1</code> thì gửi <code>/v1/users/1</code> và service trả <strong>404</strong>.</p>
</div></details>

<details class="q"><summary><span>Feign Client gọi service khác bằng địa chỉ gì?</span></summary>
<div class="ans">
<p>Bằng <strong>tên service</strong> khai báo trong <code>docker-compose.yml</code>, ví dụ <code>http://restaurant-service:8082</code>.</p>
<p>DNS nội bộ của Docker phân giải tên đó thành IP tại thời điểm chạy. Gõ sai tên sẽ cho <code>UnknownHostException</code>.</p>
</div></details>

<details class="q"><summary><span>Ba điều bắt buộc khi dùng OpenFeign là gì?</span></summary>
<div class="ans">
<p>1. <code>@EnableFeignClients</code> trên lớp Application — thiếu là <code>NoSuchBeanDefinition</code><br>
2. Dependency <code>spring-cloud-starter-openfeign</code> <strong>và</strong> BOM <code>spring-cloud-dependencies</code><br>
3. Tên service trong <code>url</code> phải khớp chính xác <code>docker-compose.yml</code></p>
</div></details>

<details class="q"><summary><span>Vì sao cần giao dịch bù thay vì <code>@Transactional</code>?</span></summary>
<div class="ans">
<p>Vì tiền và đơn hàng nằm ở <strong>hai database khác nhau</strong>. <code>@Transactional</code> chỉ bao được một kết nối database — nó không thể rollback thao tác đã xảy ra ở service khác qua HTTP.</p>
<p>Nên phải tự viết mã hoàn tác: bắt exception rồi gọi API hoàn tiền.</p>
</div></details>

<details class="q"><summary><span>Nếu ví không đủ tiền, có cần giao dịch bù không?</span></summary>
<div class="ans">
<p><strong>Không.</strong> Lỗi xảy ra ngay ở bước 3, tiền chưa kịp bị trừ. Chỉ cần huỷ đơn.</p>
<p>Giao dịch bù chỉ cần khi đã có một thao tác <strong>thành công</strong> cần hoàn tác.</p>
</div></details>

<details class="q"><summary><span>Nginx và Spring Cloud Gateway — nên chọn cái nào?</span></summary>
<div class="ans">
<p><strong>Cả hai</strong>, mỗi cái một tầng nhiệm vụ. Nginx đứng ngoài lo HTTPS và file tĩnh; Spring Cloud Gateway đứng trong lo định tuyến và bảo mật nghiệp vụ.</p>
<p>Đây không phải hai lựa chọn thay thế nhau.</p>
</div></details>

<details class="q"><summary><span>Sau khi rebuild một service, vì sao gateway báo <code>Connection refused</code>?</span></summary>
<div class="ans">
<p>Gateway chạy trên Netty, mà Netty <strong>cache kết quả phân giải DNS</strong>. Container vừa tạo lại có IP mới, nhưng gateway vẫn gọi vào IP cũ.</p>
<p>Sửa: <code>docker compose restart api-gateway</code></p>
</div></details>

---

# Bảng tra nhanh

| Việc | Lệnh |
|---|---|
| Bật cả hệ đúng thứ tự | `./start-all.sh` |
| Kiểm tra 22 mục | `./check.sh` |
| Xem cổng nào mở ra ngoài | `docker ps --format "table {{.Names}}\t{{.Ports}}"` |
| Bảng định tuyến gateway | `curl http://localhost:8000/actuator/gateway/routes` |
| Danh sách user + ví tiền | `curl http://localhost:8000/api/v1/users` |
| Danh sách nhà hàng | `curl http://localhost:8000/api/v1/restaurants` |
| **Đặt hàng** | `curl -X POST "http://localhost:8000/api/v1/orders?userId=1&restaurantId=1"` |
| Đóng cửa nhà hàng (demo Saga) | `curl -X POST "http://localhost:8000/api/v1/restaurants/2/toggle-open?open=false"` |
| Log 6 bước | `docker logs quickbite5-order 2>&1 \| grep BUOC` |
| Liệt kê 4 database | `docker exec quickbite5-db psql -U postgres -c "\l"` |

> 💡 Bảng lệnh **đầy đủ** kèm 10 thí nghiệm gây lỗi nằm ở file **`S5-02-Lab-thuc-hanh.html`**.

---

# Bảy cặp khái niệm hay nhầm

| Cặp | Khác nhau ở chỗ |
|---|---|
| Database vật lý ↔ Database logic | 1 container Postgres ↔ 4 database bên trong nó |
| `@ManyToOne` ↔ Soft reference | Ràng buộc khoá ngoại ↔ chỉ lưu số ID |
| Tham chiếu động ↔ Snapshot | Luôn lấy dữ liệu mới ↔ chụp lại lúc giao dịch |
| API Gateway ↔ Nginx | Tầng ứng dụng ↔ tầng hạ tầng (dùng **cùng nhau**) |
| Predicate ↔ Filter | "Có khớp không?" ↔ "Biến đổi thế nào?" |
| `@Transactional` ↔ Giao dịch bù | Rollback tự động ↔ tự tay viết mã hoàn tác |
| Có `ports` ↔ không `ports` | Mở ra máy thật ↔ chỉ tồn tại trong mạng ảo |

---

# Bài tập về nhà

<div class="grid2">
<div class="card">
<h4>Bài 1 · Bắt buộc</h4>
<p>Thêm route cho <code>notification-service</code> vào gateway với tiền tố <code>/api/v1/notifications/**</code>. Giải thích <code>StripPrefix</code> phải đặt bằng mấy và vì sao.</p>
</div>
<div class="card">
<h4>Bài 2 · Bắt buộc</h4>
<p>Viết Feign Client trong <code>restaurant-service</code> gọi sang <code>user-service</code> để lấy tên chủ quán. Xử lý trường hợp trả về 404.</p>
</div>
<div class="card">
<h4>Bài 3 · Bắt buộc</h4>
<p>Bổ sung giao dịch bù cho <strong>bước 5</strong> (điều phối tài xế thất bại): phải hoàn tiền <strong>và</strong> báo nhà hàng huỷ món. Giải thích vì sao giao dịch bù ở bước sau phức tạp hơn bước trước.</p>
</div>
<div class="card ok">
<h4>Bài 4 · Nâng cao</h4>
<p>Viết một <code>GlobalFilter</code> cho gateway, ghi log mọi request kèm thời gian xử lý. Giải thích vì sao đặt ở gateway tốt hơn đặt ở từng service.</p>
</div>
</div>

<div class="card ok" style="margin:17px 0">
<h4>Bài 5 · Nâng cao</h4>
<p>Tìm hiểu <strong>Circuit Breaker</strong> (Resilience4j). Nếu <code>restaurant-service</code> chết hẳn, điều gì xảy ra với <code>order-service</code>? Vì sao <code>try/catch</code> đơn thuần là <strong>không đủ</strong>?</p>
</div>

---

# Checklist trước khi rời lớp

- [ ] Giải thích được Database-per-service và phân biệt database vật lý / logic
- [ ] Giải thích được vì sao không dùng được `@ManyToOne` xuyên service
- [ ] Giải thích được Snapshot Pattern và vì sao hoá đơn cũ không được đổi theo
- [ ] Biết vì sao biến trong `.env` phải có tiền tố
- [ ] Đọc hiểu một `@FeignClient` và nhớ 3 điều bắt buộc
- [ ] Giải thích được vì sao chỉ gateway mở `ports`
- [ ] Đọc được bảng định tuyến và hiểu `StripPrefix`
- [ ] Phân biệt được Predicate và Filter
- [ ] Kể được 6 bước của luồng đặt hàng
- [ ] Giải thích được giao dịch bù và khi nào **không** cần nó
- [ ] Biết vì sao phải restart gateway sau khi rebuild service
