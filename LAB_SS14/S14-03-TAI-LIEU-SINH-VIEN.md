# TÀI LIỆU SINH VIÊN — SESSION 14
# Tạo Dashboard với Grafana

Buổi trước bạn đã có Prometheus thu thập và lưu metrics. Buổi này biến đống số đó thành thứ nhìn vào là hiểu.

> 💡 **Cách đọc tài liệu này.** Khối có nhãn `bash` là lệnh để chạy. Khối không nhãn là **kết quả phải thấy**, đừng copy vào terminal.

## Bản đồ: slide ↔ tài liệu ↔ bài lab

| Slide | Tài liệu | Bài lab |
|---|---|---|
| 4–9 | Lesson 01 | PHẦN 1 |
| 11–15 | Lesson 02 | PHẦN 2 |
| 17–23 | Lesson 03 | PHẦN 3 |
| 25–31 | Lesson 04 | PHẦN 4 |
| 33–37 | Lesson 05 | PHẦN 5 |

> ⚠️ **Điều kiện bắt buộc trước khi bắt đầu.** Buổi này không dựng gì mới từ số 0 — nó cắm vào hệ thống đã có:
>
> | Cần có | Từ buổi nào |
> |---|---|
> | 6 container QuickBite đang chạy | Session 05 |
> | `order-service` và `user-service` đã có Micrometer | **Session 13, BÀI 2** |
> | Prometheus và Node Exporter đang chạy | Session 13, BÀI 3–4 |
>
> Thiếu Micrometer thì dashboard JVM ở Lesson 04 sẽ trống trơn — không phải lỗi Grafana.

---

# LESSON 01 · GRAFANA VÀ VAI TRÒ TRONG HỆ THỐNG GIÁM SÁT

## 1.1 · Prometheus có dữ liệu nhưng giao diện còn hạn chế

| | **Prometheus** | **Grafana** |
|---|---|---|
| Chức năng | Thu thập metrics từ các target | Truy vấn dữ liệu từ Prometheus |
| Lưu trữ | Lưu dữ liệu chuỗi thời gian (TSDB) | Không lưu metrics |
| Giao diện | Truy vấn đơn giản, mỗi lần một câu | Nhiều biểu đồ trong một dashboard |
| Widget | Không có | Graph, Stat, Gauge, bảng số liệu |
| Bảo mật | **Không có đăng nhập mặc định** | Có tài khoản và phân quyền |

<div class="keybox">
<span class="lbl">Vai trò của Grafana</span>
<p>Biến dữ liệu metrics từ Prometheus thành thông tin trực quan, phục vụ theo dõi và ra quyết định khi vận hành.</p>
</div>

> 💡 **Dòng "không có đăng nhập mặc định" giải thích một quyết định ở Session 13.** Vì Prometheus không có đăng nhập, bài trước **không publish cổng 9090** ra ngoài. Grafana thì có tài khoản, nên nó được phép mở cổng 3000 — đó là lý do hai service này được đối xử khác nhau.

## 1.2 · Grafana là gì?

**Đặc điểm nền tảng**

- **Bản chất** — nền tảng mã nguồn mở chuyên trực quan hóa và phân tích dữ liệu chuỗi thời gian (time-series).
- **Cơ chế lưu trữ** — **không** tự thu thập hay lưu metrics. Nó chỉ lưu cấu hình dashboard, alert rule và thông tin người dùng trong database riêng.

**Khả năng kết nối (Data Sources)**

| Data Source | Dùng cho |
|---|---|
| **Prometheus** | Time-series metrics hệ thống |
| InfluxDB | Time-series cho IoT / Metrics |
| Elasticsearch | Log analysis và search |
| MySQL và các RDBMS | Dữ liệu nghiệp vụ truyền thống |

<div class="keybox">
<span class="lbl">Tóm tắt</span>
<p>Grafana là <strong>trung tâm trực quan hóa</strong> — một giao diện hiển thị hợp nhất cho nhiều nguồn dữ liệu, không can thiệp vào tầng lưu trữ gốc.</p>
</div>

> 💡 **Vì sao Grafana vẫn cần database riêng nếu không lưu metrics?** Vì dashboard bạn dựng, alert rule bạn đặt và tài khoản bạn tạo phải sống sót qua lần restart. Đó chính là lý do file compose có volume `grafana-data` — mất volume là mất hết dashboard, dù metrics trong Prometheus vẫn còn nguyên.

## 1.3 · Prometheus và Grafana bổ trợ cho nhau

| Thành phần | Trách nhiệm |
|---|---|
| **Prometheus** | Kéo metrics từ target và lưu vào TSDB |
| **Grafana** | Gửi truy vấn PromQL và hiển thị kết quả |

<div class="keybox">
<span class="lbl">Mối quan hệ</span>
<p>Grafana <strong>không thay thế</strong> Prometheus. Grafana là giao diện hiển thị, dùng Prometheus làm Data Source chính để truy vấn.</p>
</div>

## 1.4 · Luồng dữ liệu giám sát

```
1. Microservices / Targets          2. Prometheus Server        3. Grafana
   Node Exporter, Spring Boot          cong :9090                  cong :3000
   expose metrics qua HTTP             thu thap & luu TSDB         dashboard van hanh
              │                                 │                        │
              └────── Pull moi 15s ────────────▶│                        │
                                                │◀──── PromQL qua HTTP API ┘
```

| Chặng | Nội dung |
|---|---|
| **Thu thập và lưu trữ** | Prometheus chủ động **kéo** metrics định kỳ từ target, lưu vào TSDB |
| **Truy vấn và hiển thị** | Grafana gửi **PromQL** qua HTTP API của Prometheus |
| **Môi trường** | Các container gọi nhau qua **mạng Docker nội bộ** |

> ⚠️ **Slide ghi mạng là `quickbite-net`, còn repo dùng `quickbite5-net`.** Tài liệu này dùng tên thật trong repo. Trên dự án của bạn, dùng đúng tên mà `docker network ls` hiển thị.

## 1.5 · Cài đặt Grafana bằng Docker Compose

```yaml
services:
  grafana:
    image: grafana/grafana:10.0.3
    container_name: quickbite-grafana
    ports:
      - "${GRAFANA_HOST_PORT:-3000}:3000"
    volumes:
      - grafana-data:/var/lib/grafana
      - ./provisioning:/etc/grafana/provisioning:ro
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GF_ADMIN_PASSWORD:-quickbite_lab_2026}
    networks:
      - quickbite5-net
    restart: unless-stopped

volumes:
  grafana-data:

networks:
  quickbite5-net:
    external: true
```

| Cấu hình | Tác dụng |
|---|---|
| **Cổng 3000** | Truy cập giao diện web của Grafana |
| **Volume `grafana-data`** | Giữ dashboard, user và cấu hình Data Source qua các lần restart |
| **Mạng nội bộ** | Cùng mạng với Prometheus mới gọi nhau bằng tên được |
| **Mật khẩu admin** | Khai báo qua biến môi trường, không ghi thẳng vào file |

> ⚠️ **Cổng 3000 là cổng dev phổ biến nhất.** React, Next.js, Node thường chiếm sẵn. Nếu `docker compose up` báo `address already in use`, đổi cổng chứ đừng tắt ứng dụng đang chạy của bạn:
>
> ```
> GRAFANA_HOST_PORT=3001 ./tao-grafana.sh
> ```
>
> Cổng 3001 cũng hay bị chiếm. Nếu vẫn báo lỗi thì thử 3002, 3003. Kiểm trước bằng
> `lsof -nP -iTCP:3002 -sTCP:LISTEN` — không in gì là dùng được.

## 1.6 · Khởi chạy và bảo vệ tài khoản quản trị

```bash
docker compose up -d grafana
docker compose ps
```

| Mục | Nội dung |
|---|---|
| Username ban đầu | `admin` |
| Mật khẩu khởi tạo | Lấy từ biến môi trường đã khai |
| Đổi mật khẩu | **Bắt buộc** đổi ngay ở lần đăng nhập đầu |
| Bảo mật repo | **Tuyệt đối không** commit mật khẩu thật lên repository |

> 💡 **Vì sao mật khẩu đặt qua biến môi trường mà vẫn phải đổi?** Vì mật khẩu trong file compose nằm trong Git — ai đọc được repo là đăng nhập được. Biến môi trường chỉ giúp bạn không hard-code; đổi mật khẩu sau lần đăng nhập đầu mới thật sự bảo vệ.

---

# LESSON 02 · KẾT NỐI GRAFANA VỚI PROMETHEUS

## 2.1 · Grafana và Prometheus phải dùng đúng địa chỉ

| Địa chỉ | Kết quả |
|---|---|
| `http://localhost:9090` | ❌ Grafana gọi vào **chính container Grafana** — không có gì ở đó |
| `http://<ip_public_vps>:9090` | ❌ Có thể bị UFW chặn, và không cần mở public |
| **`http://quickbite-prometheus:9090`** | ✅ Đúng — gọi Prometheus qua mạng Docker |

- **Kết nối nội bộ** — Grafana và Prometheus phải cùng mạng.
- **Định danh bằng tên service** — dùng tên container thay vì IP tĩnh hay `localhost`.
- **Bảo mật** — tránh public cổng Prometheus ra Internet nếu không thật sự cần.

> 💡 **`localhost` bên trong container không phải máy của bạn.** Mỗi container có `localhost` riêng của nó. Grafana gõ `localhost:9090` là đang gõ cửa chính mình. Đây đúng là bài học DNS nội bộ từ Session 13, giờ gặp lại ở một chỗ khác.

## 2.2 · Data Source là gì?

- **Khái niệm** — cấu hình kết nối từ Grafana đến một hệ thống lưu trữ dữ liệu.
- **Giao thức** — với Prometheus, Grafana nói chuyện qua HTTP REST API.
- **Truy vấn** — Grafana gửi câu lệnh **PromQL**.
- **Phản hồi** — dữ liệu trả về dạng time-series JSON.
- **Trực quan hóa** — kết quả được dựng thành Panel, gom nhóm thành Dashboard.

## 2.3 · Thêm Prometheus Data Source

| Bước | Thao tác |
|---|---|
| 1 | Đăng nhập Grafana |
| 2 | Chọn **Connections → Data sources** |
| 3 | Chọn **Add data source → Prometheus** |
| 4 | Đặt tên: `Prometheus` |
| 5 | Nhập URL: `http://quickbite-prometheus:9090` |
| 6 | Nhấn **Save & test** |

**Kết quả phải thấy**

```
Successfully queried the Prometheus API.
```

**Nếu báo lỗi, kiểm tra theo thứ tự:**

1. URL có dùng tên container `quickbite-prometheus` không, hay đang để `localhost`
2. Grafana và Prometheus có cùng mạng Docker không

## 2.4 · Thử truy vấn bằng Explore

| Bước | Thao tác |
|---|---|
| 1 | Mở **Explore** ở menu bên trái |
| 2 | Chọn Data Source là **Prometheus** |
| 3 | Chuyển từ **Builder** sang **Code** |
| 4 | Nhập: `jvm_memory_used_bytes` |
| 5 | Nhấn **Run query** hoặc `Shift + Enter` |

Grafana vẽ biểu đồ biến động bộ nhớ JVM của các service mà Prometheus đã thu thập.

> 💡 **Explore là chỗ nên thử câu truy vấn trước khi đưa vào dashboard.** Nó không lưu gì, chạy sai cũng không hỏng dashboard nào. Dựng panel rồi mới sửa truy vấn thì chậm hơn nhiều.

---

# LESSON 03 · TẠO DASHBOARD GIÁM SÁT VPS

## 3.1 · Import dashboard có sẵn bằng ID

Cộng đồng Grafana chia sẻ hàng ngàn dashboard dưới dạng cấu hình JSON tại `grafana.com/grafana/dashboards`. Chỉ cần nhập ID là tải được toàn bộ giao diện.

**Node Exporter Full — ID `1860`**

| Lợi ích | Nội dung |
|---|---|
| Tạo nhanh | Không phải dựng tay từng panel |
| CPU và RAM | Phần trăm tải CPU, dung lượng RAM đã dùng |
| Disk I/O | Tốc độ đọc/ghi, dung lượng trống |
| Network | Băng thông, lưu lượng gói tin vào/ra |

## 3.2 · Các loại Panel thường dùng

| Panel | Mục đích | Ví dụ |
|---|---|---|
| **Graph / Time series** | Xem biến động theo thời gian | CPU Load, Network Traffic |
| **Stat** | Hiển thị một giá trị hoặc trạng thái | Uptime, node UP/DOWN |
| **Gauge** | Hiển thị mức độ theo phần trăm | RAM hoặc Disk đã dùng |

> ⚠️ **Chọn loại Panel theo câu hỏi cần trả lời, không theo hình thức hiển thị.** "RAM còn bao nhiêu phần trăm" là câu hỏi về mức độ → Gauge. "RAM có đang tăng dần không" là câu hỏi về xu hướng → Time series. Cùng một metric, hai panel khác nhau.

## 3.3 · PromQL cho tài nguyên VPS

### CPU đang sử dụng

```
100 - (
  avg by (instance) (
    irate(node_cpu_seconds_total{mode="idle"}[5m])
  ) * 100
)
```

| Thành phần | Ý nghĩa |
|---|---|
| `100 - (...)` | Lấy 100% trừ tỷ lệ CPU đang rảnh để ra % CPU đang làm việc |
| `mode="idle"` | Lọc phần thời gian CPU không làm gì |
| `[5m]` | Lấy biến động trong 5 phút gần nhất |

> 💡 **Vì sao dùng `irate()` chứ không `rate()`?** `irate()` tính tốc độ thay đổi **tức thời** dựa trên hai điểm cuối, cho kết quả nhạy và mượt hơn với chỉ số biến động nhanh như CPU. `rate()` lấy trung bình cả khoảng, phù hợp hơn cho chỉ số tăng đều như số request.

### RAM đã sử dụng

```
(
  node_memory_MemTotal_bytes -
  node_memory_MemAvailable_bytes
) / node_memory_MemTotal_bytes * 100
```

> 💡 **Dùng `MemAvailable` chứ không `MemFree`.** `MemFree` chỉ là RAM hoàn toàn chưa đụng tới. `MemAvailable` tính cả bộ nhớ đệm có thể giải phóng ngay khi cần — đó mới là con số phản ánh đúng RAM thực sự còn dùng được.

### Disk đã sử dụng

```
100 - (
  node_filesystem_avail_bytes{mountpoint="/"}
  * 100 /
  node_filesystem_size_bytes{mountpoint="/"}
)
```

> ⚠️ **Câu này đúng trên VPS Linux thật, nhưng trả về rỗng khi học trên máy Mac/Windows.** Lý do: Node Exporter chạy trong Docker Desktop chỉ nhìn thấy filesystem của **máy ảo Docker**, không thấy ổ đĩa macOS/Windows, và máy ảo đó không báo cáo mountpoint `/`.
>
> Khi học trên máy cá nhân, đổi mountpoint để thấy ổ đĩa Docker:
>
> ```
> 100 - (
>   node_filesystem_avail_bytes{mountpoint="/var/lib/docker"}
>   * 100 /
>   node_filesystem_size_bytes{mountpoint="/var/lib/docker"}
> )
> ```
>
> Muốn biết máy bạn có những mountpoint nào, chạy `node_filesystem_size_bytes` trong Explore rồi xem nhãn `mountpoint`.

<details class="q"><summary><span>Vì sao phải lọc `mountpoint`, không lấy hết?</span></summary>

Vì một máy có rất nhiều filesystem ảo và mount tạm: `tmpfs`, overlay của Docker, mount chia sẻ file... Lấy hết thì số liệu vô nghĩa — bạn sẽ cộng cùng một ổ đĩa nhiều lần, hoặc tính cả những vùng nhớ RAM giả làm ổ đĩa.

Lọc đúng một mountpoint cho bạn con số trả lời được câu hỏi thật: *"ổ chứa dữ liệu đã đầy bao nhiêu phần trăm?"*
</details>

## 3.4 · Import Node Exporter Full

| Bước | Thao tác |
|---|---|
| 1 | **Dashboards → New → Import** |
| 2 | Nhập ID `1860` rồi nhấn **Load** |
| 3 | Đổi tên thành `QuickBite VPS Monitoring` |
| 4 | Chọn Folder: `General` |
| 5 | Chọn Data Source: `Prometheus` |
| 6 | Nhấn **Import** |

Dashboard hiển thị đầy đủ panel theo dõi CPU, RAM, Disk và Network.

---

# LESSON 04 · TẠO DASHBOARD GIÁM SÁT SPRING BOOT SERVICE

## 4.1 · Hai tầng giám sát, hai câu hỏi khác nhau

| | **Node Exporter** (Hạ tầng VPS) | **Spring Boot Actuator** (Ứng dụng JVM) |
|---|---|---|
| Phạm vi | CPU, RAM vật lý, Disk I/O, Network của host | Heap, GC, threads, HTTP requests của JVM |
| Cổng | 9100 | Cổng của từng service |
| Endpoint | `/metrics` | `/actuator/prometheus` |
| Tích hợp | Container riêng | Nhúng trong từng microservice |

<div class="keybox">
<span class="lbl">Vì sao cần cả hai</span>
<p>Kết hợp hai tầng để xác định nguyên nhân gốc rễ nằm ở <strong>Hạ tầng</strong> hay <strong>Ứng dụng</strong>.</p>
</div>

## 4.2 · Dashboard JVM cho Spring Boot

| Dashboard | ID |
|---|---|
| **JVM (Micrometer)** | `4701` |
| JVM APM Option | `11378` |

Nguồn dữ liệu là chính Micrometer mà Spring Boot Actuator xuất ra — thứ bạn đã bật ở Session 13.

**Chỉ số trọng yếu**

- **Heap và Non-Heap** — Eden, Survivor, Tenured và Metaspace
- **Garbage Collection** — tần suất, thời gian tạm dừng, số đợt GC
- **Threads** — live, daemon, peak, và trạng thái Blocked/Waiting
- **HTTP Requests** — throughput, latency, tỉ lệ lỗi 4xx/5xx

## 4.3 · Các chỉ số JVM cần theo dõi

| Nhóm | Metric | Câu hỏi cần trả lời |
|---|---|---|
| **Heap** | `jvm_memory_used_bytes`, `jvm_memory_max_bytes` | Heap có tiến sát giới hạn không? |
| **GC** | `rate(jvm_gc_pause_seconds_sum[5m])` | Ứng dụng có dành quá nhiều thời gian cho GC không? |
| **Threads** | `jvm_threads_states_threads` | Có nhiều thread bị Blocked hoặc Waiting không? |

> ⚠️ **Heap tăng sát Max liên tục** có thể là dấu hiệu cần điều tra OOM hoặc memory leak.

## 4.4 · PromQL cho HTTP Request

### Throughput — số request mỗi giây

```
sum(
  rate(http_server_requests_seconds_count[5m])
) by (uri, status)
```

| Thành phần | Ý nghĩa |
|---|---|
| `rate(..._count[5m])` | Số request trung bình mỗi giây trong 5 phút |
| `by (uri, status)` | Tách theo đường dẫn và mã trạng thái |

Dùng để biết API nào đang nhận nhiều lưu lượng nhất, và endpoint nào đang trả về 4xx/5xx.

### Latency trung bình

```
sum(
  rate(http_server_requests_seconds_sum[5m])
) by (uri)
/
sum(
  rate(http_server_requests_seconds_count[5m])
) by (uri)
```

Lấy **tổng thời gian** chia **tổng số request** trong cùng cửa sổ thời gian, ra thời gian xử lý trung bình theo từng API.

> 💡 **Công thức chia `_sum` cho `_count` là mô hình chuẩn của PromQL để đo latency trung bình.** Nhưng nhớ lại Session 13: số trung bình che mất các trường hợp cá biệt. Latency trung bình đẹp vẫn có thể đi kèm một nhóm nhỏ người dùng phải chờ rất lâu. Muốn thấy nhóm đó thì cần percentile, và percentile cần Histogram bucket.

## 4.5 · Import Dashboard JVM Micrometer

| Bước | Thao tác |
|---|---|
| 1 | **Dashboards → New → Import** |
| 2 | Nhập ID `4701` rồi nhấn **Load** |
| 3 | Đặt tên: `QuickBite JVM Monitoring` |
| 4 | Chọn Data Source: `Prometheus` |
| 5 | Nhấn **Import** |
| 6 | Dùng bộ lọc **Application** để chọn microservice |

Bộ lọc `Application` phải liệt kê được `order-service` và `user-service`.

> ⚠️ **Bộ lọc Application trống nghĩa là service chưa có nhãn `application`.** Nhãn này do `metrics.tags.application` trong `application.yml` sinh ra — phần bạn cấu hình ở Session 13 mục 2.4. Không có nhãn thì dashboard không biết gom metric theo service nào, và mọi panel sẽ trống.

## 4.6 · Đọc biểu đồ Heap và Garbage Collection

**Chu kỳ bình thường**

1. **Heap tăng** — ứng dụng liên tục tạo object mới
2. **GC dọn dẹp** — Garbage Collection thu hồi object không còn dùng
3. **Heap giảm** — bộ nhớ được giải phóng

Đồ thị Heap chuẩn có dạng **răng cưa**: tăng rồi giảm liên tục.

<div class="keybox">
<span class="lbl">Dấu hiệu Memory Leak</span>
<p>Răng cưa là bình thường. Nhưng nếu <strong>đáy</strong> của sóng răng cưa tăng dần theo thời gian dù GC vẫn chạy, đó là dấu hiệu rõ nhất của rò rỉ bộ nhớ.</p>
</div>

> 💡 **Đừng kết luận memory leak chỉ bằng biểu đồ.** Biểu đồ cho bạn biết *có chuyện gì đó*, nhưng muốn biết object nào không được giải phóng thì phải phân tích Heap Dump.

---

# LESSON 05 · CẤU HÌNH CẢNH BÁO KHI SERVICE GẶP SỰ CỐ

## 5.1 · Alerting Workflow của Grafana

| Bước | Thành phần | Nhiệm vụ |
|---|---|---|
| 1 | **Alert Rule** | Điều kiện ngưỡng viết bằng PromQL |
| 2 | **Contact Point** | Kênh nhận thông báo (Discord, Telegram, Email) |
| 3 | **Notification Policy** | Định tuyến cảnh báo bằng cách ghép Labels với kênh nhận |
| 4 | **Tin nhắn** | Gửi chi tiết sự cố tới người quản trị |

Grafana liên tục đánh giá chỉ số theo chu kỳ. Khi điều kiện thỏa mãn, nó tổng hợp dữ liệu, định tuyến qua Notification Policy và gửi tin nhắn.

## 5.2 · Các trạng thái của Alert Rule

| Trạng thái | Ý nghĩa |
|---|---|
| **Normal** | Chỉ số trong ngưỡng an toàn |
| **Pending** | Điều kiện lỗi đã xuất hiện nhưng **chưa đủ lâu** |
| **Firing** | Lỗi kéo dài quá Pending period — cảnh báo được gửi |
| **Resolved** | Chỉ số trở lại bình thường — gửi thông báo khôi phục |

<div class="keybox">
<span class="lbl">Vai trò của Pending period</span>
<p>Giảm cảnh báo giả do tăng đột biến ngắn hạn hoặc do quá trình deploy. Đội vận hành chỉ nhận thông báo khi sự cố thật sự kéo dài.</p>
</div>

## 5.3 · Tạo Contact Point qua Discord

| Bước | Thao tác |
|---|---|
| 1 | Tạo channel `#system-alerts` trên Discord |
| 2 | Tạo **Webhook** trong phần Integrations của channel |
| 3 | Vào Grafana: **Alerting → Contact points** |
| 4 | Chọn **Add contact point** |
| 5 | Chọn integration **Discord** |
| 6 | Dán Webhook URL, nhấn **Test** rồi **Save** |

> ⚠️ **Webhook URL là thông tin nhạy cảm.** Nó chứa mã xác thực cho phép gửi thẳng tin nhắn vào channel. Tuyệt đối không commit file chứa URL này lên Git công khai, và không đưa vào slide dùng chung.

## 5.4 · Tạo Alert Rule khi service bị DOWN

| Mục | Giá trị |
|---|---|
| Rule Name | `Service Down Alert` |
| Data Source | `Prometheus` |
| Query (A) | `up` |
| Condition | **WHEN A IS BELOW 1** |
| Evaluation Interval | `1m` |
| Pending Period (For) | `2m` |
| Folder | `QuickBite Alerts` |
| Contact Point | `Discord-Alerts` |

> ⚠️ **Slide ghi `up == 0` với điều kiện `IS ABOVE 0` — cấu hình đó KHÔNG BAO GIỜ kêu.**
>
> Lý do: `up == 0` là một bộ lọc, nó trả về những chuỗi **có giá trị bằng 0**. Giá trị đưa sang bước điều kiện vì thế đúng bằng `0`, mà `0 > 0` là sai. Alert đứng mãi ở `Normal` ngay cả khi service đã chết.
>
> Điều nguy hiểm là **không có thông báo lỗi nào** — bạn tưởng đã có cảnh báo, thực tế thì không.
>
> | Cách viết | Kết quả |
> |---|---|
> | Query `up == 0`, điều kiện `IS ABOVE 0` | ❌ không bao giờ Firing |
> | **Query `up`, điều kiện `IS BELOW 1`** | ✅ đúng |
> | Query `count(up == 0)`, điều kiện `IS ABOVE 0` | ✅ cũng đúng, nhưng mất nhãn `instance` |
>
> Dùng cách thứ hai: nó giữ được nhãn `instance` nên tin nhắn cảnh báo nói rõ service nào chết.

## 5.5 · Kiểm chứng bằng sự cố giả lập

**Bước 1 — dừng service**

```bash
docker compose stop order-service
```

Theo dõi trên Grafana. Mốc thời gian đo được trên môi trường lab:

| Thời điểm | Trạng thái |
|---|---|
| ~45 giây | Prometheus ghi nhận `up = 0` |
| **~1 phút** | Alert chuyển sang **Pending** |
| **~3 phút** | Alert chuyển sang **Firing**, Discord nhận tin |

**Bước 2 — khôi phục service**

```bash
docker compose start order-service
```

| Thời điểm | Trạng thái |
|---|---|
| ~45 giây sau khi service lên | Alert về **Normal**, gửi thông báo khôi phục |

> 💡 **Vì sao Pending xuất hiện sau 1 phút chứ không ngay lập tức?** Vì có hai chu kỳ chồng lên nhau: Prometheus scrape mỗi **15 giây**, còn Grafana đánh giá rule mỗi **1 phút**. Service chết xong vẫn phải đợi Prometheus phát hiện, rồi đợi Grafana đánh giá. Cộng thêm Pending period 2 phút nữa mới Firing.

---

# TỔNG KẾT

| # | Nội dung |
|---|---|
| **1** | Grafana dùng Prometheus làm **Data Source** để tạo biểu đồ và dashboard, không tự lưu metrics |
| **2** | Hai container kết nối qua DNS nội bộ: `http://quickbite-prometheus:9090` |
| **3** | Dashboard ID `1860` theo dõi tài nguyên VPS; ID `4701` theo dõi JVM |
| **4** | Bộ lọc `Application` sống nhờ nhãn chung đã đặt ở Session 13 |
| **5** | Alert Rule dùng PromQL phát hiện sự cố; Contact Point quyết định nơi nhận tin |
| **6** | Pending period tránh cảnh báo giả; Resolved xác nhận hệ thống đã phục hồi |

## Ba điều nếu chỉ nhớ được ba điều

1. **Grafana chỉ vẽ, Prometheus mới giữ dữ liệu.** Mất volume Grafana là mất dashboard, không mất metrics.
2. **Container gọi nhau bằng tên, không bằng `localhost`.** Đây là lỗi số một khi thêm Data Source.
3. **Một alert không kêu thì vô dụng hơn là không có alert.** Luôn kiểm chứng bằng sự cố giả lập trước khi tin vào nó.

# Bảng tra nhanh

| Việc | Cách làm |
|---|---|
| Mở Grafana | `http://localhost:3000` (hoặc cổng bạn đã đổi) |
| Thêm Data Source | Connections → Data sources → Add → Prometheus |
| Thử truy vấn | Explore → chọn Prometheus → chuyển sang Code |
| Import dashboard | Dashboards → New → Import → nhập ID |
| Tạo cảnh báo | Alerting → Alert rules → New alert rule |
| Xem trạng thái alert | Alerting → Alert rules |

# Từ khoá cần phân biệt

| Cặp khái niệm | Khác nhau ở |
|---|---|
| Prometheus / Grafana | Một bên **thu thập và lưu**, một bên **truy vấn và vẽ** |
| Data Source / Dashboard | Một bên là **kết nối tới dữ liệu**, một bên là **cách bày dữ liệu ra** |
| Pending / Firing | Lỗi **vừa xuất hiện** / lỗi **đã kéo dài đủ lâu** |
| Alert Rule / Contact Point | **Khi nào** báo / báo **đi đâu** |
| `rate()` / `irate()` | Trung bình cả khoảng / tốc độ **tức thời** |
