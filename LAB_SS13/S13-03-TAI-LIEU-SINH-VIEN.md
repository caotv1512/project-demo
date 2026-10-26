# TÀI LIỆU SINH VIÊN — SESSION 13
# Giám sát hệ thống với Prometheus

> **Tài liệu này bám sát slide bài giảng.** Bốn Lesson và các mục con đánh số **đúng như trên slide**, để bạn đối chiếu giữa lúc nghe giảng và lúc đọc lại.

> | Tài liệu | Dùng khi nào |
> |---|---|
> | Slide bài giảng | Nghe giảng trên lớp |
> | **Tài liệu này** | Đọc lại để **hiểu vì sao** |
> | `S13-02-Lab-thuc-hanh.html` | **Gõ lệnh** — bảng lệnh kèm 3 thí nghiệm |

## Bản đồ: slide ↔ tài liệu ↔ bài lab

| Slide | Lesson | Tài liệu này | Bài lab |
|---|---|---|---|
| 4–9 | **01** · Metrics và kiến trúc hoạt động của Prometheus | Lesson 01 | BÀI 1 |
| 11–16 | **02** · Tích hợp Spring Boot Actuator và xuất metrics | Lesson 02 | BÀI 2 |
| 18–21 | **03** · Triển khai Prometheus bằng Docker Compose | Lesson 03 | BÀI 3 |
| 23–25 | **04** · Node Exporter giám sát tài nguyên VPS | Lesson 04 | BÀI 4 |

---

# LESSON 01 · METRICS VÀ KIẾN TRÚC CỦA PROMETHEUS

## 1.1 · Production không nên là một "hộp đen"

Khi hệ thống chậm, QuickBite **vẫn nhận được request** — nên nhìn từ ngoài tưởng như không sao. Nhưng đội vận hành cần trả lời được:

| Câu hỏi | Thuộc tầng nào |
|---|---|
| VPS có bị quá tải CPU hoặc RAM không? | **Hạ tầng** |
| JVM của `order-service` có gần đầy Heap không? | **Ứng dụng** |
| Garbage Collection có đang chạy quá nhiều không? | **Ứng dụng** |
| Endpoint nào đang nhận lượng request bất thường? | **Ứng dụng** |
| Sự cố bắt đầu chính xác từ thời điểm nào? | **Lịch sử dữ liệu** |

<div class="keybox">
<span class="lbl">Giải pháp</span>
<p><strong>Chuyển từ suy đoán sang giám sát dữ liệu.</strong></p>
<p>Monitoring theo dõi dữ liệu <strong>liên tục</strong>, thay vì chỉ đoán nguyên nhân khi sự cố đã xảy ra.</p>
</div>

> 💡 **Câu hỏi cuối bảng là câu khó nhất nếu không có monitoring.** Sau khi sự cố qua đi, không còn dấu vết nào để biết nó bắt đầu lúc nào và vì sao. Metrics được lưu liên tục nên bạn **tua ngược lại được**.

## 1.2 · Monitoring và Metrics

| Khái niệm | Ý nghĩa |
|---|---|
| **Monitoring** | Thu thập, xử lý và theo dõi dữ liệu của hệ thống |
| **Metrics** | Giá trị **số** biểu thị trạng thái hệ thống |
| **Timestamp** | Thời điểm ghi nhận giá trị |
| **Labels** | Nhãn giúp phân biệt nguồn hoặc nhóm dữ liệu |

### Cấu trúc một metric

```
http_requests_total{method="POST", handler="/api/v1/orders"} 1250
└──────────┬──────┘└──────────────────┬──────────────────┘ └─┬─┘
       TÊN METRIC                  LABELS                 GIÁ TRỊ
```

> 💡 **Labels là thứ làm metrics hữu dụng.** Cùng tên `http_requests_total` nhưng khác labels là **những chuỗi dữ liệu khác nhau** — nhờ đó bạn tách được request `POST /orders` khỏi `GET /users`, tách service này khỏi service kia.

> ⚠️ **Đừng tạo label có quá nhiều giá trị khác nhau** (ví dụ `user_id`, `order_id`). Mỗi tổ hợp label sinh ra một chuỗi riêng — vài nghìn người dùng là vài nghìn chuỗi, và cơ sở dữ liệu phình rất nhanh. Vấn đề này có tên riêng: **cardinality explosion**.

## 1.3 · Counter và Gauge

| | **Counter** | **Gauge** |
|---|---|---|
| Đặc điểm | **Chỉ tăng**; reset về 0 khi app khởi động lại | Tăng **hoặc giảm** tự do theo trạng thái |
| Ví dụ | `http_requests_total` | `jvm_memory_used_bytes` |
| Ứng dụng | Đếm tổng số request, tổng số lỗi | Đo RAM đang dùng, số thread đang sống |

<div class="keybox">
<span class="lbl">Quy tắc chọn</span>
<p><strong>Counter</strong> cho giá trị tích luỹ luôn tăng (requests, errors).</p>
<p><strong>Gauge</strong> cho chỉ số biến động theo thời gian thực (RAM, CPU, threads).</p>
</div>

<details class="q"><summary><span>Counter chỉ tăng thì làm sao biết "bao nhiêu request mỗi giây"?</span></summary>

Bản thân Counter **không** cho bạn tốc độ — nó chỉ là con số tích luỹ từ lúc ứng dụng khởi động.

Muốn biết tốc độ, bạn dùng hàm `rate()` của PromQL. Nó lấy hai mẫu ở hai thời điểm rồi tính độ chênh chia cho khoảng thời gian:

```
rate(http_requests_total[5m])
```

Hàm này còn xử lý được việc Counter **reset về 0** khi ứng dụng khởi động lại — nếu tự trừ tay, bạn sẽ ra số âm.

PromQL nằm ngoài phạm vi buổi này, nhưng biết tên hàm để sau này tra cứu.
</details>

## 1.4 · Histogram và Summary

| | **Histogram** | **Summary** |
|---|---|---|
| Cách hoạt động | Chia dữ liệu vào các **khoảng (bucket)** rồi đếm | Tính **phân vị** p50, p90, p99 ngay tại client |
| Ví dụ | `http_request_duration_seconds_bucket` | `p99 response time` |
| Ứng dụng | Phân phối thời gian phản hồi, kích thước request | Theo dõi độ trễ theo percentile |

<div class="keybox">
<span class="lbl">Quy tắc chọn</span>
<p><strong>Histogram</strong> khi hệ thống nhiều instance và cần <strong>tổng hợp</strong> latency từ nhiều container.</p>
<p><strong>Summary</strong> khi cần phân vị chính xác trên <strong>từng instance đơn lẻ</strong>.</p>
</div>

> 💡 **Vì sao nhiều instance thì phải dùng Histogram?** Vì **phân vị không cộng được**. p99 của container A và p99 của container B gộp lại **không** ra p99 của cả hệ thống. Histogram thì khác — các bucket là những bộ đếm, và bộ đếm thì cộng được. Prometheus gộp bucket từ mọi instance rồi mới tính phân vị.

> ⚠️ **Spring Boot KHÔNG bật Histogram sẵn.** Bạn sẽ thấy `_count` và `_sum`, nhưng **không có** `_bucket` cho tới khi bật thủ công. Bài lab có thí nghiệm đo tận mắt chuyện này.

## 1.5 · Prometheus chủ động kéo metrics

| | **Pull-based** (Prometheus) | **Push-based** |
|---|---|---|
| Cơ chế | Prometheus gửi **HTTP GET** đến target theo chu kỳ | Ứng dụng **chủ động gửi** metrics về server |
| Ưu điểm | **Dễ phát hiện** target không phản hồi hoặc DOWN | — |
| Lưu ý | — | Có thể nhận dữ liệu **dồn dập** từ nhiều client |
| Phù hợp | Service chạy **lâu dài** | Job chạy **ngắn**, serverless |

> 💡 **Ưu điểm của Pull sâu hơn vẻ ngoài.** Với Push, *"không nhận được dữ liệu"* và *"service đã chết"* trông **giống hệt nhau** — bạn không phân biệt được. Với Pull, chính Prometheus là bên gọi, nên nó biết ngay target nào không trả lời, và **ghi lại điều đó** thành metric `up=0`.

## 1.6 · Luồng scraping trong QuickBite

```
┌──────────────────────┐
│  Prometheus Server   │   1. Đọc cấu hình: danh sách targets + chu kỳ 15s
└──────────┬───────────┘
           │  HTTP GET mỗi 15s
   ┌───────┼────────────────┬──────────────────┐
   ▼       ▼                ▼                  ▼
user-service:8081   order-service:8083   node-exporter:9100
/actuator/prometheus  /actuator/prometheus    /metrics
           │
           ▼  2. Xử lý và lưu
        TSDB trên VPS
```

| Bước | Nội dung |
|---|---|
| **1. Đọc cấu hình** | Xác định danh sách targets và chu kỳ scraping (15s) |
| **2. Xử lý và lưu trữ** | Dữ liệu được phân tích và lưu vào **TSDB** trên VPS |

> 💡 **TSDB = Time Series Database.** Khác cơ sở dữ liệu thông thường ở chỗ mọi bản ghi đều gắn **mốc thời gian**, và nó được tối ưu để trả lời câu hỏi *"giá trị này thay đổi thế nào trong 6 giờ qua?"* — đúng thứ ta cần khi điều tra sự cố.

> ⚠️ Tất cả target phải **cùng một Docker network** với Prometheus, nếu không nó không phân giải được tên service.

---

# LESSON 02 · TÍCH HỢP SPRING BOOT ACTUATOR

## 2.1 · Actuator cung cấp endpoint cho ứng dụng

| Endpoint | Nội dung |
|---|---|
| `/actuator/health` | Trạng thái ứng dụng: **UP** hoặc **DOWN** |
| `/actuator/info` | Thông tin chung của ứng dụng |
| `/actuator/metrics` | Danh sách metrics, **định dạng JSON** |
| `/actuator/prometheus` | Metrics ở **định dạng Prometheus** |

**Lợi ích:**

- **Tự động hoá** — lấy thông tin JVM và ứng dụng mà không cần tự viết code đo đạc
- **Sẵn sàng cho production** — có sẵn health check và thông số hoạt động
- **Tích hợp dễ** — xuất được sang Prometheus, Grafana

## 2.2 · Micrometer chuyển metrics sang định dạng Prometheus

```
┌─────────────────────┐   ┌──────────────────────┐   ┌────────────────────┐
│ 1. Actuator         │──▶│ 2. Micrometer        │──▶│ 3. Prometheus      │
│ thu thập metrics,   │   │ Prometheus Registry  │   │ Server scrape tại  │
│ cung cấp JSON tại   │   │ định dạng lại sang   │   │ /actuator/         │
│ /actuator/metrics   │   │ plain text chuẩn     │   │ prometheus         │
└─────────────────────┘   └──────────────────────┘   └────────────────────┘
```

<div class="keybox">
<span class="lbl">Phân vai cho rõ</span>
<p><strong>Actuator</strong> tạo ra endpoint. <strong>Micrometer</strong> dịch dữ liệu sang định dạng Prometheus hiểu được.</p>
<p>Có Actuator mà thiếu Micrometer thì <code>/actuator/prometheus</code> trả <strong>404</strong>.</p>
</div>

## 2.3 · Thêm dependencies cho order-service

```gradle
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
    implementation 'io.micrometer:micrometer-registry-prometheus'
}
```

Sau khi sửa, tải thư viện mới bằng `./gradlew build` hoặc **Refresh Gradle project** trên IDE.

## 2.4 · Cấu hình endpoint và common tag

> ⚠️ **`application.yml` của service đã có sẵn một khối `management:`.** Sửa khối đó tại chỗ, đừng thêm khối thứ hai:
> YAML không cho hai key trùng ở cùng cấp, app sẽ chết lúc khởi động với `DuplicateKeyException`.
> Kiểm tra nhanh bằng `grep -c '^management:' application.yml` — phải ra đúng `1`.

```yaml
spring:
  application:
    name: order-service

management:
  endpoints:
    web:
      exposure:
        include: health, prometheus
  metrics:
    tags:
      application: ${spring.application.name}
```

| Cấu hình | Tác dụng |
|---|---|
| **Expose endpoints** | Chỉ mở **hai** endpoint cần thiết: `health` và `prometheus` |
| **Common tags** | Gắn nhãn `application="order-service"` vào **mọi** metric |
| **Phân biệt service** | Dễ lọc dữ liệu giữa các microservice trên Grafana/Prometheus |

> 💡 **Common tag khai một lần, có tác dụng với tất cả.** Khi 5 service cùng báo `jvm_memory_used_bytes`, bạn phải biết của ai. Nhãn `application` làm đúng việc đó mà không phải sửa từng chỗ đo.

## 2.5 · Cảnh báo bảo mật Spring Boot Actuator

| ❌ **KHÔNG NÊN** | ✅ **NÊN LÀM trên production** |
|---|---|
| `include: "*"` mở toàn bộ endpoint | Chỉ mở tối thiểu **`health`** và **`prometheus`** |
| Mở cổng metrics ra Internet công cộng | Chỉ cho Prometheus **trong cùng Docker network** truy cập |
| Làm lộ thông tin JVM, biến môi trường, cấu trúc hệ thống | Giới hạn thông tin, chỉ đủ phục vụ vận hành |

> ⚠️ **Không dùng Nginx để proxy cổng metrics ra bên ngoài.** Session 11 dạy đưa dịch vụ ra Internet qua Nginx — nhưng metrics là **ngoại lệ**. Chúng tiết lộ cấu trúc bên trong hệ thống và chỉ dành cho nội bộ.

<details class="q"><summary><span>`include: "*"` nguy hiểm ở mức nào?</span></summary>

Nó mở **toàn bộ** endpoint Actuator, trong đó có những endpoint rất nhạy cảm:

| Endpoint | Tiết lộ gì |
|---|---|
| `/actuator/env` | **Toàn bộ biến môi trường** — có thể gồm mật khẩu database |
| `/actuator/configprops` | Mọi thuộc tính cấu hình |
| `/actuator/beans` | Cấu trúc nội bộ của ứng dụng |
| `/actuator/heapdump` | **Tải về ảnh chụp bộ nhớ** — có thể chứa dữ liệu người dùng |

Spring Boot có che bớt vài giá trị nhạy cảm, nhưng đó không phải lý do để mở hết. Nguyên tắc vẫn là **đặc quyền tối thiểu** — giống `ports` ở Session 10 và tường lửa ở Session 11.
</details>

## 2.6 · Kiểm tra endpoint metrics tại local

```
http://localhost:8083/actuator/prometheus
```

Kết quả là **text thuần** theo định dạng Prometheus:

```
# HELP jvm_memory_used_bytes The amount of used memory
# TYPE jvm_memory_used_bytes gauge
jvm_memory_used_bytes{application="order-service", area="heap"} 4.194304E7
```

| Dòng | Vai trò |
|---|---|
| `# HELP` | Mô tả metric dùng để làm gì |
| `# TYPE` | Loại metric — `counter`, `gauge`, `histogram`, `summary` |
| Dòng dữ liệu | Tên + labels + giá trị |

**Nếu endpoint trả `404`:**

1. Kiểm tra đã thêm đủ **hai** dependencies Actuator và Micrometer chưa
2. Xác nhận `exposure.include` trong `application.yml` đã có `prometheus`

**Nếu container restart liên tục, chưa kịp trả gì:** xem `docker logs <container>`. Gặp `DuplicateKeyException` nghĩa là
`application.yml` đang có **hai** khối `management:` — gộp lại làm một rồi build lại.

> 💡 **Dòng `# TYPE` cho bạn biết ngay đó là loại metric nào** — không cần đoán qua tên. Đây là cách nhanh nhất để kiểm chứng những gì Lesson 01 đã học.

---

# LESSON 03 · TRIỂN KHAI PROMETHEUS BẰNG DOCKER COMPOSE

## 3.1 · Cấu hình chu kỳ và target trong `prometheus.yml`

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: quickbite-backend
    metrics_path: /actuator/prometheus
    static_configs:
      - targets:
          - user-service:8081
          - order-service:8083
```

| Cấu hình | Ý nghĩa |
|---|---|
| `scrape_interval` | Chu kỳ Prometheus kéo metrics |
| `job_name` | Tên nhóm target |
| `metrics_path` | Đường dẫn endpoint metrics |
| `targets` | Danh sách service và cổng cần thu thập |

> ⚠️ **`metrics_path` khác nhau giữa hai loại target.** Spring Boot dùng `/actuator/prometheus`, còn Node Exporter dùng `/metrics`. Vì vậy chúng phải nằm ở **hai `job` riêng**, không gộp chung được.

## 3.2 · Dùng DNS nội bộ của Docker

| Nguyên lý | Nội dung |
|---|---|
| **Dùng Service Name thay cho IP** | Kết nối linh hoạt, không phụ thuộc IP động của container |
| **Tránh rủi ro đổi IP** | IP container **đổi sau mỗi lần** `restart` hoặc `recreate` |
| **Yêu cầu chung network** | Prometheus và backend phải cùng tham gia một mạng |

> 💡 **Đây đúng là cơ chế API Gateway đã dùng từ Session 05.** Gateway gọi `http://user-service:8081` chứ không gọi IP. Giờ Prometheus làm y hệt. Một ý tưởng, hai chỗ dùng.

## 3.3 · Prometheus lưu lịch sử bằng volume

```yaml
prometheus:
  image: prom/prometheus:v2.45.0
  container_name: quickbite-prometheus
  volumes:
    - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    - prometheus-data:/prometheus
  networks:
    - quickbite-net

volumes:
  prometheus-data:
```

| Nguyên lý | Nội dung |
|---|---|
| **Mount file cấu hình** | `prometheus.yml` được mount vào container |
| **Bảo toàn TSDB** | Named volume `prometheus-data` giữ lịch sử khi container bị **ngắt, xoá hoặc tái tạo** |
| **An toàn mạng nội bộ** | **Không** public cổng `9090:9090` ra host |

> ⚠️ **Giao diện web của Prometheus không có đăng nhập.** Publish cổng 9090 ra Internet là cho bất kỳ ai xem toàn bộ metrics hệ thống — và metrics tiết lộ rất nhiều về cấu trúc bên trong.

<details class="q"><summary><span>Volume giữ được dữ liệu tới mức nào?</span></summary>

Bài lab có thí nghiệm đo thật: xoá hẳn container bằng `docker compose rm -sf` rồi dựng lại — **dữ liệu lịch sử vẫn còn**.

| Lệnh | Dữ liệu còn không |
|---|---|
| `docker compose rm -sf` | ✅ Còn |
| `docker compose down` | ✅ Còn |
| **`docker compose down -v`** | ❌ **Mất hết** |

> ⚠️ Cờ `-v` xoá luôn volume. Chạy nhầm trên máy chủ production là mất sạch lịch sử giám sát — thứ bạn cần nhất khi đang điều tra sự cố.
</details>

## 3.4 · Khởi chạy và kiểm tra targets

```
docker compose up -d prometheus
docker compose ps
docker exec -it quickbite-prometheus wget -qO- http://localhost:9090/api/v1/targets
```

**Kết quả cần kiểm tra:**

| Mục | Phải thấy |
|---|---|
| Trạng thái container | Prometheus ở trạng thái **Up / Running** |
| Danh sách target | Xuất hiện đầy đủ trong JSON trả về |
| Trạng thái health | Target backend hiển thị **`health: up`** |

**Khi target ở trạng thái DOWN, kiểm tra lần lượt:**

1. **Trạng thái service** — đã khởi chạy chưa
2. **Log container** — tìm lỗi ứng dụng
3. **Cổng truy cập** — đã đúng port chưa
4. **Docker network** — có cùng mạng không

> 💡 **Nhanh hơn cả bốn bước trên: đọc trường `lastError` trong JSON.** Nó nói thẳng vì sao scrape thất bại:
>
> | `lastError` | Nghĩa |
> |---|---|
> | `404` | Gọi tới được nhưng **endpoint không tồn tại** → thiếu Micrometer |
> | `connection refused` | Service **chưa chạy** hoặc sai cổng |
> | `no such host` | Sai tên service hoặc **khác mạng** |
> | `context deadline exceeded` | Service **quá chậm** |

<details class="q"><summary><span>Metric `up` từ đâu ra?</span></summary>

`up` **không** do service gửi lên — nó do **chính Prometheus sinh ra** sau mỗi lần scrape:

| Giá trị | Nghĩa |
|---|---|
| `up=1` | Lần scrape gần nhất thành công |
| `up=0` | Lần scrape gần nhất thất bại |

Đây chính là lợi thế của Pull-based đã nói ở Lesson 01: Prometheus là bên gọi nên nó **biết** target nào chết, và ghi lại thành dữ liệu để sau này tra cứu được.

> ⚠️ Sửa xong mà `up` vẫn bằng `0` thì thường chỉ là **chưa tới chu kỳ scrape tiếp theo**. Đợi đủ 15 giây rồi xem lại.
</details>

---

# LESSON 04 · NODE EXPORTER GIÁM SÁT TÀI NGUYÊN VPS

## 4.1 · Node Exporter giám sát cấp hệ điều hành

| | **Node Exporter** (Hạ tầng VPS) | **Spring Boot Actuator** (Ứng dụng JVM) |
|---|---|---|
| Phạm vi | CPU, RAM vật lý, Disk I/O, Network của **host** | Heap, GC, threads, HTTP requests của **JVM** |
| Cổng | **9100** | Cổng của từng service |
| Endpoint | `/metrics` | `/actuator/prometheus` |
| Tích hợp | Chạy như một container riêng | **Nhúng trong từng microservice** |
| Mục đích | Sức khoẻ tổng thể của server | Hiệu năng bên trong ứng dụng |

<div class="keybox">
<span class="lbl">Vì sao cần cả hai</span>
<p>Kết hợp Node Exporter và Actuator để xác định nguyên nhân gốc rễ nằm ở <strong>Hạ tầng</strong> hay <strong>Ứng dụng</strong>.</p>
</div>

> 💡 **Một ví dụ cụ thể.** Hệ thống chậm:
>
> | RAM máy chủ | JVM heap | Kết luận |
> |---|---|---|
> | Còn nhiều | Gần đầy | Lỗi ở **ứng dụng** — rò rỉ bộ nhớ hoặc heap cấp quá nhỏ |
> | Cạn kiệt | Bình thường | Lỗi ở **hạ tầng** — container khác đang ngốn RAM |
>
> Chỉ nhìn một tầng thì không phân biệt được hai trường hợp này.

## 4.2 · Mount tài nguyên host ở chế độ Read-Only

```yaml
node-exporter:
  image: prom/node-exporter:v1.6.0
  volumes:
    - /proc:/host/proc:ro
    - /sys:/host/sys:ro
    - /:/rootfs:ro
  command:
    - --path.procfs=/host/proc
    - --path.sysfs=/host/sys
  networks:
    - quickbite-net
```

| Mount | Dữ liệu chính |
|---|---|
| `/proc` | Tiến trình, RAM và CPU |
| `/sys` | Thiết bị và thông tin kernel |
| `/` | Dung lượng filesystem của host |

> ⚠️ **Cờ `:ro` bảo đảm Node Exporter chỉ đọc dữ liệu host**, ngăn mọi nguy cơ ghi đè hoặc can thiệp vào hệ điều hành.

> 💡 **Vì sao phải mount vào mới đọc được?** Vì container **bị cô lập** — nó chỉ thấy tiến trình và tài nguyên của chính nó. Muốn đọc được của máy chủ thì phải mount `/proc` và `/sys` của host vào. Các cờ `--path.procfs` báo cho Node Exporter biết chúng nằm ở đâu bên trong container.

## 4.3 · Thêm Node Exporter vào Prometheus

```yaml
- job_name: vps-hardware
  metrics_path: /metrics
  static_configs:
    - targets:
        - node-exporter:9100
```

```
docker compose up -d node-exporter
docker compose restart prometheus
docker exec -it quickbite-prometheus wget -qO- http://localhost:9090/api/v1/targets
```

> ⚠️ **Phải `restart prometheus` sau khi sửa `prometheus.yml`.** Prometheus **chỉ đọc file cấu hình lúc khởi động** — khác với Nginx có `reload`. Sửa file xong mà không restart thì nó vẫn chạy cấu hình cũ.

> 💡 **Không cần mở cổng 9100 ra host.** Prometheus truy cập Node Exporter trực tiếp qua mạng nội bộ, đúng như nguyên tắc `ports` của Session 10.

---

# TỔNG KẾT

| # | Nội dung |
|---|---|
| **1** | **Metrics** là dữ liệu số có timestamp và labels để theo dõi trạng thái hệ thống |
| **2** | Prometheus dùng **Pull-based** để thu thập và lưu metrics vào **TSDB** |
| **3** | **Actuator** và **Micrometer** xuất metrics của Spring Boot tại `/actuator/prometheus` |
| **4** | `prometheus.yml` dùng **tên service Docker** để tìm backend trong cùng network |
| **5** | **Volume** giữ lịch sử metrics; **không expose** cổng Prometheus 9090 ra Internet |
| **6** | **Node Exporter** đọc CPU, RAM, Disk và Network của VPS qua các mount **Read-Only** |

## Ba điều nếu chỉ nhớ được ba điều

1. **Actuator tạo endpoint, Micrometer dịch định dạng.** Thiếu một trong hai là `404`.
2. **Metrics chỉ dành cho nội bộ.** Không publish cổng, không proxy qua Nginx.
3. **Hai tầng giám sát trả lời hai câu khác nhau.** Phải có cả hai mới khoanh được nguyên nhân.

# Bảng tra nhanh

| Việc | Lệnh |
|---|---|
| Xem metrics thô của service | `wget -qO- http://localhost:8083/actuator/prometheus` |
| Khởi chạy Prometheus | `docker compose up -d prometheus` |
| Nạp lại cấu hình Prometheus | `docker compose restart prometheus` |
| Xem danh sách targets | `wget -qO- http://localhost:9090/api/v1/targets` |
| Truy vấn metric | `wget -qO- "http://localhost:9090/api/v1/query?query=up"` |
| Liệt kê mọi tên metric | `wget -qO- "http://localhost:9090/api/v1/label/__name__/values"` |
| Xem log | `docker compose logs --tail=30 prometheus` |

# Từ khoá cần phân biệt

| Cặp khái niệm | Khác nhau ở |
|---|---|
| Monitoring ↔ Metrics | Hoạt động theo dõi ↔ **Dữ liệu số** được theo dõi |
| Counter ↔ Gauge | Chỉ tăng ↔ **Tăng và giảm** |
| Histogram ↔ Summary | Chia bucket, **gộp được** nhiều instance ↔ Tính phân vị tại client |
| Pull ↔ Push | Prometheus **gọi vào** ↔ App tự gửi ra |
| Actuator ↔ Micrometer | Tạo **endpoint** ↔ Dịch **định dạng** |
| `/actuator/metrics` ↔ `/actuator/prometheus` | JSON ↔ **Text định dạng Prometheus** |
| `/actuator/prometheus` ↔ `/metrics` | Spring Boot ↔ **Node Exporter** |
| Node Exporter ↔ Actuator | Tầng **máy chủ** ↔ Tầng **ứng dụng** |
| `down` ↔ `down -v` | Giữ volume ↔ **Xoá sạch lịch sử** |
