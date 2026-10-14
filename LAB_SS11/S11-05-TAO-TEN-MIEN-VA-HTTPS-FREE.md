# HƯỚNG DẪN THAO TÁC — SESSION 11
# Tạo tên miền và bật HTTPS miễn phí

> **Đây là bảng thao tác, không phải tài liệu lý thuyết.** Làm tuần tự **Bước 1 → Bước 9**, khoảng **20 phút** là xong.
> Mỗi bước theo đúng bố cục: **Cấu trúc** → **Lệnh** → **Giải thích** → **Ví dụ**.

> **Khác gì file 04?**
>
> | File | Dùng khi |
> |---|---|
> | `S11-04-HTTPS-that-va-ten-mien.html` | **Tìm hiểu** — so sánh các cách, giới hạn, Caddy, mua tên miền |
> | **File này** | **Làm ngay** — một con đường duy nhất, chép lệnh là chạy |

> **Kết quả cuối:** `https://ten-cua-ban.duckdns.org/api/v1/users` chạy được trên trình duyệt, **ổ khoá đóng, không cảnh báo**, và **không tốn đồng nào**.

---

# BƯỚC 0 · ĐIỀU KIỆN CẦN

**Giải thích**

| Thứ | Bắt buộc | Vì sao |
|---|---|---|
| VPS có **IP public** | ✅ | Let's Encrypt phải gọi ngược về được |
| Nginx đã chạy, đã proxy tới API Gateway | ✅ | Đã làm ở BÀI 3 của bài lab |
| Quyền `sudo` trên VPS | ✅ | Cài Certbot, sửa cấu hình |
| Tài khoản Google hoặc GitHub | ✅ | Để đăng nhập DuckDNS |
| Tiền | ❌ **Không cần** | Toàn bộ quy trình miễn phí |

**Lệnh** — kiểm tra Nginx đang phục vụ API

```bash
curl -s -o /dev/null -w 'API qua Nginx: %{http_code}\n' --max-time 8 http://<ip-vps-cua-ban>/api/v1/users
```

**Ví dụ**

```
API qua Nginx: 200
```

> ⚠️ **Nếu chưa ra `200`, dừng lại.** Quay về BÀI 3 của bài lab làm cho xong đã. Certbot dùng **chính đường đi này** để xác thực — Nginx chưa chạy thì Certbot chắc chắn thất bại.

---

# BƯỚC 1 · TẠO TÊN MIỀN MIỄN PHÍ

**Cấu trúc tên miền sẽ có**

```
quickbite-an . duckdns.org
└─────┬─────┘  └────┬────┘
  bạn tự đặt    cố định
```

**Thao tác trên trình duyệt**

| # | Việc |
|---|---|
| 1 | Vào **duckdns.org** |
| 2 | Bấm đăng nhập bằng **Google** hoặc **GitHub** (không cần thẻ, không cần email riêng) |
| 3 | Ở ô **sub domain**, gõ tên bạn muốn — ví dụ `quickbite-an` |
| 4 | Bấm **add domain** |

**Giải thích**

| | Nội dung |
|---|---|
| Số tên miền được tạo | **5 cái** cho mỗi tài khoản, miễn phí |
| Thời hạn | Không giới hạn, miễn là còn đăng nhập thỉnh thoảng |
| Đặt tên thế nào | Chỉ chữ thường, số và dấu `-`. **Nên thêm tên mình** để không trùng |

> ⚠️ **Tên bị trùng thì không thêm được.** `quickbite` chắc chắn đã có người lấy. Hãy dùng `quickbite-<tên-bạn>` hoặc `quickbite-<mã-sinh-viên>`.

**Ví dụ** — sau khi thêm, trang hiện một dòng như sau:

```
quickbite-an.duckdns.org    current ip: [        ]    [update ip]
```

---

# BƯỚC 2 · TRỎ TÊN MIỀN VỀ VPS

**Cấu trúc**

```
quickbite-an.duckdns.org  ──────▶  13.210.134.235
      tên miền                       IP của VPS
```

**Thao tác**

| # | Việc |
|---|---|
| 1 | Điền **IP public của VPS** vào ô `current ip` |
| 2 | Bấm **update ip** |

**Giải thích**

| | Nội dung |
|---|---|
| Lấy IP VPS ở đâu | AWS Console → EC2 → cột **Public IPv4 address** |
| Đổi IP sau này | Vào lại trang này, sửa rồi bấm `update ip` lần nữa |
| Mất bao lâu để có hiệu lực | **Dưới 1 phút** — DuckDNS đặt thời gian lưu đệm rất ngắn |

> 💡 **Quên mất IP VPS?** Gõ lệnh này **ngay trên VPS**:
> ```
> curl -s ifconfig.me; echo
> ```

**Ví dụ**

```
quickbite-an.duckdns.org    current ip: [13.210.134.235]    ✓ OK
```

---

# BƯỚC 3 · KIỂM TRA TÊN MIỀN ĐÃ TRỎ ĐÚNG

**Cấu trúc lệnh**

```
dig +short <tên-miền> [@máy-chủ-DNS]
    └──┬──┘            └─────┬─────┘
  chỉ in kết quả    hỏi thẳng, bỏ qua bộ nhớ đệm
```

**Lệnh** — chạy trên **máy của bạn**, không phải VPS

```bash
dig +short quickbite-an.duckdns.org
```
```bash
dig +short quickbite-an.duckdns.org @8.8.8.8
```

**Giải thích**

| Kết quả | Nghĩa | Làm gì tiếp |
|---|---|---|
| Ra **đúng IP VPS** | ✅ Xong bước này | Sang Bước 4 |
| **Không ra gì** | Chưa lan truyền, hoặc chưa bấm `update ip` | Đợi 1 phút, thử lại |
| Ra **IP khác** | Điền nhầm IP | Quay lại Bước 2 sửa |

> ⚠️ **Đừng dùng `ping` để kiểm tra.** Máy bạn có thể đang nhớ kết quả cũ. `dig` chính xác hơn, và `@8.8.8.8` cho bạn hỏi thẳng máy chủ DNS của Google, bỏ qua mọi bộ nhớ đệm trung gian.

**Ví dụ**

```
13.210.134.235
13.210.134.235
```

> 🛑 **Chỉ đi tiếp khi cả hai lệnh đều ra đúng IP.** Chạy Certbot khi DNS chưa đúng sẽ **tiêu hạn mức** — xem Bảng lỗi cuối file.

---

# BƯỚC 4 · MỞ CỔNG 80 VÀ 443

**Cấu trúc** — trên AWS có **hai lớp** tường lửa, phải mở **cả hai**

```
Internet ──▶ Security Group (AWS) ──▶ UFW (trong máy) ──▶ Nginx
             └──── lớp 1 ────┘        └─── lớp 2 ───┘
```

**Lệnh** — lớp 2, chạy **trên VPS**

```bash
sudo ufw allow 80/tcp
```
```bash
sudo ufw allow 443/tcp
```
```bash
sudo ufw status verbose
```

**Thao tác** — lớp 1, trên AWS Console

**EC2 → chọn máy → Security → Security groups → Edit inbound rules → Add rule**

| Type | Port | Source |
|---|---|---|
| HTTP | 80 | `0.0.0.0/0` |
| HTTPS | 443 | `0.0.0.0/0` |

**Giải thích**

| Cổng | Dùng để làm gì | Bỏ được không |
|---|---|---|
| **80** | Let's Encrypt xác thực tên miền **và tự gia hạn sau này** | ❌ **Không** |
| **443** | Người dùng truy cập HTTPS | ❌ Không |

> ⚠️ **Cổng 80 phải mở vĩnh viễn, kể cả sau khi đã có HTTPS.** Chứng chỉ sống 90 ngày và Certbot gia hạn qua cổng 80. Chặn nó là 3 tháng sau website chết.

**Ví dụ**

```
80/tcp                     ALLOW IN    Anywhere
443/tcp                    ALLOW IN    Anywhere
```

**Lệnh** — kiểm chứng từ **máy của bạn**

```bash
curl -s -o /dev/null -w 'qua ten mien: %{http_code}\n' --max-time 8 http://quickbite-an.duckdns.org/api/v1/users
```

> 🛑 **Phải ra `200` mới đi tiếp.** Ra `000` là còn một lớp tường lửa chưa mở.

---

# BƯỚC 5 · KHAI BÁO TÊN MIỀN TRONG NGINX

**Cấu trúc file** — `/etc/nginx/conf.d/quickbite.conf`

```nginx
server {
    listen 80;
    server_name quickbite-an.duckdns.org;     ← đổi dòng này
    ...
}
```

**Lệnh**

```bash
sudo nano /etc/nginx/conf.d/quickbite.conf
```
```bash
sudo nginx -t && sudo systemctl reload nginx
```

**Giải thích**

| Trước | Sau | Vì sao phải đổi |
|---|---|---|
| `server_name _;` | `server_name quickbite-an.duckdns.org;` | Certbot **tìm khối `server` theo tên miền** để biết sửa chỗ nào |

> ⚠️ **Bỏ qua bước này thì Certbot sẽ báo lỗi không tìm thấy khối phù hợp**, hoặc sửa nhầm khối khác.

**Ví dụ**

```
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

---

# BƯỚC 6 · CÀI CERTBOT

**Lệnh**

```bash
sudo apt update
```
```bash
sudo apt install certbot python3-certbot-nginx -y
```
```bash
certbot --version
```
```bash
certbot plugins
```

**Giải thích**

| Gói | Vai trò |
|---|---|
| `certbot` | Công cụ xin và gia hạn chứng chỉ |
| `python3-certbot-nginx` | **Plugin** giúp Certbot tự sửa file cấu hình Nginx |

**Ví dụ**

```
certbot 2.9.0

* nginx
Description: Nginx Web Server plugin
```

> ✅ **Phải thấy dòng `* nginx` trong `certbot plugins`.** Không thấy nghĩa là thiếu gói `python3-certbot-nginx`.

---

# BƯỚC 7 · XIN CHỨNG CHỈ

**Cấu trúc lệnh**

```
sudo certbot --nginx -d <tên-miền>
             └──┬──┘ └──────┬─────┘
          dùng plugin    tên miền cần cấp
            Nginx       (thêm -d nữa nếu nhiều tên)
```

**Lệnh** — chạy thử trước, **không tiêu hạn mức**

```bash
sudo certbot certonly --nginx -d quickbite-an.duckdns.org --dry-run
```

> ⚠️ **Phải có chữ `certonly` thì `--dry-run` mới chạy.** Viết `certbot --nginx -d ... --dry-run` sẽ bị từ chối ngay:
> ```
> --dry-run currently only works with the 'certonly' or 'renew' subcommands ('run')
> ```
> `certonly` nghĩa là *chỉ xin chứng chỉ, không sửa cấu hình Nginx* — đúng thứ ta cần khi chỉ muốn thử.

**Lệnh** — chạy thật khi bản thử đã đạt

```bash
sudo certbot --nginx -d quickbite-an.duckdns.org
```

**Giải thích** — Certbot sẽ hỏi gì

| Câu hỏi | Trả lời |
|---|---|
| `Enter email address` | **Email thật** — nhận cảnh báo khi chứng chỉ sắp hết hạn |
| `Please read the Terms of Service... (Y)es/(N)o` | `Y` |
| `Would you be willing to share your email with EFF?` | `N` cũng được |

> 💡 **Muốn chạy không cần trả lời** (ví dụ khi hướng dẫn cả lớp):
> ```
> sudo certbot --nginx -d quickbite-an.duckdns.org --non-interactive --agree-tos -m email-cua-ban@gmail.com
> ```

**Ví dụ** — kết quả thành công

```
Requesting a certificate for quickbite-an.duckdns.org
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/quickbite-an.duckdns.org/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/quickbite-an.duckdns.org/privkey.pem
Deploying certificate
Successfully deployed certificate for quickbite-an.duckdns.org to /etc/nginx/conf.d/quickbite.conf
Congratulations! You have successfully enabled HTTPS
```

**Giải thích** — Certbot vừa sửa file cấu hình của bạn thành thế này:

```nginx
server {
    server_name quickbite-an.duckdns.org;

    location /api/ { ... }                              ← phần bạn viết, giữ nguyên

    listen 443 ssl;                                     # managed by Certbot
    ssl_certificate     /etc/letsencrypt/live/.../fullchain.pem;   # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/.../privkey.pem;     # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf;    # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;      # managed by Certbot
}

server {
    if ($host = quickbite-an.duckdns.org) {
        return 301 https://$host$request_uri;           # managed by Certbot
    }
    listen 80;
    server_name quickbite-an.duckdns.org;
    return 404;                                         # managed by Certbot
}
```

| Certbot thêm gì | Tác dụng |
|---|---|
| `listen 443 ssl` + hai dòng `ssl_certificate*` | Bật HTTPS, trỏ tới chứng chỉ vừa cấp |
| `include options-ssl-nginx.conf` | Bộ thiết lập TLS an toàn do Certbot duy trì |
| `ssl_dhparam` | Tham số trao đổi khoá |
| Khối `server` cổng 80 với `return 301` | Chuyển hướng HTTP sang HTTPS |
| `return 404` ở cuối khối 80 | Chặn request vào cổng 80 bằng tên miền khác |

> 💡 **So với file bạn viết tay ở BÀI 4**, cấu trúc giống nhau (hai khối `server`, redirect 301, trỏ chứng chỉ) nhưng Certbot viết redirect bằng `if ($host = ...)` thay vì `return 301` thẳng, và thêm hai dòng thiết lập TLS. **Mọi dòng nó thêm đều có chú thích `# managed by Certbot`** — đừng sửa tay những dòng đó, lần gia hạn sau nó sẽ ghi đè.

---

# BƯỚC 8 · KIỂM CHỨNG HTTPS

**Lệnh**

```bash
curl https://quickbite-an.duckdns.org/api/v1/users
```
```bash
curl -s -o /dev/null -w 'HTTP -> %{http_code} | chuyen toi: %{redirect_url}\n' http://quickbite-an.duckdns.org/api/v1/users
```

**Giải thích**

| Phép thử | Phải ra gì | Nghĩa là |
|---|---|---|
| `curl https://...` **không có `-k`** | Dữ liệu thật | ✅ **Chứng chỉ hợp lệ** |
| `curl http://...` | `301` → `https://...` | ✅ Redirect đã bật |

> ✅ **Điểm mấu chốt: không cần cờ `-k` nữa.** Ở BÀI 4 của bài lab ta phải dùng `-k` vì chứng chỉ tự ký. Giờ bỏ đi vẫn chạy — **đó chính là bằng chứng chứng chỉ được công nhận**.

**Thao tác** — mở trình duyệt

Vào `https://quickbite-an.duckdns.org/api/v1/users`

| Phải thấy | |
|---|---|
| 🔒 **Ổ khoá đóng** trên thanh địa chỉ | Không có cảnh báo đỏ |
| Bấm vào ổ khoá → `Connection is secure` | Chứng chỉ do **Let's Encrypt** cấp |

**Ví dụ**

```
[{"id":1,"full_name":"Nguyen Van An","email":"an.nguyen@quickbite.vn","wallet_balance":425000}, ...]
HTTP -> 301 | chuyen toi: https://quickbite-an.duckdns.org/api/v1/users
```

---

# BƯỚC 9 · KIỂM TRA TỰ ĐỘNG GIA HẠN

**Cấu trúc**

```
Chứng chỉ sống 90 ngày
      │
      ├── Certbot tự gia hạn khi còn 30 ngày
      └── chạy qua cổng 80 → cổng 80 phải luôn mở
```

**Lệnh**

```bash
sudo certbot renew --dry-run
```
```bash
sudo certbot certificates
```
```bash
systemctl list-timers | grep certbot
```

**Giải thích**

| Lệnh | Trả lời câu hỏi |
|---|---|
| `renew --dry-run` | Cơ chế gia hạn **có chạy được không** |
| `certificates` | Đang có những chứng chỉ nào, hết hạn khi nào |
| `list-timers` | Bộ hẹn giờ tự động **đã bật chưa** |

> 💡 Certbot cài sẵn **hai** cơ chế chạy định kỳ: `certbot.timer` của systemd và `/etc/cron.d/certbot`. Bạn **không phải cấu hình gì thêm**.

**Ví dụ**

```
Congratulations, all simulated renewals succeeded!

Certificate Name: quickbite-an.duckdns.org
    Expiry Date: 20XX-XX-XX (VALID: 89 days)
```

> 🎉 **Đến đây là xong.** Hệ thống của bạn đang chạy HTTPS thật, chứng chỉ tự gia hạn, và không tốn đồng nào.

---

# PHỤ LỤC A · NẾU BẠN ĐÃ MUA TÊN MIỀN RIÊNG

Quy trình **giống hệt**, chỉ khác Bước 1 và 2.

**Cấu trúc bản ghi DNS cần tạo**

| Type | Name | Value | TTL |
|---|---|---|---|
| `A` | `api` | `13.210.134.235` | `300` |

Kết quả: `api.quickbite.com` trỏ về VPS.

**Giải thích**

| Muốn địa chỉ là | Điền ô **Name** |
|---|---|
| `api.quickbite.com` | `api` |
| `quickbite.com` | `@` |
| `www.quickbite.com` | `www` |

> 💡 **Đặt TTL `300` khi mới cấu hình.** Gõ nhầm IP còn kịp sửa trong 5 phút. Ổn định rồi hãy nâng lên.

**Lệnh** — các bước còn lại y hệt, chỉ thay tên miền

```bash
dig +short api.quickbite.com @8.8.8.8
```
```bash
sudo certbot --nginx -d api.quickbite.com
```

**Ví dụ** — xin một chứng chỉ cho nhiều tên cùng lúc

```bash
sudo certbot --nginx -d quickbite.com -d www.quickbite.com
```

> ⚠️ **Mọi tên trong lệnh đều phải đã trỏ DNS về VPS này.** Chỉ cần một tên chưa trỏ là cả lệnh thất bại.

---

# PHỤ LỤC B · BẢNG TRA NHANH

| Việc | Lệnh |
|---|---|
| Xem IP public của VPS | `curl -s ifconfig.me; echo` |
| Kiểm tra DNS | `dig +short <tên-miền> @8.8.8.8` |
| Mở cổng | `sudo ufw allow 80/tcp && sudo ufw allow 443/tcp` |
| Kiểm tra cấu hình Nginx | `sudo nginx -t && sudo systemctl reload nginx` |
| Cài Certbot | `sudo apt install certbot python3-certbot-nginx -y` |
| **Chạy thử, không tiêu hạn mức** | `sudo certbot certonly --nginx -d <tên-miền> --dry-run` |
| Xin chứng chỉ | `sudo certbot --nginx -d <tên-miền>` |
| Xem chứng chỉ đang có | `sudo certbot certificates` |
| Thử gia hạn | `sudo certbot renew --dry-run` |
| Xoá một chứng chỉ | `sudo certbot delete --cert-name <tên-miền>` |

---

# PHỤ LỤC C · BẢNG LỖI

| Triệu chứng | Nguyên nhân | Sửa |
|---|---|---|
| `dig` không ra gì | Chưa bấm `update ip`, hoặc chưa lan truyền | Đợi 1 phút, kiểm tra lại trang DuckDNS |
| `curl http://<tên-miền>` ra `000` | Cổng 80 chưa mở ở **một trong hai** lớp tường lửa | Mở cả UFW **và** Security Group |
| `DNS problem: NXDOMAIN looking up A` | Tên miền chưa trỏ, hoặc gõ sai | Làm lại Bước 3 cho ra đúng IP |
| `Timeout during connect (likely firewall problem)` | **Cổng 80 bị chặn** | Bước 4 |
| `too many failed authorizations` | Chạy Certbot liên tục khi DNS chưa đúng | **Đợi 1 tiếng.** Lần sau dùng `--dry-run` |
| `could not find a matching server block` | Chưa đổi `server_name` | Bước 5 |
| `unauthorized :: Invalid response from .../.well-known/...` | Nginx trả 404 cho đường dẫn xác thực | `server_name` chưa khớp, hoặc site mặc định đang nuốt request |
| `certbot plugins` không thấy `nginx` | Thiếu gói plugin | `sudo apt install python3-certbot-nginx -y` |
| Trình duyệt vẫn báo không an toàn | Còn trỏ chứng chỉ tự ký cũ | `sudo nginx -T \| grep ssl_certificate` xem đang trỏ đâu |
| Sau 90 ngày website chết | Cổng 80 bị chặn nên không gia hạn được | Mở lại 80 rồi `sudo certbot renew` |
| Tên miền DuckDNS bị trùng | Người khác đã lấy | Thêm tên hoặc mã sinh viên vào sau |

---

# ✅ CHECKLIST

**Trước khi chạy Certbot — đủ 5 dấu tick mới chạy**

- [ ] `dig +short <tên-miền> @8.8.8.8` ra **đúng IP VPS**
- [ ] Cổng **80** mở ở UFW **và** Security Group
- [ ] Cổng **443** mở ở cả hai nơi
- [ ] `curl http://<tên-miền>/api/v1/users` ra `200`
- [ ] `server_name` trong `quickbite.conf` đã đổi thành tên miền

**Sau khi có chứng chỉ**

- [ ] `curl https://<tên-miền>/api/v1/users` chạy **không cần `-k`**
- [ ] Trình duyệt hiện **ổ khoá đóng**
- [ ] `http://` tự chuyển `301` sang `https://`
- [ ] `sudo certbot renew --dry-run` thành công
- [ ] `sudo certbot certificates` hiện ngày hết hạn
- [ ] **Không chặn cổng 80** sau khi xong

<div class="keybox">
<span class="lbl">Điều cần nhớ nhất</span>
<p><strong>HTTPS không tốn tiền. Thứ tốn tiền là cái tên đẹp.</strong></p>
<p>Và nếu bạn chỉ cần nộp bài tập hay demo đồ án, <strong>cái tên miễn phí là quá đủ</strong>.</p>
</div>
