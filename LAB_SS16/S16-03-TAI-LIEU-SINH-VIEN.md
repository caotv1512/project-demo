# Session 16 — Logging trong Spring Boot môi trường Production

> Buổi học này trả lời một câu hỏi duy nhất: **khi hệ thống trên Production gặp sự cố, đọc log thế nào để tìm ra nguyên nhân?**
>
> Hệ thống dùng làm ví dụ là QuickBite ở `session-05`: năm service chạy trong năm container riêng biệt.

## Nội dung

| Phần | Chủ đề |
|---|---|
| 1 | Khác biệt logging giữa Development và Production |
| 2 | Log level và quy ước ghi log backend |

---

# PHẦN 1 — KHÁC BIỆT LOGGING GIỮA DEVELOPMENT VÀ PRODUCTION

## 1.1 · Log local không phản ánh sự cố trên Production

Khi lập trình trên máy cá nhân, một request đi từ đầu đến cuối trong **một tiến trình**. Toàn bộ log hiện ra trong một cửa sổ terminal, theo đúng thứ tự thời gian.

Trên Production thì khác. Một request đặt món của QuickBite đi qua **bốn container độc lập**:

```
api-gateway  ->  order-service  ->  restaurant-service
                      |
                      +---------->  user-service
                      |
                      +---------->  notification-service
```

Mỗi container ghi log vào luồng riêng của nó. Không có cửa sổ nào thấy được cả chuỗi.

### Ba thách thức khi truy vết sự cố

| Thách thức | Câu hỏi phải trả lời |
|---|---|
| **1. Xác định service chịu trách nhiệm** | Service nào đã xử lý và gây ra lỗi? |
| **2. Định vị vị trí lỗi** | Lỗi xuất hiện ở bước nào trong chuỗi request? |
| **3. Trạng thái container** | Container có đang bị restart liên tục không? |

> **Vấn đề vận hành.** Log phân tán trên từng container riêng biệt khiến việc truy vết lỗi thủ công trở nên rất khó. Hệ thống cần giải pháp tập trung hoá metrics và log để giám sát toàn diện.

## 1.2 · Development và Production có mục tiêu logging khác nhau

| Tiêu chí | Development | Production |
|---|---|---|
| **Mục đích** | Debug nhanh một service | Vận hành và điều tra toàn hệ thống |
| **Nơi chạy** | IDE hoặc terminal local | Nhiều container trên VPS |
| **Định dạng** | Text dễ đọc bằng mắt | JSON ổn định, dễ xử lý tự động |
| **Log level** | Có thể bật `DEBUG`, `TRACE` | Thường giữ `INFO` trở lên |
| **Dữ liệu** | Dữ liệu kiểm thử | Dữ liệu thật, yêu cầu bảo mật |
| **Vòng đời** | Tạm thời | Cần thu thập và quản lý tập trung |

## 1.3 · Ba lý do không được sao chép cấu hình logging từ Development lên Production

| Lý do | Nội dung |
|---|---|
| **Hiệu năng** | Log quá chi tiết (`DEBUG`/`TRACE`) ở Production tốn tài nguyên đĩa cứng và CPU |
| **Bảo mật** | Tránh rò rỉ thông tin nhạy cảm (token, password, PII) ra file log tập trung |
| **Phân tích** | Cần định dạng JSON để các hệ thống Log Aggregator (Elasticsearch, Loki) parse dễ dàng |

Con số đo thật trên QuickBite, cùng một thao tác đặt món:

| Log level | Số dòng log sinh ra cho **một** request |
|---|---|
| `INFO` | 4 dòng |
| `DEBUG` | 13 dòng |

Gấp 3,25 lần. Với hệ thống nhận 100 request mỗi giây, đó là khác biệt giữa 400 và 1.300 dòng log mỗi giây.

## 1.4 · Luồng log trong môi trường container

```
[1] Ứng dụng Spring Boot          ->  SLF4J / Logback tạo và định dạng nội dung log
          |
          v  stdout / stderr
[2] Docker logging driver         ->  thu nhận toàn bộ luồng xuất chuẩn của container
          |
          v
[3] Hệ thống log tập trung        ->  lưu trữ, lập chỉ mục, phục vụ truy vấn dài hạn
```

| Giai đoạn | Việc được làm |
|---|---|
| **01. Tạo và cấu trúc log** | Ứng dụng chủ động tạo nội dung, định dạng và định nghĩa cấu trúc log ban đầu qua SLF4J/Logback |
| **02. Thu nhận từ container** | Docker logging driver thu nhận toàn bộ luồng `stdout` và `stderr` của container |
| **03. Quản lý tập trung** | Hệ thống log tập trung lưu trữ, lập chỉ mục và phục vụ truy vấn dài hạn |

Điểm quan trọng: ứng dụng **không ghi log vào file**. Nó ghi ra `stdout`. Docker mới là thành phần quyết định log đi đâu.

## 1.5 · Xác định đúng service trước khi đọc log

Trong Docker Compose có hai loại tên khác nhau, rất dễ nhầm:

| Loại tên | Ví dụ trong QuickBite | Dùng ở đâu |
|---|---|---|
| **Service name** | `order-service` | Lệnh `docker compose logs` |
| **Container name** | `quickbite5-order` | Lệnh `docker logs`, `docker exec` |

Năm service của QuickBite:

| Vai trò | Service name | Container name |
|---|---|---|
| Cửa ngõ vào | `api-gateway` | `quickbite5-gateway` |
| Đặt món | `order-service` | `quickbite5-order` |
| Nhà hàng | `restaurant-service` | `quickbite5-restaurant` |
| Người dùng | `user-service` | `quickbite5-user` |
| Thông báo | `notification-service` | `quickbite5-notification` |

> **Nguyên tắc truy vấn log.** Luôn dùng chính xác service name được định nghĩa trong file Compose. Không đoán, không dùng tên container do Compose tự sinh ra.

## 1.6 · Các lệnh xem log cần dùng thường xuyên

| Lệnh | Việc nó làm |
|---|---|
| `docker compose logs --tail 50 order-service` | Xem 50 dòng gần nhất |
| `docker compose logs -t --since 10m order-service` | Xem log trong 10 phút gần nhất, kèm mốc thời gian |
| `docker compose logs -f order-service` | Theo dõi log mới theo thời gian thực |
| `docker compose logs -f order-service user-service` | Theo dõi hai service trong cùng luồng nghiệp vụ |

### Giải thích từng tham số

| Tham số | Ý nghĩa |
|---|---|
| `--tail N` | Chỉ xem `N` dòng cuối, tiết kiệm thời gian tải và không gian màn hình |
| `-t` | Hiển thị mốc thời gian (timestamp) của Docker ở đầu mỗi dòng |
| `--since 10m` | Lọc log theo khoảng thời gian gần đây |
| `-f` | Theo dõi liên tục, dòng mới hiện ra ngay khi phát sinh |
| Nhiều service | Gộp log của nhiều service vào cùng một luồng để dễ truy vết |

> **Thao tác terminal.** Nhấn `Ctrl + C` chỉ dừng việc theo dõi log trên terminal. Nó không làm dừng hay ảnh hưởng đến trạng thái hoạt động của container.

## 1.7 · Quy trình năm bước khoanh vùng sự cố

| Bước | Việc làm | Lệnh |
|---|---|---|
| **01** | Kiểm tra trạng thái container — tìm container `exited`, `restarting` hoặc không `healthy` | `docker compose ps -a` |
| **02** | Xác định mốc thời gian cụ thể người dùng gặp sự cố | — |
| **03** | Lọc log gần thời điểm xảy ra lỗi | `docker compose logs -t --since 10m` |
| **04** | Truy vết luồng service: bắt đầu từ service chính rồi mở rộng sang service phụ thuộc | `docker compose logs -f order-service user-service` |
| **05** | Phân tích loại lỗi: đối chiếu lỗi nghiệp vụ `4xx` với lỗi hệ thống `5xx` và stacktrace | `grep -E 'ERROR|Exception'` |

> **Tối ưu truy vấn log.** Không đọc toàn bộ lịch sử log khi đã biết khung thời gian xảy ra sự cố. Đọc đúng khoảng thời gian giúp giảm tải cho terminal và tìm ra nguyên nhân nhanh hơn.

## 1.8 · Log Production không được chứa bí mật

| 🚫 Không được ghi | ✅ Có thể ghi khi điều tra |
|---|---|
| Password, PIN, CVV | `orderId` |
| JWT access token / refresh token | `userId` / `customerId` |
| API key, secret key | `restaurantId` |
| Header `Authorization` | Mã lỗi / `reason` đã chuẩn hoá |
| Toàn bộ request/response body | Thời gian xử lý request |

### Ví dụ đối chiếu

Không an toàn:

```
Login request: password=Rikkei@123, token=eyJhbGciOiJIUzI1Ni...
```

An toàn:

```
Login failed: userId=USR-1024, reason=INVALID_CREDENTIALS
```

Dòng thứ hai vẫn đủ để điều tra: biết ai đăng nhập thất bại và thất bại vì lý do gì. Nhưng nó không để lại mật khẩu hay token trong hệ thống log tập trung — nơi có thể có hàng chục người truy cập được.

> **Bảo mật thông tin log.** Không ghi thông tin nhạy cảm vào log Production. Chỉ lưu vết các định danh không nhạy cảm và mã lỗi đã chuẩn hoá.

---

# PHẦN 2 — LOG LEVEL VÀ QUY ƯỚC GHI LOG BACKEND

## 2.1 · Năm mức log và ý nghĩa sử dụng

Thứ tự từ chi tiết nhất đến nghiêm trọng nhất:

| Level | Mục đích |
|---|---|
| `TRACE` | Theo dõi từng bước rất nhỏ của thuật toán |
| `DEBUG` | Chẩn đoán kỹ thuật trong thời gian có kiểm soát |
| `INFO` | Ghi nhận mốc nghiệp vụ hoặc vận hành bình thường |
| `WARN` | Bất thường nhưng ứng dụng đã có cách xử lý |
| `ERROR` | Lỗi kỹ thuật khiến thao tác thất bại hoặc bị gián đoạn |

Cài đặt một ngưỡng nghĩa là **ghi mức đó và mọi mức nghiêm trọng hơn**. Đặt ngưỡng `INFO` thì `INFO`, `WARN`, `ERROR` được ghi; `DEBUG` và `TRACE` bị bỏ.

## 2.2 · Quy tắc Production: ngưỡng mặc định là INFO

| Lý do | Nội dung |
|---|---|
| **Lọc bỏ nhiễu** | Bỏ `TRACE` và `DEBUG` giúp tập trung vào thông tin vận hành quan trọng |
| **Tối ưu hiệu năng** | Giảm tải I/O đĩa cứng, dung lượng lưu trữ và chi phí mạng cho Log Aggregator |
| **Linh hoạt khi sự cố** | Chỉ bật debug level **tạm thời** khi cần điều tra một lỗi cụ thể, rồi tắt ngay |

## 2.3 · Cấu trúc một dòng log Spring Boot

Một dòng log thật của QuickBite:

```
2026-11-02T06:48:06.826Z  INFO 1 --- [order-service] [nio-8083-exec-5] com.quickbite.order.OrderController : [BUOC 2] Tao don #4 PENDING - Pho Thin / Pho bo tai lan / 75000d
```

Tách thành bảy phần:

| Phần | Giá trị | Ý nghĩa |
|---|---|---|
| Thời điểm | `2026-11-02T06:48:06.826Z` | Múi giờ UTC — dùng để khớp log giữa các service |
| Level | `INFO` | Mức log |
| PID | `1` | Process ID trong container; trong Docker hầu như luôn là `1` |
| Tên ứng dụng | `[order-service]` | Lấy từ `spring.application.name` |
| Thread | `[nio-8083-exec-5]` | Luồng xử lý — cùng một thread nghĩa là cùng một request |
| Logger | `com.quickbite.order.OrderController` | Class đã ghi dòng log này |
| Nội dung | `[BUOC 2] Tao don #4 PENDING...` | Thông điệp do lập trình viên viết |

Hai phần đáng chú ý nhất khi truy vết:

- **Thread** — trong cùng một service, các dòng có cùng tên thread thuộc cùng một request. Đây là cách truy vết thủ công khi chưa có `traceId`.
- **Logger** — cho biết lỗi phát sinh ở class nào, không phải đọc hết stacktrace mới biết.

## 2.4 · Quy ước ghi log của QuickBite

`order-service` ghi log theo mốc nghiệp vụ. Một đơn hàng thành công để lại đúng bốn dòng `INFO`:

```
[BUOC 2] Tao don #4 PENDING - Pho Thin / Pho bo tai lan / 75000d
[BUOC 3] Da tru 75000d cua user #1
[BUOC 4] Nha hang Pho Thin da nhan don #4
[BUOC 5-6] Don #4 CONFIRMED, da gui thong bao
```

Đọc bốn dòng này là biết đơn đi được đến đâu. Đó là mục đích của `INFO`: **ghi nhận mốc nghiệp vụ**.

Khi `user-service` ngừng hoạt động, cùng thao tác đó để lại:

```
[BUOC 2] Tao don #5 PENDING - Pho Thin / Pho bo tai lan / 75000d
[BUOC 3] THAT BAI - huy don #5
```

Dòng thứ hai ở mức `WARN`, không phải `ERROR`. Lý do: ứng dụng **đã có cách xử lý** — nó huỷ đơn và hoàn tiền, người dùng nhận được phản hồi rõ ràng. Đúng định nghĩa `WARN` ở mục 2.1.

Ba nguyên tắc rút ra:

| Nguyên tắc | Nội dung |
|---|---|
| **Ghi log ở mốc nghiệp vụ, không ghi ở mỗi dòng code** | Bốn dòng cho một đơn hàng là đủ để truy vết; bốn mươi dòng thì không ai đọc |
| **Kèm định danh vào nội dung** | `don #5`, `user #1` cho phép `grep` ra đúng đơn cần điều tra |
| **Chọn level theo hậu quả, không theo cảm giác** | Đã xử lý được thì `WARN`; thao tác thất bại thì `ERROR` |

---

# TỔNG KẾT

| Điểm | Nội dung |
|---|---|
| 1 | Log local và log Production khác nhau về mục đích, định dạng, level và vòng đời — không sao chép cấu hình giữa hai môi trường |
| 2 | Ứng dụng ghi ra `stdout`; Docker logging driver thu nhận; hệ thống tập trung lưu trữ và lập chỉ mục |
| 3 | `docker compose logs` dùng **service name**, không dùng container name |
| 4 | Bốn tham số phải thuộc: `--tail`, `-t`, `--since`, `-f` |
| 5 | Khoanh vùng sự cố theo năm bước, bắt đầu từ `docker compose ps -a` chứ không phải từ log |
| 6 | Không ghi password, token, API key hay request body vào log; chỉ ghi định danh và mã lỗi chuẩn hoá |
| 7 | Năm level `TRACE` → `DEBUG` → `INFO` → `WARN` → `ERROR`; Production giữ ngưỡng `INFO` |
| 8 | Chọn level theo hậu quả: xử lý được thì `WARN`, thất bại thì `ERROR` |
