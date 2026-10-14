# TÀI LIỆU SINH VIÊN — SESSION 11
# Reverse proxy với Nginx trong môi trường production

> **Tài liệu này bám sát slide bài giảng.** Bốn Lesson và các mục con đánh số **đúng như trên slide**, để bạn đối chiếu được giữa lúc nghe giảng và lúc đọc lại.

> **Ba tài liệu của buổi học:**
>
> | Tài liệu | Dùng khi nào |
> |---|---|
> | Slide bài giảng | Nghe giảng trên lớp |
> | **Tài liệu này** | Đọc lại để **hiểu vì sao** |
> | `S11-02-Lab-thuc-hanh.html` | **Gõ lệnh** — bảng lệnh đầy đủ kèm 3 thí nghiệm gây lỗi |

## Bản đồ: slide ↔ tài liệu ↔ bài lab

| Slide | Lesson | Tài liệu này | Bài lab |
|---|---|---|---|
| 4–6 | **01** · Khái niệm Reverse Proxy và vai trò của Nginx | Lesson 01 | BÀI 1 |
| 8–10 | **02** · Cấu trúc tệp cấu hình Nginx và các khối chính | Lesson 02 | BÀI 2 |
| 12–13 | **03** · Cấu hình Nginx chuyển tiếp request đến API Gateway | Lesson 03 | BÀI 3 |
| 15–18 | **04** · Trỏ tên miền và thiết lập SSL/HTTPS với Let's Encrypt | Lesson 04 | BÀI 4 |
| — | Tìm lỗi | Rải trong từng Lesson | BÀI 5 |

---

# Trước khi vào bài: buổi này nối tiếp Session 10 thế nào

<div class="keybox">
<span class="lbl">Một câu để nhớ cả buổi</span>
<p><strong>Session 10 đưa hệ thống lên mạng. Session 11 thu hẹp nó lại còn đúng một điểm chạm.</strong></p>
</div>

| | Session 10 | **Session 11** |
|---|---|---|
| Câu hỏi | *"Làm sao đưa hệ thống lên máy chủ thật?"* | *"Làm sao để chỉ có **một cửa** ra Internet?"* |
| Cổng mở ra Internet | SSH + **8080** (API Gateway) | SSH + **80 và 443** — gateway **đóng hẳn** |
| Người dùng gõ gì | `http://13.210.134.235:8080/api/v1/users` | `https://api.quickbite.com/api/v1/users` |
| Mã hoá đường truyền | ❌ HTTP thuần | ✅ **HTTPS** |
| Kiến thức mới | SSH, UFW, Docker Compose | **Reverse proxy, `server`/`location`, `proxy_pass`, SSL termination** |

---

# LESSON 01 · KHÁI NIỆM REVERSE PROXY VÀ VAI TRÒ CỦA NGINX

## 1.1 · Không nên mở trực tiếp nhiều cổng service ra Internet

| | **Không có Reverse Proxy** | **Có Nginx Reverse Proxy** |
|---|---|---|
| Client gọi | Trực tiếp các cổng `8080`, `8081`, `8082` | Chỉ cổng **80** hoặc **443** |
| Diện tấn công | **Rộng** — nhiều cổng public | **Hẹp** — một điểm vào |
| Domain, HTTPS, cấu hình client | **Khó quản lý** — phải làm ở từng nơi | Làm **một lần** tại Nginx |
| Service phía sau | Phơi ra Internet | **Cô lập** trong mạng nội bộ hoặc localhost |

### Mô hình kiến trúc mục tiêu

```
┌──────────────────┐
│ Client / Internet│
└────────┬─────────┘
         │  chỉ 80 / 443
         ▼
┌──────────────────────────────┐
│ Nginx Reverse Proxy          │  ← điểm truy cập DUY NHẤT
│ (Port 80 / 443)              │
└────────┬─────────────────────┘
         │  mạng nội bộ
         ▼
┌──────────────────────────────┐
│ API Gateway (Internal)       │
└────────┬─────────────────────┘
         ▼
┌──────────────────────────────┐
│ Backend Microservices        │
│ QuickBite: 8081, 8082, 8083  │
└──────────────────────────────┘
```

> ⚠️ **Mỗi cổng mở ra Internet là một cánh cửa phải canh.** Thêm một trang quản trị, thêm một WebSocket, thêm một service — là thêm một cổng nữa, thêm một chứng chỉ nữa, thêm một chỗ nữa có thể quên vá. Reverse proxy biến **N cánh cửa** thành **một**.

## 1.2 · So sánh Forward Proxy và Reverse Proxy

| | **Forward Proxy** | **Reverse Proxy (Nginx)** |
|---|---|---|
| Đứng trước | **Client** | **Server** |
| Đại diện cho | Client đi ra Internet | Cụm server nhận request từ Internet |
| Client nhìn thấy | **Biết** request đi qua proxy | **Chỉ thấy proxy**, không biết hệ thống phía sau |
| Ví dụ | VPN, proxy công ty | Nginx trước API Gateway QuickBite |

```
Forward Proxy:   Client ──▶ Proxy ──▶ Internet ──▶ Server đích
Reverse Proxy:   Client ──▶ Internet ──▶ Nginx ──▶ API Gateway / Services
```

<div class="keybox">
<span class="lbl">Điểm khác biệt then chốt</span>
<p><strong>Forward Proxy</strong>: bảo vệ và che giấu <strong>identity của Client</strong>.</p>
<p><strong>Reverse Proxy</strong>: bảo vệ và ẩn giấu <strong>hạ tầng của Server</strong>.</p>
</div>

**Ứng dụng Nginx trong Microservices:**

- Đóng vai trò Reverse Proxy làm **cổng giao tiếp duy nhất**
- Điều hướng request, cân bằng tải và tăng cường bảo mật

## 1.3 · Client không gọi trực tiếp các cổng service nữa

Sau khi có Nginx:

- Client **không cần** gọi trực tiếp cổng `8080`, `8081` hoặc `8082`
- **API Gateway tiếp tục định tuyến** request trong mạng Docker

> 💡 **Hai lớp định tuyến, không thừa chút nào.** Nginx định tuyến ở **tầng mạng** (đường dẫn nào ra ngoài, cổng nào, chứng chỉ nào). API Gateway định tuyến ở **tầng nghiệp vụ** (`/api/v1/orders` thuộc order-service). Bỏ lớp nào cũng được, nhưng khi đó lớp còn lại phải gánh việc nó không giỏi.

<details class="q"><summary><span>Đã có API Gateway rồi, vì sao còn cần Nginx?</span></summary>

| Việc | API Gateway | **Nginx** |
|---|---|---|
| Định tuyến theo nghiệp vụ | ✅ Giỏi — hiểu service nào xử lý gì | Làm được nhưng thô |
| Chấm dứt TLS, quản lý chứng chỉ | Làm được nhưng nặng, phải cấu hình trong Java | ✅ **Việc của nó** |
| Phục vụ file tĩnh | ❌ Lãng phí | ✅ Rất nhanh |
| Chịu tải kết nối rác từ Internet | Mỗi kết nối tốn một luồng JVM | ✅ Nhẹ, hàng vạn kết nối |
| Đổi cấu hình | **Phải restart ứng dụng** | ✅ `reload`, không rớt request |

**Câu trả lời ngắn:** Gateway hiểu **nghiệp vụ**, Nginx giỏi **mạng**. Đặt Nginx ở biên để nó hứng mọi thứ bẩn từ Internet, còn Gateway chỉ làm việc nó giỏi.
</details>

<details class="q"><summary><span>"Ẩn giấu hạ tầng" cụ thể là ẩn cái gì?</span></summary>

Trước khi có Nginx, kẻ quét cổng server bạn thấy cổng `8080` chạy một ứng dụng Java. Họ biết ngay đó là Spring, đoán được phiên bản, và tra được các lỗ hổng đã công bố.

Sau khi có Nginx, họ chỉ thấy `80` và `443` chạy Nginx. **Mọi thông tin về công nghệ bên trong biến mất.**

> Đây là cùng một ý tưởng **giảm bề mặt tấn công** đã gặp ở Session 08 (bỏ `javac` khỏi image) và Session 10 (không publish database). Mỗi buổi áp dụng nó ở một tầng khác nhau.
</details>

---

# LESSON 02 · CẤU TRÚC TỆP CẤU HÌNH NGINX

## 2.1 · Tạo file cấu hình riêng trong `conf.d/`

`nginx.conf` là **file gốc**, và ta **không sửa nó**. Bên trong khối `http` của nó đã có sẵn:

```
include /etc/nginx/conf.d/*.conf;
```

Nghĩa là mọi file `.conf` bạn đặt vào `conf.d/` đều được nạp tự động.

| Nguyên tắc | Nội dung |
|---|---|
| **File cấu hình riêng** | Chỉ tạo hoặc sửa file riêng như `quickbite.conf`, **không** sửa trực tiếp file gốc |
| **Phạm vi khối** | File trong `conf.d/` **không khai báo lại** `http {}` hay `events {}` — chúng đã nằm trong context cha |
| **Kiểm tra an toàn** | Luôn kiểm tra bằng `sudo nginx -t` **trước khi** reload |

> ⚠️ **Trên Ubuntu có một cái bẫy im lặng.** Ubuntu còn một thư mục thứ hai là `sites-enabled/`, và nó chứa sẵn một site mặc định cũng nghe cổng 80 với `server_name _`. Khi bạn thêm file vào `conf.d/`, hai khối tranh nhau và Nginx **bỏ qua một cái**:
>
> ```
> [warn] conflicting server name "_" on 0.0.0.0:80, ignored
> nginx: configuration file ... test is successful
> ```
>
> Vì đó chỉ là `warn`, `nginx -t` vẫn báo **successful** — rất dễ lướt qua rồi tưởng mình cấu hình sai chỗ khác.
>
> **Sửa:** `sudo rm /etc/nginx/sites-enabled/default`

<details class="q"><summary><span>Vì sao Ubuntu có tới hai thư mục cấu hình?</span></summary>

| Thư mục | Nguồn gốc | Dùng khi |
|---|---|---|
| `conf.d/` | **Chuẩn của Nginx**, dùng trên mọi bản Linux | Cách slide dạy, nên dùng |
| `sites-available/` + `sites-enabled/` | Thói quen từ Debian/Ubuntu, bắt chước Apache | Bật/tắt site bằng symlink |

Cả hai đều được `nginx.conf` nạp, nên chúng **tranh nhau**. Hãy chọn một kiểu và dùng nhất quán.
</details>

## 2.2 · Hai khối cấu hình chính: `server` và `location`

```nginx
server {
    listen 80;
    server_name _;

    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
    }
}
```

| Dòng | Nghĩa |
|---|---|
| `listen 80` | Nhận request HTTP trên cổng 80 |
| `server_name _` | Khớp request đi vào **IP VPS** (trong ví dụ này chưa có tên miền) |
| `location /` | Khớp tất cả các URI bắt đầu từ `/` |

| Khối | Vai trò | Chỉ thị thường gặp |
|---|---|---|
| **`server`** | Xác định **máy chủ ảo** theo cổng và tên miền | `listen`, `server_name`, `access_log`, `error_log` |
| **`location`** | Xử lý **một đường dẫn URI** cụ thể | `root`, `index`, `proxy_pass` |

<details class="q"><summary><span>`server_name _` thật ra nghĩa là gì?</span></summary>

Dấu `_` **không phải ký tự đặc biệt** trong Nginx. Nó chỉ là một tên miền không hợp lệ nên **không bao giờ khớp Host header thật**.

Tác dụng thật: khi không khối `server` nào khớp, Nginx dùng **khối đầu tiên nghe trên cổng đó** làm mặc định — và `_` là quy ước để nói *"đây là khối bắt tất cả"*.

Khi có tên miền thật, ta đổi thành `server_name api.quickbite.com;` và Nginx mới so khớp theo Host header.
</details>

## 2.3 · Quy tắc so khớp `location`

Nginx **không** chọn khối đầu tiên khớp — nó chọn khối **phù hợp nhất** theo modifier.

| Modifier | Loại so khớp | Ví dụ |
|---|---|---|
| `=` | **Chính xác, ưu tiên cao nhất** | `location = /favicon.ico` |
| `^~` | Tiền tố ưu tiên, **không quét Regex** | `location ^~ /assets/` |
| `~` `~*` | Regular Expression (`~*` không phân biệt hoa thường) | `location ~* \.json$` |
| *(không có)* | Tiền tố mặc định | `location /api` |

### Ví dụ thực tế

```nginx
location /api/v1/ { ... }
location ~* \.json$ { ... }
```

Với URI `/api/v1/users.json` → **khối Regex được chọn**.

> 💡 **Lý do:** tiền tố `/api/v1/` **không dùng modifier `^~`**, do đó Nginx ghi nhớ nó rồi **vẫn tiếp tục kiểm tra các quy tắc Regular Expression**. Regex nào khớp trước sẽ thắng.

> ⚠️ **Đây là nguyên nhân của một loại lỗi rất khó tìm.** Bạn thêm một `location ~* \.(js|css|json)$` để phục vụ file tĩnh, và đột nhiên các API trả về `.json` **ngừng đi qua proxy** — chúng rơi vào khối file tĩnh và trả về 404.
>
> **Sửa:** đổi `location /api/` thành `location ^~ /api/` để chặn Nginx quét tiếp regex.

---

# LESSON 03 · CẤU HÌNH NGINX CHUYỂN TIẾP REQUEST ĐẾN API GATEWAY

## 3.1 · Dùng `proxy_pass` và giữ thông tin request gốc

```nginx
location /api {
    proxy_pass http://127.0.0.1:8080;
    proxy_set_header Host              $host;
    proxy_set_header X-Real-IP         $remote_addr;
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

| Cấu hình | Thông tin được chuyển tiếp |
|---|---|
| `proxy_pass` | **Địa chỉ API Gateway đích** |
| `Host` | Tên miền request ban đầu |
| `X-Real-IP` | IP client kết nối tới Nginx |
| `X-Forwarded-For` | Chuỗi IP đã đi qua các proxy |
| `X-Forwarded-Proto` | Giao thức ban đầu: HTTP hoặc HTTPS |

> ⚠️ **Vì sao bốn header này quan trọng?** Vì sau khi đi qua proxy, **backend không còn nhìn thấy client thật** — nó chỉ thấy Nginx.
>
> | Thiếu header | Hậu quả |
> |---|---|
> | `X-Real-IP` / `X-Forwarded-For` | Log ứng dụng ghi **IP của Nginx** cho mọi người dùng. Chặn IP, giới hạn tốc độ, phân tích truy cập đều sai |
> | `Host` | Ứng dụng tự sinh link sai tên miền |
> | `X-Forwarded-Proto` | Ứng dụng tưởng đang chạy HTTP, sinh link `http://` trong trang HTTPS → trình duyệt chặn |

<details class="q"><summary><span>Dấu `/` ở cuối `proxy_pass` làm thay đổi điều gì?</span></summary>

Đây là chi tiết gây nhầm nhiều nhất của Nginx.

| Cấu hình | URI `/api/v1/users` được chuyển thành |
|---|---|
| `proxy_pass http://gw:8080;` | `/api/v1/users` — **giữ nguyên** |
| `proxy_pass http://gw:8080/;` | `/v1/users` — **cắt mất `/api`** |

**Quy tắc:** `proxy_pass` **có** đường dẫn (kể cả chỉ một dấu `/`) thì Nginx **thay thế** phần tiền tố đã khớp. **Không có** đường dẫn thì Nginx **giữ nguyên** URI.

Với QuickBite ta **không** thêm dấu `/`, vì API Gateway cần nhận đủ `/api/v1/users` để khớp route `Path=/api/v1/users/**` của nó.
</details>

## 3.2 · Kiểm tra trước, reload sau

Quy trình đổi cấu hình trên production, **bốn bước, không đảo**:

```
# 1. Sửa cấu hình
sudo nano /etc/nginx/conf.d/quickbite.conf

# 2. Kiểm tra cú pháp
sudo nginx -t

# 3. Nạp cấu hình mới
sudo systemctl reload nginx

# 4. Gọi thử và xem log
curl http://<vps_public_ip>/api/v1/restaurants
tail -n 10 /var/log/nginx/quickbite_access.log
```

| Bước | Mục đích |
|---|---|
| 1. Sửa file | Cập nhật thông số proxy hoặc upstream mới |
| 2. `nginx -t` | Đảm bảo **không gián đoạn do lỗi cú pháp** trước khi apply |
| 3. `reload` | Áp dụng an toàn, **không ngắt kết nối người dùng** |
| 4. Verify | Kiểm tra phản hồi thực tế và theo dõi log |

### Vì sao nên dùng `reload` thay vì `restart`

| | `reload` | `restart` |
|---|---|---|
| Request đang chạy dở | **Được xử lý nốt** | **Bị cắt ngang** |
| Thời gian ngừng dịch vụ | **Không có** | Có, dù ngắn |

> 💡 Nginx chạy theo mô hình **một master nhiều worker**. Lệnh `reload` cho phép worker cũ xử lý nốt request đang chạy dở trước khi đóng hẳn, đồng thời khởi tạo worker mới với cấu hình mới. Nhờ vậy hệ thống hoạt động **liên tục**, không dừng toàn bộ dịch vụ như `restart`.

<details class="q"><summary><span>Nếu cú pháp sai mà vẫn reload thì dịch vụ có sập không?</span></summary>

**Không.** Trong bài lab có thí nghiệm đo thật:

1. Làm hỏng cấu hình trên đĩa → API **vẫn trả `200`**, vì Nginx chỉ đọc file khi bạn bảo nó đọc; worker đang chạy vẫn dùng cấu hình cũ trong bộ nhớ.
2. Chạy `reload` với cấu hình hỏng → Nginx **từ chối thay**, giữ nguyên cấu hình cũ. API **vẫn `200`**.

**Vậy vì sao vẫn phải `nginx -t`?** Vì nó cho bạn biết **ngay lúc đó** rằng thay đổi của mình **chưa có tác dụng**. Không có nó, bạn reload, không thấy báo gì, rồi tưởng đã xong — trong khi hệ thống vẫn chạy cấu hình cũ. Đó là kiểu lỗi mất hàng giờ để phát hiện.

**Cách viết an toàn:** `sudo nginx -t && sudo systemctl reload nginx`
</details>

---

# LESSON 04 · TRỎ TÊN MIỀN VÀ THIẾT LẬP SSL/HTTPS VỚI LET'S ENCRYPT

> 📑 **Mục 4.1 trên slide lặp lại nội dung `proxy_pass` của Lesson 03** — xem lại mục **3.1** ở trên. Phần mới của Lesson 04 bắt đầu từ 4.2.

## 4.2 · Tên miền và HTTPS giải quyết hai vấn đề khác nhau

| Thành phần | Vai trò trong QuickBite |
|---|---|
| **DNS A Record** | Trỏ `api.quickbite.com` về **public IP** của VPS |
| **HTTPS** | **Mã hoá** dữ liệu truyền giữa client và Nginx |
| **Let's Encrypt** | Cấp chứng chỉ SSL/TLS **miễn phí** |
| **Certbot** | Xác thực tên miền và hỗ trợ cấu hình chứng chỉ cho Nginx |

| | **HTTP** (không an toàn) | **HTTPS** (an toàn) |
|---|---|---|
| Dữ liệu trên đường truyền | **Plaintext** — dễ bị can thiệp | **Mã hoá SSL/TLS** |
| Nguy cơ | Nghe lén mật khẩu, token xác thực, dữ liệu người dùng | Bảo vệ mật khẩu, JWT token, thông tin giao dịch |

> ⚠️ **Hai thứ này độc lập nhau.** Có tên miền mà không có HTTPS thì vẫn bị nghe lén. Và bạn **không thể có HTTPS mà không có tên miền**, vì **Let's Encrypt chỉ cấp chứng chỉ cho tên miền, không cấp cho địa chỉ IP**. Đó là lý do phải làm DNS trước.

## 4.3 · Cấu hình Certbot cho tên miền QuickBite

| # | Bước | Nội dung |
|---|---|---|
| **1** | Tạo **DNS A Record** | Trỏ `api.quickbite.com` → `<vps_public_ip>` |
| **2** | Cập nhật Nginx | Khai báo `server_name api.quickbite.com;` trong `quickbite.conf` |
| **3** | Cài **Certbot** và plugin Nginx | `sudo apt install certbot python3-certbot-nginx -y` |
| **4** | Xin chứng chỉ và kiểm tra gia hạn | `sudo certbot --nginx -d api.quickbite.com` |

```
# 1. Kiểm tra kết nối DNS
ping api.quickbite.com

# 2. Cài đặt Certbot
sudo apt update && sudo apt install certbot python3-certbot-nginx -y

# 3. Khởi chạy xác thực và cấu hình tự động
sudo certbot --nginx -d api.quickbite.com
```

Kết quả mong đợi:

```
Requesting a certificate for api.quickbite.com
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/api.quickbite.com/fullchain.pem
Deploying certificate to VirtualHost /etc/nginx/conf.d/quickbite.conf
Congratulations! You have successfully enabled HTTPS
```

```
# 4. Giả lập thử nghiệm gia hạn tự động
sudo certbot renew --dry-run
```

```
Congratulations, all simulated renewals succeeded!
```

> ⚠️ **Đừng chạy Certbot khi DNS chưa trỏ đúng.** Let's Encrypt xác thực bằng cách **gọi ngược về tên miền của bạn**. DNS chưa đúng là nó không gọi tới được, và bạn nhận một lỗi khó hiểu. **`ping` ra đúng IP rồi mới làm bước sau.**

> 💡 **Certbot tự sửa file cấu hình của bạn** — nó thêm `listen 443 ssl`, trỏ `ssl_certificate` tới `/etc/letsencrypt/live/...`, thêm `include options-ssl-nginx.conf`, và tạo khối `server` cổng 80 để chuyển hướng. Mọi dòng nó thêm đều mang chú thích `# managed by Certbot`.
>
> Cấu trúc giống file bạn viết tay ở mục 4.4, chỉ khác ở chỗ Certbot viết redirect bằng `if ($host = ...)`. Trong bài lab bạn **làm tay trước rồi mới dùng Certbot** là có chủ ý: để đọc hiểu được thứ nó sinh ra, thay vì coi là phép màu.

> ⚠️ **Chứng chỉ Let's Encrypt chỉ sống 90 ngày.** Certbot cài sẵn timer tự gia hạn, nhưng nó **chỉ chạy được nếu cổng 80 vẫn mở** để Let's Encrypt xác thực lại. **Đừng chặn cổng 80 sau khi có HTTPS** — hãy để nó làm nhiệm vụ redirect **và** gia hạn chứng chỉ.

## 4.4 · SSL Termination và chuyển hướng HTTP sang HTTPS

```nginx
server {
    listen 80;
    server_name api.quickbite.com;
    return 301 https://$host$request_uri;    # HTTP -> HTTPS
}
```

### Nguyên lý SSL Termination

```
Client ──HTTPS (mã hoá)──▶ Nginx ──HTTP (mạng nội bộ)──▶ API Gateway
                            ▲
                     giải mã tại đây
```

| Nguyên lý | Nội dung |
|---|---|
| **Quản lý tập trung** | Nginx giữ chứng chỉ SSL và private key, xử lý kết nối HTTPS ngay tại **biên (edge)** |
| **Giải mã an toàn** | Nginx giải mã request rồi chuyển tiếp traffic dạng **HTTP** vào API Gateway qua mạng nội bộ |
| **Tối ưu tài nguyên** | Giảm tải mã hoá/giải mã cho từng microservice phía sau |

### Chuyển hướng tự động HTTP → HTTPS

| Nội dung | Ý nghĩa |
|---|---|
| **Redirect vĩnh viễn (301)** | Mọi request tới cổng 80 được tự động chuyển lên cổng 443 |
| **Bảo mật** | Không dữ liệu nhạy cảm nào bị truyền qua kết nối HTTP không mã hoá |
| **Chuẩn URL** | Giữ nguyên tên miền và các path/query parameter của request gốc |

<details class="q"><summary><span>Bên trong là HTTP thuần thì có an toàn không?</span></summary>

Trong phạm vi buổi học thì **có**: đoạn Nginx → API Gateway nằm **trong cùng một máy chủ**, không đi qua Internet. Gói tin không rời khỏi máy.

Khi hệ thống trải trên **nhiều máy chủ**, đoạn đó cũng cần mã hoá — đó là chủ đề của mTLS và service mesh, nằm ngoài phạm vi hôm nay.
</details>

<details class="q"><summary><span>Vì sao dùng `301` chứ không `302`?</span></summary>

| Mã | Nghĩa | Hệ quả |
|---|---|---|
| **`301`** | Chuyển **vĩnh viễn** | Trình duyệt **nhớ**, lần sau đi thẳng HTTPS |
| `302` | Chuyển **tạm thời** | Trình duyệt hỏi lại cổng 80 **mỗi lần** |

**Mặt trái của `301`:** trình duyệt nhớ **rất lâu**. Nếu bạn lỡ cấu hình sai rồi sửa, người dùng vẫn bị đẩy theo đường cũ cho tới khi xoá cache.

Khi còn đang thử nghiệm, hãy dùng `302`, chỉ đổi sang `301` khi đã chắc chắn.
</details>

---

# TỔNG KẾT

| Ý | Nội dung |
|---|---|
| **1** | Reverse Proxy **đại diện cho server**; Nginx tạo **điểm vào duy nhất** |
| **2** | Chỉ cấu hình dự án trong `/etc/nginx/conf.d/`; dùng `server` và `location` để xử lý request |
| **3** | `proxy_pass` chuyển request đến API Gateway; `proxy_set_header` giữ lại thông tin client cần thiết |
| **4** | Luôn chạy `nginx -t` **trước** `systemctl reload nginx` |
| **5** | DNS A Record trỏ domain về VPS; Certbot hỗ trợ cài SSL/HTTPS cho Nginx |

## Ba điều nếu chỉ nhớ được ba điều

1. **Một cửa vào, và cửa đó không nói gì về bên trong.** Đó là toàn bộ mục đích của reverse proxy.
2. **`nginx -t && systemctl reload nginx`** — gộp hai lệnh thành một thói quen, đừng tách rời.
3. **`502` là lỗi của backend, không phải của Nginx.** Thấy `502` thì đi kiểm tra thứ phía sau trước.

# Bảng tra nhanh

| Việc | Lệnh |
|---|---|
| Kiểm tra cú pháp | `sudo nginx -t` |
| Nạp lại, không ngắt dịch vụ | `sudo systemctl reload nginx` |
| Gộp hai bước cho an toàn | `sudo nginx -t && sudo systemctl reload nginx` |
| In **toàn bộ** cấu hình đang chạy | `sudo nginx -T` |
| Log truy cập | `tail -n 20 /var/log/nginx/quickbite_access.log` |
| Log lỗi | `tail -n 20 /var/log/nginx/quickbite_error.log` |
| Gỡ site mặc định Ubuntu | `sudo rm /etc/nginx/sites-enabled/default` |
| Cài Certbot | `sudo apt install certbot python3-certbot-nginx -y` |
| Xin chứng chỉ | `sudo certbot --nginx -d api.quickbite.com` |
| Thử gia hạn | `sudo certbot renew --dry-run` |

# Bảng mã lỗi hay gặp

| Mã | Nghĩa | Hỏng ở đâu |
|---|---|---|
| `curl` treo / `000` | Không kết nối được tới Nginx | **Tường lửa**, Nginx chưa chạy, sai cổng |
| `404` | Nginx chạy nhưng không khối `location` nào khớp | **Cấu hình Nginx** |
| **`502` Bad Gateway** | Nginx chạy nhưng **không gọi được backend** | `proxy_pass` sai, hoặc Gateway chết |
| **`504` Gateway Timeout** | Gọi được backend nhưng nó **không trả lời kịp** | Backend treo hoặc quá chậm |
| `301` | Chuyển hướng sang HTTPS | Đúng như thiết kế |

# Từ khoá cần phân biệt

| Cặp khái niệm | Khác nhau ở |
|---|---|
| Forward Proxy ↔ Reverse Proxy | Che giấu **Client** ↔ Che giấu **hạ tầng Server** |
| Nginx ↔ API Gateway | Định tuyến **tầng mạng** ↔ định tuyến **tầng nghiệp vụ** |
| `nginx -t` ↔ `nginx -T` | Kiểm tra **cú pháp** ↔ In **toàn bộ cấu hình đang chạy** |
| `reload` ↔ `restart` | Không ngắt request ↔ **Cắt ngang** request |
| `conf.d/` ↔ `sites-enabled/` | Chuẩn Nginx ↔ Thói quen Ubuntu — **chúng tranh nhau** |
| `location /api` ↔ `location ^~ /api` | Vẫn quét tiếp regex ↔ **Khớp rồi thì dừng** |
| `proxy_pass …:8080` ↔ `…:8080/` | Giữ nguyên URI ↔ **Cắt mất tiền tố** |
| `301` ↔ `302` | Vĩnh viễn, trình duyệt nhớ ↔ Tạm thời |
| `502` ↔ `504` | Không gọi được backend ↔ Backend **không trả lời kịp** |
