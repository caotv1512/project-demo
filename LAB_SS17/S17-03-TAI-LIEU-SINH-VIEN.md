# Session 17 — Logging tập trung với EFK Stack

> Tài liệu này giải thích khái niệm. Phần thao tác nằm ở file `S17-02-LAB.md`.

## Nội dung

| Phần | Chủ đề |
|---|---|
| 1 | Logging tập trung trong microservices và tổng quan EFK |
| 2 | Triển khai EFK Stack bằng Docker Compose |
| 3 | Gửi log từ Spring Boot đến Fluentd |
| 4 | Phân tích và debug log trong Kibana bằng `trace.id` |

---

# PHẦN 1 — LOGGING TẬP TRUNG VÀ TỔNG QUAN EFK

## 1.1 · Ba điểm nghẽn của cách đọc log thủ công

Buổi 16 đọc log bằng `docker compose logs` trên từng container. Cách đó đủ dùng cho một hệ thống năm service trên một máy, nhưng bộc lộ ba điểm nghẽn ngay khi sự cố đi qua nhiều service.

| Điểm nghẽn | Biểu hiện cụ thể trong QuickBite |
|---|---|
| Dữ liệu rời rạc | Một đơn hàng thất bại cần đọc log của bốn container: `order`, `user`, `restaurant`, `notification` |
| Khó tìm kiếm và lọc | Không có cách lọc đồng thời theo mốc thời gian, theo level và theo tên service trong cùng một lệnh |
| Phân mảnh chuỗi sự kiện | Các dòng log thuộc cùng một request nằm rải ở bốn luồng khác nhau, phải ghép bằng mắt theo mốc thời gian |

Buổi 16 đã chạm đúng vào giới hạn này: tên thread chỉ nối được các dòng log **trong cùng một service**, vì mỗi service có không gian tên thread riêng. Hai dòng `nio-8083-exec-5` và `nio-8081-exec-2` có thể thuộc cùng một đơn hàng, nhưng không có gì trong chính dòng log nói ra điều đó.

## 1.2 · Docker logs rời rạc và EFK tập trung

| Tiêu chí | `docker compose logs` | EFK tập trung |
|---|---|---|
| Cách tiếp cận | Đọc từng container riêng biệt | Tìm kiếm và truy vấn trên toàn hệ thống |
| Truy vết sự cố | Ghép mốc thời gian thủ công | Lọc chính xác theo `trace.id` |
| Lưu trữ | Log mất khi container bị dựng lại | Index nằm trong persistent volume |
| Giao diện | Terminal | Kibana Discover với truy vấn KQL |
| Thống kê | Khó tổng hợp số lượng lỗi | Lọc và đếm theo `service.name`, `log.level` |

Logging tập trung **không thay thế việc ghi log tốt**. Một service không ghi log thì sau khi gắn EFK vẫn không có gì để đọc. EFK chỉ thu gom và khai thác những dòng log mà ứng dụng đã viết ra.

## 1.3 · Vai trò của năm thành phần

| Thành phần | Vai trò trong QuickBite |
|---|---|
| Spring Boot | Sinh JSON log chuẩn ECS ra `stdout` |
| Docker logging driver | Bắt `stdout`/`stderr` và chuyển log tới collector |
| Fluentd | Nhận, parse, bổ sung metadata, buffer và chuyển tiếp |
| Elasticsearch | Lưu trữ, lập chỉ mục và thực hiện truy vấn |
| Kibana | Cung cấp Discover, KQL và giao diện phân tích |

Ứng dụng **không gửi log trực tiếp tới Elasticsearch**. Giữa hai đầu có hai tầng trung gian: logging driver của Docker và collector Fluentd.

## 1.4 · Luồng dữ liệu năm tầng

```
1. Spring Boot        in JSON ra stdout
        ↓
2. Docker daemon      logging driver fluentd  →  127.0.0.1:24224
        ↓
3. Fluentd            parse JSON, giữ metadata, buffer xuống đĩa
        ↓
4. Elasticsearch      index quickbite-YYYY.MM.DD
        ↓
5. Kibana Discover    Time Range, KQL, lọc theo trace.id
```

Mỗi tầng làm đúng một việc và vận hành độc lập. Elasticsearch sập thì Fluentd vẫn nhận log và giữ trong buffer; Fluentd sập thì ứng dụng vẫn chạy nhờ tuỳ chọn `fluentd-async`.

## 1.5 · Hai đường kết nối mạng khác nhau

Đây là chỗ nhầm phổ biến nhất khi cấu hình EFK.

| Nguồn kết nối | Địa chỉ đích | Lý do |
|---|---|---|
| Docker logging driver | `127.0.0.1:24224` | Tiến trình `dockerd` nằm ngoài network namespace của container, không phân giải được tên service |
| Container Fluentd | `elasticsearch:9200` | Hai container cùng mạng, dùng Docker DNS |
| Container Kibana | `elasticsearch:9200` | Cùng mạng nội bộ với Elasticsearch |

> ⚠️ Không dùng `fluentd:24224` làm `fluentd-address`. Giá trị đó là tên container, chỉ phân giải được **bên trong** mạng Docker, còn `dockerd` thì ở ngoài.

## 1.6 · Một log event biến đổi qua bốn bước

**Bước 1 — Spring Boot tạo JSON**

```
{"@timestamp":"2026-11-04T01:11:45.513Z","log.level":"INFO",
 "message":"[BUOC 2] Tao don #42 PENDING","service.name":"order-service",
 "trace.id":"trace-json-check"}
```

**Bước 2 — Docker bọc JSON đó vào một JSON khác**

```
{"container_name":"/quickbite5-order","source":"stdout",
 "log":"{\"@timestamp\":\"...\",\"service.name\":\"order-service\",...}"}
```

Toàn bộ JSON của ứng dụng bị biến thành **một chuỗi** nằm trong trường `log`.

**Bước 3 — Fluentd parse trường `log`**

Các thuộc tính bên trong chuỗi được bóc ra thành field độc lập: `service.name`, `trace.id`, `log.level`, `message`.

**Bước 4 — Elasticsearch lập chỉ mục**

Mỗi field được index riêng. Kibana lọc trực tiếp theo field thay vì tìm toàn văn, nên truy vấn nhanh và chính xác.

Bỏ bước 3 thì Elasticsearch chỉ nhận được một trường `log` dạng text dài. Mọi truy vấn theo `trace.id` hoặc `log.level` sẽ không hoạt động.

## 1.7 · Ba cổng chỉ mở trên loopback

| Cổng | Thành phần | Bind trong bài lab |
|---|---|---|
| 24224 | Fluentd forward input | `127.0.0.1:24224` |
| 9200 | Elasticsearch REST API | `127.0.0.1:9200` |
| 5601 | Kibana Web UI | `127.0.0.1:5601` |

Cấu hình `xpack.security.enabled=false` tắt toàn bộ xác thực. Bất kỳ ai gọi được cổng 9200 đều đọc và xoá được dữ liệu. Cấu hình này chỉ dùng cho lab một node đã cô lập; môi trường thật cần xác thực và TLS.

---

# PHẦN 2 — TRIỂN KHAI EFK STACK BẰNG DOCKER COMPOSE

## 2.1 · Tách EFK thành một compose project độc lập

```
quickbite-demo/
├── session-05/stack/docker-compose.yml     ← 4 microservices + gateway
├── LAB_SS13/monitoring/                    ← Prometheus
├── LAB_SS14/grafana/                       ← Grafana
└── LAB_SS17/efk/
    ├── docker-compose.yml                  ← Elasticsearch, Kibana, Fluentd
    └── fluentd/
        ├── Dockerfile
        └── fluent.conf
```

| Lợi ích | Nội dung |
|---|---|
| Tách vòng đời triển khai | Microservices và hạ tầng log có tần suất cập nhật khác nhau |
| Nối bằng external network | Hai project dùng chung mạng `quickbite5-net` |
| Bảo trì không gián đoạn | Khởi động lại EFK không chạm vào service nghiệp vụ |

## 2.2 · Tham số kernel `vm.max_map_count`

Elasticsearch 8.x dùng rất nhiều memory-mapped file. Giới hạn mặc định của Linux quá thấp làm tiến trình chết khi khởi động.

Trên **Linux host** (VPS Ubuntu):

```
echo 'vm.max_map_count=262144' | sudo tee /etc/sysctl.d/99-elasticsearch.conf
sudo sysctl --system
```

Đây là cấu hình của hệ điều hành host, không đổi được từ bên trong container.

Trên **macOS và Windows**, Docker Desktop chạy một máy ảo Linux riêng và máy ảo đó đã đặt sẵn `vm.max_map_count = 262144`. Không cần làm gì thêm.

## 2.3 · Khoá phiên bản và lưu dữ liệu bền vững

| Thành phần | Phiên bản |
|---|---|
| Elasticsearch | 8.15.0 |
| Kibana | 8.15.0 |
| Fluentd | 1.19.3 |

Elasticsearch và Kibana **phải cùng phiên bản**. Kibana kiểm tra phiên bản của Elasticsearch khi khởi động và từ chối kết nối nếu lệch.

| Named volume | Mount point | Dữ liệu được bảo vệ |
|---|---|---|
| `elasticsearch-data` | `/usr/share/elasticsearch/data` | Index và document log |
| `fluentd-buffer` | `/fluentd/buffer` | Chunk đang chờ gửi tới Elasticsearch |

## 2.4 · Custom Fluentd image

Image Fluentd gốc không có plugin Elasticsearch, nên phải tự build.

```
FROM fluent/fluentd:v1.19.3-debian-2.2
USER root
RUN gem install elasticsearch --no-document --version 8.19.0 \
 && gem install fluent-plugin-elasticsearch --no-document --version 5.4.3 \
 && mkdir -p /fluentd/buffer \
 && chown -R fluent:fluent /fluentd
USER fluent
```

| Chi tiết | Lý do |
|---|---|
| Base Debian | Có sẵn jemalloc, quản lý bộ nhớ tốt hơn cho tiến trình chạy dài |
| Khoá phiên bản gem | Build lại sau này ra đúng kết quả cũ |
| Client Ruby major 8 | Tương thích với Elasticsearch 8.x |
| `USER fluent` ở cuối | Tiến trình không chạy bằng `root` |

## 2.5 · Ba khối của `fluent.conf`

```
<source>                      ← nhận log
  @type forward
  port 24224
  bind 0.0.0.0
</source>

<filter quickbite.**>         ← parse chuỗi JSON
  @type parser
  key_name log
  reserve_data true
  <parse>
    @type json
  </parse>
</filter>

<match quickbite.**>          ← ghi sang Elasticsearch
  @type elasticsearch
  host elasticsearch
  port 9200
  logstash_format true
  logstash_prefix quickbite
</match>
```

| Tham số | Ý nghĩa |
|---|---|
| `@type forward` | Giao thức mà Docker logging driver dùng để gửi event |
| `bind 0.0.0.0` | Lắng nghe trên mọi interface **bên trong container**; cổng vẫn chỉ publish ra loopback của host |
| `key_name log` | Chỉ rõ trường chứa chuỗi JSON cần giải mã |
| `reserve_data true` | Giữ lại metadata gốc của Docker sau khi parse |
| `logstash_prefix quickbite` | Index có dạng `quickbite-YYYY.MM.DD` |

Cấu hình thật cần thêm hai thứ mà slide không nhắc tới:

| Bổ sung | Lý do |
|---|---|
| `remove_key_name_field true` trong khối `<filter>` | Bỏ trường `log` gốc sau khi parse. Giữ lại thì `log` vừa là chuỗi vừa là object `log.level`, và Elasticsearch từ chối mọi document |
| Một khối `<filter @type record_transformer>` thứ hai | Dọn trường `log` của những dòng **không phải JSON**, ví dụ banner khởi động của Spring Boot mà parser không đọc được |

## 2.6 · File buffer chống mất log

```
<buffer>
  @type file
  path /fluentd/buffer/quickbite
  flush_mode interval
  flush_interval 5s
  retry_forever true
  chunk_limit_size 8m
  total_limit_size 512m
</buffer>
```

| Tình huống | Hành vi của Fluentd |
|---|---|
| Elasticsearch gián đoạn | Ghi chunk xuống `/fluentd/buffer`, thử lại liên tục |
| Elasticsearch phục hồi | Đẩy toàn bộ chunk đã đệm sang, theo đúng thứ tự |
| Buffer đầy 512 MB | Bắt đầu mất log — cần giám sát dung lượng đĩa |

`flush_interval 5s` giải thích tại sao log vừa sinh ra chưa xuất hiện ngay trong Kibana: mỗi lô được gom tối đa năm giây trước khi gửi.

## 2.7 · Thứ tự khởi động

`depends_on` với `condition: service_healthy` buộc Kibana và Fluentd chỉ khởi động sau khi Elasticsearch đã trả lời healthcheck. Thiếu điều kiện này, cả hai sẽ khởi động trước và báo lỗi kết nối.

Trạng thái cluster `yellow` là **bình thường** với lab một node: Elasticsearch không tìm được node thứ hai để đặt replica. Chỉ `red` mới là dấu hiệu dữ liệu không đọc được.

## 2.8 · Truy cập Kibana qua SSH tunnel

Khi EFK chạy trên VPS, cổng 5601 chỉ bind trên loopback của VPS nên trình duyệt ở máy cá nhân không gọi tới được. SSH tunnel mở đường đi mà không cần mở cổng ra internet.

```
ssh -N -L 5601:127.0.0.1:5601 deployer@VPS_PUBLIC_IP
```

| Tham số | Ý nghĩa |
|---|---|
| `-L 5601:127.0.0.1:5601` | Chuyển cổng 5601 của máy cá nhân tới `127.0.0.1:5601` trên VPS |
| `-N` | Chỉ mở tunnel, không mở shell |

Khi EFK chạy ngay trên máy cá nhân thì không cần tunnel: `127.0.0.1:5601` đã là máy mình.

---

# PHẦN 3 — GỬI LOG TỪ SPRING BOOT ĐẾN FLUENTD

## 3.1 · Docker bọc console log thành JSON

Mỗi dòng ứng dụng in ra `stdout` được Docker đóng gói lại:

```
{
  "container_id":   "9a8b7c6d5e...",
  "container_name": "/quickbite5-order",
  "source":         "stdout",
  "log":            "{\"service.name\":\"order-service\",...}"
}
```

JSON của Spring Boot không mất đi, nhưng nằm **dưới dạng chuỗi** trong trường `log`. Vì vậy Fluentd buộc phải parse trước khi gửi sang Elasticsearch.

## 3.2 · Cấu hình logging driver

```
logging:
  driver: fluentd
  options:
    fluentd-address: "127.0.0.1:24224"
    fluentd-async: "true"
    tag: "quickbite.order"
```

| Tuỳ chọn | Ý nghĩa |
|---|---|
| `fluentd-address` | Địa chỉ collector **nhìn từ Docker daemon** |
| `fluentd-async` | Kết nối nền; collector chưa sẵn sàng thì container vẫn khởi động được |
| `tag` | Nhãn định tuyến event qua `<filter>` và `<match>` |

Mọi giá trị trong `options` nên viết dưới dạng chuỗi, kể cả `"true"`.

### Điều gì xảy ra với `docker logs` sau khi đổi driver

Từ Docker Engine 20.10, tính năng **dual logging** được bật mặc định: khi driver chính không hỗ trợ đọc lại, Docker vẫn giữ một bản sao cục bộ để `docker logs` hoạt động. Vì vậy sau khi đổi sang driver `fluentd`, lệnh `docker compose logs order-service` **vẫn in ra log** — nhưng in ra JSON thô, và từ một bản sao chứ không phải nguồn dữ liệu chính.

| Thứ | Vai trò sau khi gắn EFK |
|---|---|
| `docker compose logs` | Bản sao cục bộ của Docker; mất khi container bị dựng lại |
| Index `quickbite-*` | Nguồn dữ liệu chính; nằm trong persistent volume, truy vấn được theo field |

Trên một số cấu hình Docker có dual logging bị tắt, cùng lệnh đó trả về lỗi `configured logging driver does not support reading`. Không nên dựa vào `docker logs` sau khi đã chuyển sang logging tập trung.

## 3.3 · Chuẩn hoá tag cho bốn service

| Compose service | Container | Fluentd tag |
|---|---|---|
| `order-service` | `quickbite5-order` | `quickbite.order` |
| `user-service` | `quickbite5-user` | `quickbite.user` |
| `restaurant-service` | `quickbite5-restaurant` | `quickbite.restaurant` |
| `notification-service` | `quickbite5-notification` | `quickbite.notification` |

Pattern `quickbite.**` trong `<filter>` và `<match>` khớp mọi tag bắt đầu bằng `quickbite.`, nên thêm service mới không phải sửa `fluent.conf`.

Tag dùng để **định tuyến trong Fluentd**. Tên service dùng để **truy vấn trong Kibana** và nằm ở field `service.name`. Hai thứ độc lập nhau.

## 3.4 · `reserve_data true` giữ lại metadata

**Trước parser**

```
{"container_name":"/quickbite5-order","source":"stdout",
 "log":"{\"service.name\":\"order-service\",\"trace.id\":\"req-001\"}"}
```

**Sau parser, có `reserve_data true`**

```
{"container_name":"/quickbite5-order","source":"stdout",
 "service.name":"order-service","trace.id":"req-001"}
```

Bỏ `reserve_data true` thì `container_name` và `source` bị loại khỏi kết quả. Mất hai field đó là mất khả năng trả lời câu hỏi "container nào in dòng này", vốn là thông tin cần cho việc điều tra ở tầng hạ tầng.

## 3.5 · Spring Boot không phụ thuộc EFK

```
Mã Java → SLF4J → Logback (ECS encoder) → stdout → Docker driver → Fluentd → Elasticsearch → Kibana
                   └──────── trong ứng dụng ────────┘ └──────────── hạ tầng ────────────┘
```

Những thứ ứng dụng **không cần có**:

| Không cần | Lý do |
|---|---|
| SDK Fluentd | Ứng dụng chỉ in ra `stdout` |
| Endpoint Elasticsearch | Không có IP hay URL Elasticsearch nào trong `application.yml` |
| Logic buffer và retry | Fluentd đảm nhiệm bằng file buffer |

Việc duy nhất ứng dụng phải làm là in log **đúng định dạng JSON**. Trong QuickBite, việc đó do `logback-spring.xml` và thư viện `logback-ecs-encoder` lo.

### Hai định dạng cho hai môi trường

| Môi trường | Profile | Định dạng | Người đọc |
|---|---|---|---|
| Development | không bật profile nào | Dòng text có màu, căn cột | Lập trình viên đọc trực tiếp trên terminal |
| Production | `SPRING_PROFILES_ACTIVE=json` | JSON chuẩn ECS một dòng | Máy đọc: Fluentd parse, Elasticsearch index |

Đây chính là nội dung "khác biệt logging giữa Development và Production" của buổi 16, nhưng ở dạng cấu hình chạy được chứ không còn là nguyên tắc.

### `trace.id` đi từ đâu ra

Một dòng log chỉ có `trace.id` khi ứng dụng đặt giá trị đó vào **MDC** (Mapped Diagnostic Context) — một vùng dữ liệu gắn với thread đang xử lý request. Logback đọc MDC và in ra thành field.

| Thành phần | Nhiệm vụ |
|---|---|
| `TraceIdFilter` | Đọc header `X-Trace-Id` của request; không có thì tự sinh. Đặt vào MDC dưới khoá `trace.id` |
| `FeignTraceConfig` | Gắn lại header `X-Trace-Id` vào mọi lời gọi Feign sang service khác |
| `EcsEncoder` | In toàn bộ MDC ra thành field trong JSON |

Thiếu `FeignTraceConfig`, mỗi service sẽ tự sinh một `trace.id` riêng và Kibana không nối được chuỗi log thành một hành trình.

## 3.6 · Phải tái tạo container để đổi logging driver

```
docker compose up -d --force-recreate
```

| Câu hỏi | Trả lời |
|---|---|
| Vì sao `restart` không đủ? | `restart` chỉ khởi động lại container cũ, giữ nguyên cấu hình đã tạo |
| Cấu hình nằm ở đâu? | `HostConfig.LogConfig`, gắn cố định vào container **tại thời điểm create** |
| Kiểm tra bằng gì? | `docker inspect --format '{{.HostConfig.LogConfig.Type}}' <container>` |

## 3.7 · Chẩn đoán lỗi theo từng chặng

| Hiện tượng | Điểm cần kiểm tra |
|---|---|
| Container không khởi động được | Fluentd đã chạy chưa, `fluentd-address` đúng chưa, có `fluentd-async` chưa |
| Fluentd không nhận event | Tag và cổng `127.0.0.1:24224` |
| Fluentd nhận nhưng không có index | Khối `<match>`, sức khoẻ Elasticsearch, buffer và retry |
| Chỉ có một trường `log` dạng text | Parser chưa chạy hoặc tag không khớp `quickbite.**` |
| Mất metadata container | Thiếu `reserve_data true` |

Thứ tự điều tra luôn đi theo chiều của pipeline: ứng dụng → Docker driver → Fluentd → Elasticsearch → Kibana.

---

# PHẦN 4 — PHÂN TÍCH VÀ DEBUG LOG TRONG KIBANA

## 4.1 · Data view

Kibana không đọc index trực tiếp. Phải khai báo một **data view** trỏ tới nhóm index cần xem.

| Thông số | Giá trị |
|---|---|
| Name | `quickbite-logs` |
| Index pattern | `quickbite-*` |
| Timestamp field | `@timestamp` |

Index pattern có dấu `*` để bao trọn mọi ngày: `quickbite-2026.11.04`, `quickbite-2026.11.05`. Trường `@timestamp` cho phép Kibana lọc theo Time Range và vẽ biểu đồ phân bố log theo thời gian.

## 4.2 · Sáu cột cần có trong Discover

| Cột | Câu hỏi nó trả lời |
|---|---|
| `@timestamp` | Sự kiện xảy ra khi nào |
| `service.name` | Service nào tạo log |
| `log.level` | Mức độ nghiêm trọng |
| `message` | Sự kiện nghiệp vụ nào xảy ra |
| `trace.id` | Dòng log thuộc request nào |
| `error.type` | Exception thuộc loại nào |

Thu hẹp Time Range trước khi truy vấn để giảm lượng dữ liệu phải quét.

## 4.3 · KQL cho các tình huống điều tra

| Mục đích | Cú pháp KQL |
|---|---|
| Mọi lỗi trong khoảng thời gian | `log.level : "ERROR"` |
| Lỗi gọi liên service | `error.type : "feign.FeignException*"` |
| Cảnh báo của một service, bỏ nhiễu | `service.name : "restaurant-service" and (log.level : "ERROR" or log.level : "WARN")` |
| Toàn bộ log của một request | `trace.id : "trace-demo-001"` |

Các toán tử `and`, `or`, `not` và ký tự đại diện `*` kết hợp được với nhau. Giá trị có dấu cách hoặc dấu chấm phải đặt trong dấu ngoặc kép.

## 4.4 · Sáu bước debug phân tán

| Bước | Việc làm |
|---|---|
| 1 | Thu hẹp Time Range quanh thời điểm xảy ra lỗi |
| 2 | Tìm log `ERROR` hoặc `WARN` của `order-service` |
| 3 | Mở document, sao chép `trace.id` |
| 4 | Truy vấn lại toàn hệ thống bằng `trace.id` đó |
| 5 | Sắp xếp `@timestamp` từ cũ đến mới |
| 6 | Tìm `WARN`/`ERROR` **đầu tiên** — đó là nơi luồng bị đứt |

> Log `ERROR` cuối cùng thường chỉ là hậu quả. Nguyên nhân gốc nằm ở service phụ thuộc đã lỗi trước đó.

## 4.5 · Hành trình một request qua bốn service

Truy vấn `trace.id : "trace-demo-001"`, sắp xếp cũ đến mới:

| Thứ tự | Service | Việc đang làm |
|---|---|---|
| 1 | `order-service` | Tiếp nhận đơn, tạo bản ghi `PENDING` |
| 2 | `restaurant-service` | Kiểm tra nhà hàng và món |
| 3 | `user-service` | Trừ số dư ví |
| 4 | `notification-service` | Gửi thông báo trạng thái |
| 5 | `order-service` | Hoàn tất đơn hoặc ghi nhận thất bại |

## 4.6 · Phân loại sự cố từ chuỗi log

| Nhóm sự cố | Dấu hiệu | Hướng xử lý |
|---|---|---|
| Nghiệp vụ có kiểm soát | `WARN`, nhà hàng đóng cửa hoặc ví không đủ tiền | Kiểm tra rule nghiệp vụ và mã lỗi 4xx |
| Service phụ thuộc | `FeignException`, timeout | Kiểm tra health và mạng của service đích |
| Hạ tầng | `SQLException`, lỗi transaction | Kiểm tra database, CPU, RAM, connection pool |
| Lỗi logic | `NullPointerException` | Đọc stack trace và sửa mã nguồn |

## 4.7 · Khi Kibana không có kết quả

| Thứ tự kiểm tra | Việc làm |
|---|---|
| 1 | Mở rộng Time Range — mặc định chỉ 15 phút gần nhất |
| 2 | Kiểm tra index có tồn tại: `curl '127.0.0.1:9200/_cat/indices/quickbite-*?v'` |
| 3 | Kiểm tra đúng tên field `trace.id`, không phải `traceId` hay `trace_id` |
| 4 | Chờ đủ `flush_interval` 5 giây của Fluentd buffer |

---

# TỔNG KẾT

| Điều cần nhớ | Nội dung |
|---|---|
| EFK không thay ghi log tốt | Service im lặng thì sau khi gắn EFK vẫn không có gì để đọc |
| Hai đường mạng khác nhau | `dockerd` dùng `127.0.0.1:24224`; container dùng Docker DNS |
| Parser là mắt xích bắt buộc | Thiếu nó, Elasticsearch chỉ nhận một trường text và mọi truy vấn theo field đều vô dụng |
| Driver gắn lúc create | Đổi driver phải `up -d --force-recreate`, `restart` không có tác dụng |
| Đánh đổi của driver `fluentd` | `docker compose logs` của service đó không in ra gì nữa |
| `trace.id` là thứ nối chuỗi | Tên thread chỉ nối được trong một service; `trace.id` nối được qua nhiều service |
| Lỗi đầu tiên theo thời gian | Lỗi cuối cùng thường chỉ là hậu quả |
