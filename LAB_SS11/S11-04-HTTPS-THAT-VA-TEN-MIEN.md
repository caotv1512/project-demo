# HƯỚNG DẪN BỔ SUNG — SESSION 11
# Có HTTPS thật: trước và sau khi mua tên miền

> **File này dùng sau khi đã làm xong BÀI 1–4.** Nó trả lời đúng một câu hỏi: *"Hết buổi học rồi, em có HTTPS thật được chưa, hay bắt buộc phải mua tên miền?"*

> **Ví dụ xuyên suốt:** server có IP `13.210.134.235`. **Thay bằng IP máy của bạn** ở mọi lệnh.

> ⚠️ **Mức độ kiểm chứng.** Bài lab Session 11 đã chạy thật 62/62 lệnh. File này thì **không kiểm chứng tự động được**, vì nó cần một IP public và một tên miền. Những gì tôi **đã đo được** sẽ ghi rõ bằng ✅; phần còn lại dựa trên tài liệu chính thức và **bạn nên làm thử một lượt trước khi đứng lớp**.

---

# A · TRẢ LỜI THẲNG: CÓ HTTPS ĐƯỢC CHƯA?

**Có — và không cần mua gì cả.** Nhưng phải hiểu đúng vì sao.

| Bạn muốn | Cần tên miền? | Trình duyệt có tin? | Chi phí |
|---|---|---|---|
| HTTPS **có cảnh báo** (chứng chỉ tự ký, như BÀI 4) | ❌ Không | ❌ Hiện cảnh báo đỏ | 0đ |
| HTTPS **thật, không cảnh báo** | ✅ **Có** — nhưng **lấy miễn phí được** | ✅ Tin | **0đ** |
| HTTPS với tên miền riêng của bạn | ✅ Có — phải mua | ✅ Tin | ~200–300k/năm |

> 💡 **Mấu chốt nằm ở chỗ này:** HTTPS thật cần một **tên miền**, nhưng **"có tên miền" không đồng nghĩa với "mua tên miền"**. Có những dịch vụ cho bạn một tên miền con **miễn phí, dùng được ngay**, và Let's Encrypt cấp chứng chỉ cho nó bình thường.

## A1. Vì sao Let's Encrypt không cấp chứng chỉ cho địa chỉ IP

Chứng chỉ TLS chứng minh *"máy chủ này đúng là chủ của **cái tên** đó"*. Quy trình xác thực của Let's Encrypt là:

1. Bạn nói: *"tôi muốn chứng chỉ cho `api.quickbite.com`"*
2. Let's Encrypt **tra DNS** xem tên đó trỏ về IP nào
3. Nó **gọi ngược về** `http://api.quickbite.com/.well-known/acme-challenge/...`
4. Nếu nhận đúng chuỗi mà nó yêu cầu Certbot đặt ở đó → cấp chứng chỉ

> ⚠️ **Với địa chỉ IP, bước 2 không tồn tại** — không có DNS nào để tra, và IP có thể bị nhà cung cấp thu hồi rồi cấp cho người khác bất cứ lúc nào. Vì vậy theo truyền thống, **Let's Encrypt chỉ cấp cho tên miền**.
>
> 📌 **Lưu ý:** Let's Encrypt gần đây đã bắt đầu thử nghiệm cấp chứng chỉ cho **địa chỉ IP** với thời hạn rất ngắn. Tính năng này còn mới, nhiều công cụ chưa hỗ trợ, và **không phù hợp cho lớp học**. Nếu quan tâm, hãy kiểm tra trạng thái hiện tại trên trang chủ Let's Encrypt. Tài liệu này đi theo con đường **tên miền**, vì nó ổn định và dạy đúng nguyên lý.

## A2. Tên miền EC2 mặc định có dùng được không?

Máy của bạn đã có sẵn một tên miền do AWS cấp:

```
ec2-13-210-134-235.ap-southeast-2.compute.amazonaws.com
```

> ⚠️ **Không dùng được để xin chứng chỉ.** Tên đó thuộc quyền quản lý của AWS, bạn **không tạo được bản ghi DNS** cho nó, và các nhà cấp chứng chỉ hạn chế cấp cho những tên miền dùng chung kiểu này. Đừng mất thời gian thử.

## A3. Ba con đường, chọn theo hoàn cảnh

| | **Đường 1** — Chứng chỉ tự ký | **Đường 2** — Tên miền con miễn phí | **Đường 3** — Mua tên miền |
|---|---|---|---|
| Thời gian | 2 phút | ~15 phút | ~20 phút + đợi DNS |
| Chi phí | 0đ | **0đ** | ~200–300k/năm |
| Trình duyệt tin | ❌ Cảnh báo đỏ | ✅ **Tin** | ✅ Tin |
| Địa chỉ trông thế nào | `https://13.210.134.235` | `https://quickbite-an.duckdns.org` | `https://api.quickbite.com` |
| Dùng cho | Học, nội bộ | **Bài tập, đồ án, demo** | Sản phẩm thật |
| Hướng dẫn | BÀI 4 trong file lab | **Phần B** bên dưới | **Phần C** bên dưới |

---

# B · TRƯỚC KHI MUA TÊN MIỀN — CÓ HTTPS THẬT, MIỄN PHÍ

## B1. Chọn dịch vụ nào — và một chi tiết quyết định

Có hai nhóm dịch vụ cho tên miền con miễn phí:

| Nhóm | Ví dụ | Cách hoạt động |
|---|---|---|
| **Wildcard DNS** | `nip.io`, `sslip.io` | `13.210.134.235.nip.io` **tự động** trỏ về `13.210.134.235`. Không cần đăng ký gì |
| **Dịch vụ DNS động** | `duckdns.org`, No-IP, FreeDNS | Đăng ký tài khoản, tự chọn tên, tự trỏ IP |

✅ **Tôi đã kiểm chứng cả hai nhóm đều phân giải đúng:**

```
13.210.134.235.nip.io     ->  13.210.134.235
13.210.134.235.sslip.io   ->  13.210.134.235
```

**Nhưng có một chi tiết khiến tôi khuyên dùng DuckDNS cho lớp học.**

✅ Tôi đã tra **Public Suffix List** — danh sách mà Let's Encrypt dùng để tính hạn mức cấp chứng chỉ:

| Dịch vụ | Có trong Public Suffix List? | Hệ quả |
|---|---|---|
| `duckdns.org` | ✅ **Có** | Mỗi tên con có **hạn mức riêng** |
| `nip.io` | ❌ Không | **Cả thế giới dùng chung một hạn mức** |
| `sslip.io` | ❌ Không | **Cả thế giới dùng chung một hạn mức** |

> ⚠️ **Đây là lý do rất thực tế.** Let's Encrypt giới hạn số chứng chỉ cấp cho mỗi **tên miền đã đăng ký** mỗi tuần. Vì `nip.io` không nằm trong Public Suffix List, **toàn bộ người dùng `nip.io` trên thế giới chia nhau một hạn mức**. Một lớp 30 sinh viên cùng xin chứng chỉ `nip.io` rất dễ gặp lỗi `too many certificates already issued` — và lúc đó **phải đợi cả tuần**.
>
> `duckdns.org` nằm trong danh sách đó, nên mỗi `ten-cua-ban.duckdns.org` được tính **riêng**. An toàn hơn hẳn cho lớp học.

| Chọn gì | Khi nào |
|---|---|
| **DuckDNS** | **Mặc định nên chọn** — nhất là khi cả lớp cùng làm |
| `sslip.io` | Chỉ demo nhanh một mình, không cần đăng ký. Chấp nhận rủi ro hạn mức |

## B2. Đường nhanh nhất — `sslip.io`, không cần đăng ký gì

Dùng khi bạn chỉ muốn thử trong 5 phút.

**Bước 1 — kiểm tra tên miền đã trỏ đúng chưa** (làm từ máy bạn):

```bash
dig +short 13.210.134.235.sslip.io
```

**Phải thấy:** chính IP đó. Không cần làm gì thêm — dịch vụ này tự động.

**Bước 2 — mở cổng 80 và 443.** Trên AWS phải mở ở **cả hai nơi**:

```
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw status verbose
```

Và **EC2 → Security Group → Edit inbound rules** → thêm `HTTP (80)` và `HTTPS (443)`, source `0.0.0.0/0`.

> ⚠️ **Cổng 80 bắt buộc phải mở ra Internet.** Let's Encrypt xác thực bằng cách gọi vào `http://<tên-miền>/.well-known/...`. Chặn cổng 80 là không xin được chứng chỉ — và sau này cũng **không tự gia hạn được**.

**Bước 3 — sửa `server_name` trong cấu hình Nginx:**

```
sudo nano /etc/nginx/conf.d/quickbite.conf
```

```nginx
server_name 13.210.134.235.sslip.io;
```

```
sudo nginx -t && sudo systemctl reload nginx
```

**Bước 4 — xin chứng chỉ:**

```
sudo apt update && sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d 13.210.134.235.sslip.io
```

Nhảy tới **B4** để xem cần trả lời gì khi Certbot hỏi.

## B3. Đường ổn định hơn — DuckDNS

**Bước 1 — đăng ký.** Vào `duckdns.org`, đăng nhập bằng tài khoản Google/GitHub. Không cần thẻ, không cần email riêng.

**Bước 2 — tạo tên miền con.** Gõ tên bạn muốn (ví dụ `quickbite-an`) rồi bấm **add domain**. Bạn được `quickbite-an.duckdns.org`.

**Bước 3 — trỏ về IP VPS.** Điền IP vào ô **current ip** rồi bấm **update ip**.

**Bước 4 — kiểm tra từ máy bạn:**

```bash
dig +short quickbite-an.duckdns.org
```

**Phải thấy:** IP VPS của bạn. Nếu chưa ra, đợi 1–2 phút rồi thử lại.

> 💡 **DuckDNS lan truyền rất nhanh** — thường dưới một phút, vì thời gian lưu đệm DNS của nó rất ngắn. Tên miền mua ở nhà cung cấp thường lâu hơn nhiều (xem C3).

**Bước 5 — mở cổng** (giống B2 bước 2), **sửa `server_name`** thành `quickbite-an.duckdns.org`, rồi sang B4.

## B4. Chạy Certbot — và trả lời đúng các câu hỏi

```
sudo apt update && sudo apt install certbot python3-certbot-nginx -y
```
```
sudo certbot --nginx -d quickbite-an.duckdns.org
```

Certbot sẽ hỏi vài câu:

| Câu hỏi | Trả lời |
|---|---|
| `Enter email address` | Email thật của bạn — dùng để báo khi chứng chỉ sắp hết hạn |
| `Please read the Terms of Service... (Y)es/(N)o` | `Y` |
| `Would you be willing to share your email with EFF?` | `N` cũng được, không ảnh hưởng gì |

**Phải thấy:**

```
Requesting a certificate for quickbite-an.duckdns.org
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/quickbite-an.duckdns.org/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/quickbite-an.duckdns.org/privkey.pem
This certificate expires on 20XX-XX-XX.
Deploying certificate to VirtualHost /etc/nginx/conf.d/quickbite.conf
Congratulations! You have successfully enabled HTTPS
```

> 💡 **Certbot vừa tự sửa file cấu hình của bạn.** Mở ra xem — nó thêm `listen 443 ssl`, trỏ `ssl_certificate` tới `/etc/letsencrypt/live/...`, thêm `include options-ssl-nginx.conf` và `ssl_dhparam`, rồi tạo một khối `server` cổng 80 để chuyển hướng.
>
> Cấu trúc giống file `03-quickbite-https.conf` bạn viết tay ở BÀI 4, nhưng **Certbot viết redirect bằng `if ($host = ...)`** thay vì `return 301` thẳng. **Mọi dòng nó thêm đều có chú thích `# managed by Certbot`** — đừng sửa tay, lần gia hạn sau sẽ bị ghi đè.

```
sudo nginx -T | grep -A3 'ssl_certificate'
```

## B5. Kiểm chứng HTTPS thật

```bash
curl https://quickbite-an.duckdns.org/api/v1/users
```

> ✅ **Không cần cờ `-k` nữa** — đó chính là bằng chứng chứng chỉ **hợp lệ**. Ở BÀI 4 ta phải dùng `-k` vì chứng chỉ tự ký; giờ thì không.

```bash
curl -s -o /dev/null -w 'HTTP  -> %{http_code} | chuyen toi: %{redirect_url}\n' http://quickbite-an.duckdns.org/api/v1/users
```

**Phải thấy:** `301` và địa chỉ `https://...`

**Mở trình duyệt** và vào `https://quickbite-an.duckdns.org/api/v1/users`.

> ✅ **Phải thấy ổ khoá đóng** trên thanh địa chỉ, **không có cảnh báo đỏ**. Bấm vào ổ khoá → `Certificate is valid` → do **R10/R11 của Let's Encrypt** cấp. Đây là khoảnh khắc đáng chiếu lên lớp.

**Kiểm tra tự động gia hạn:**

```
sudo certbot renew --dry-run
```

**Phải thấy:** `Congratulations, all simulated renewals succeeded!`

---

# C · SAU KHI MUA TÊN MIỀN

## C1. Mua ở đâu, giá bao nhiêu

| Nhà cung cấp | Đặc điểm |
|---|---|
| **Cloudflare Registrar** | Bán đúng giá gốc, không đội giá năm sau. Phải chuyển DNS sang Cloudflare |
| **Namecheap**, **Porkbun** | Giá tốt, giao diện dễ dùng |
| **Nhà cung cấp Việt Nam** (Mắt Bão, PA, Tenten…) | Hỗ trợ tiếng Việt, thanh toán nội địa, mua `.vn` được |

| Đuôi tên miền | Giá tham khảo mỗi năm |
|---|---|
| `.com` | ~250–350k |
| `.dev`, `.app` | ~300–400k — **bắt buộc HTTPS**, trình duyệt tự ép |
| `.xyz`, `.site` | Có khi chỉ ~30–50k năm đầu |
| `.vn` | Cao hơn, cần giấy tờ |

> ⚠️ **Đọc kỹ giá gia hạn, không chỉ giá năm đầu.** Rất nhiều nơi bán năm đầu 30k rồi gia hạn 400k. Mục cần tìm là **renewal price**.

## C2. Tạo bản ghi DNS

Vào trang quản lý tên miền, tìm mục **DNS** / **DNS Records** / **Quản lý DNS**, rồi thêm:

| Type | Name | Value | TTL |
|---|---|---|---|
| `A` | `api` | `13.210.134.235` | `300` (hoặc Auto) |

Kết quả: `api.quickbite.com` trỏ về VPS của bạn.

| Muốn địa chỉ là | Điền ô **Name** |
|---|---|
| `api.quickbite.com` | `api` |
| `quickbite.com` (tên miền gốc) | `@` |
| `www.quickbite.com` | `www` |

> 💡 **Đặt TTL thấp (300 giây) khi mới cấu hình.** TTL là thời gian các máy chủ DNS khác được phép nhớ kết quả cũ. Để 300 thì sửa sai còn kịp đổi lại trong 5 phút; để 86400 (một ngày) thì gõ nhầm IP là chịu trận cả ngày. Khi mọi thứ ổn định rồi hãy nâng lên.

## C3. Đợi DNS lan truyền — và cách kiểm tra cho đúng

```bash
dig +short api.quickbite.com
```

**Phải thấy:** IP VPS của bạn.

> ⚠️ **Đừng dùng `ping` để kiểm tra DNS.** Máy bạn có thể đã **lưu đệm** kết quả cũ, hoặc nhà mạng trả về bản ghi cũ. `dig` cho bạn thấy chính xác hơn, và bạn còn hỏi thẳng được một máy chủ DNS công cộng:

```bash
dig +short api.quickbite.com @8.8.8.8
```

| Kết quả | Nghĩa |
|---|---|
| Ra đúng IP | ✅ Chạy tiếp được |
| **Không ra gì** | Chưa lan truyền, hoặc gõ sai bản ghi |
| Ra **IP khác** | Có bản ghi cũ trùng tên — xoá nó đi |

> 💡 **Lan truyền DNS mất bao lâu?** Thường **5–30 phút**, đôi khi tới vài giờ. Trong lúc đợi, cứ chạy `dig` lại mỗi vài phút. **Đừng chạy Certbot khi `dig` chưa ra đúng IP** — mỗi lần thất bại đều tính vào hạn mức (xem phần D).

## C4. Đổi cấu hình Nginx và xin chứng chỉ

```
sudo nano /etc/nginx/conf.d/quickbite.conf
```

```nginx
server_name api.quickbite.com;
```

```
sudo nginx -t && sudo systemctl reload nginx
```

**Kiểm tra Nginx đã nhận tên miền mới chưa — làm trước khi gọi Certbot:**

```bash
curl -s -o /dev/null -w 'HTTP qua ten mien: %{http_code}\n' http://api.quickbite.com/api/v1/users
```

**Phải thấy:** `200` (hoặc `301` nếu bạn đã có HTTPS từ phần B).

> ⚠️ **Nếu bước này chưa chạy được thì Certbot cũng sẽ thất bại**, vì nó dùng đúng đường đi này để xác thực. Sửa cho `curl` chạy trước đã.

```
sudo certbot --nginx -d api.quickbite.com
```

Muốn cả tên miền gốc và `www` trong **một** chứng chỉ:

```
sudo certbot --nginx -d quickbite.com -d www.quickbite.com
```

> 💡 **Mỗi `-d` thêm một tên vào cùng một chứng chỉ.** Nhưng **mọi tên đều phải đã trỏ DNS về VPS này** — chỉ cần một tên chưa trỏ là cả lệnh thất bại.

## C5. Chuyển từ tên miền tạm sang tên miền thật

Nếu bạn đã làm phần B với DuckDNS rồi giờ mới mua tên miền:

```bash
sudo certbot certificates
```

Lệnh này liệt kê các chứng chỉ đang có. Giờ xin thêm cho tên miền mới:

```
sudo certbot --nginx -d api.quickbite.com
```

Khi chắc chắn tên miền mới chạy ổn, **xoá chứng chỉ cũ** cho gọn:

```
sudo certbot delete --cert-name quickbite-an.duckdns.org
```

> 💡 **Không cần xoá ngay.** Giữ cả hai vài ngày cũng được — Nginx chọn chứng chỉ theo `server_name`, chúng không giẫm chân nhau. Chỉ xoá khi bạn chắc không còn ai dùng địa chỉ cũ.

---

# D · GIỚI HẠN CỦA LET'S ENCRYPT — BIẾT TRƯỚC ĐỂ KHÔNG VẤP

| Giới hạn | Con số tham khảo | Ý nghĩa thực tế |
|---|---|---|
| Chứng chỉ mỗi tên miền đã đăng ký / tuần | ~50 | Lý do `nip.io` dễ hết hạn mức (xem B1) |
| Chứng chỉ **trùng lặp** / tuần | ~5 | Xin đi xin lại cùng một tên là hết |
| **Xác thực thất bại** / giờ | ~5 | **Đây là cái hay vấp nhất** |
| Thời hạn chứng chỉ | **90 ngày** | Certbot tự gia hạn trước 30 ngày |

> ⚠️ **Giới hạn "xác thực thất bại" là thứ làm hỏng buổi học.** Nếu DNS chưa trỏ đúng mà bạn chạy Certbot liên tục, chỉ sau 5 lần là **bị khoá một tiếng** — và cả lớp phải ngồi chờ.
>
> **Phòng tránh:** luôn làm đúng thứ tự **`dig` ra đúng IP → `curl` qua tên miền ra `200` → rồi mới chạy Certbot**.
>
> **Và khi cần thử nhiều lần, dùng môi trường thử nghiệm:**
> ```
> sudo certbot certonly --nginx -d api.quickbite.com --dry-run
> ```
> `--dry-run` chạy toàn bộ quy trình thật nhưng **không tiêu hạn mức** và không cấp chứng chỉ thật. Dùng nó để kiểm tra cấu hình, rồi mới chạy lệnh thật.

> 📌 **Các con số trên có thể thay đổi.** Hãy tra lại trang Rate Limits của Let's Encrypt khi cần con số chính xác.

---

# E · PHƯƠNG ÁN THAY THẾ: CADDY TỰ LO HTTPS

Nếu bạn thấy Certbot rườm rà, **Caddy** là một reverse proxy khác **tự xin và tự gia hạn chứng chỉ** mà không cần cấu hình gì thêm.

✅ **Tôi đã kiểm chứng Caddy có sẵn trong kho Ubuntu 24.04** (phiên bản 2.6.2), nên cài rất nhanh:

```
sudo apt install caddy -y
```

Toàn bộ cấu hình tương đương cả file Nginx của BÀI 4 gói trong **ba dòng** `/etc/caddy/Caddyfile`:

```
api.quickbite.com {
    reverse_proxy 127.0.0.1:8080
}
```

```
sudo systemctl reload caddy
```

Caddy tự xin chứng chỉ Let's Encrypt, tự bật HTTPS, tự redirect HTTP → HTTPS, tự gia hạn.

| | **Nginx + Certbot** | **Caddy** |
|---|---|---|
| Dòng cấu hình cho ví dụ này | ~25 | **3** |
| HTTPS | Phải chạy Certbot | **Tự động** |
| Gia hạn | Certbot timer | **Tự động** |
| Phổ biến ở công ty | ✅ **Rất phổ biến** | Đang tăng |
| Tài liệu, câu hỏi trên mạng | Rất nhiều | Ít hơn |
| Học được gì về cơ chế | **Nhiều** — bạn thấy từng mảnh | Ít — nó giấu đi |

> 💡 **Vì sao buổi học vẫn dạy Nginx?** Vì hai lý do. Thứ nhất, **Nginx phổ biến hơn rất nhiều** — đi làm bạn sẽ phải đọc cấu hình Nginx của người khác. Thứ hai, Caddy **giấu mất** chính những thứ ta cần học: khối `server`, `location`, SSL termination, redirect 301.
>
> **Học Nginx trước, rồi dùng Caddy khi cần nhanh** — lúc đó bạn hiểu nó đang làm gì thay mình.

---

# F · CHECKLIST

**Trước khi chạy Certbot — làm đủ mới chạy**

- [ ] `dig +short <ten-mien>` ra **đúng IP VPS**
- [ ] Cổng **80** mở ở UFW **và** 🌐 ở Security Group của AWS
- [ ] Cổng **443** mở ở cả hai nơi
- [ ] `server_name` trong `quickbite.conf` đã đổi thành tên miền
- [ ] `sudo nginx -t` đạt và đã `reload`
- [ ] `curl http://<ten-mien>/api/v1/users` ra `200` hoặc `301`
- [ ] *(nếu thử nhiều lần)* Dùng `--dry-run` trước

**Sau khi có chứng chỉ**

- [ ] `curl https://<ten-mien>/api/v1/users` chạy **không cần `-k`**
- [ ] Trình duyệt hiện **ổ khoá đóng**, không cảnh báo
- [ ] `http://` tự chuyển `301` sang `https://`
- [ ] `sudo certbot renew --dry-run` thành công
- [ ] **Không chặn cổng 80** sau khi có HTTPS (cần cho gia hạn)
- [ ] Email trong Certbot là email thật, để nhận cảnh báo hết hạn

---

# G · BẢNG LỖI

| Triệu chứng | Nguyên nhân thường gặp | Sửa |
|---|---|---|
| `DNS problem: NXDOMAIN looking up A for ...` | Tên miền chưa trỏ, hoặc gõ sai | `dig +short <ten-mien>` trước |
| `Timeout during connect (likely firewall problem)` | **Cổng 80 bị chặn** | Mở ở UFW **và** Security Group |
| `too many certificates already issued` | Hết hạn mức — hay gặp với `nip.io` | Đổi sang **DuckDNS**, hoặc đợi hết tuần |
| `too many failed authorizations` | Chạy Certbot liên tục khi DNS chưa đúng | Đợi một tiếng; lần sau dùng `--dry-run` |
| `--dry-run currently only works with the 'certonly' or 'renew' subcommands` | Thiếu chữ `certonly` | `certbot certonly --nginx -d <ten-mien> --dry-run` |
| `unauthorized :: Invalid response from http://.../.well-known/...` | Nginx trả 404 cho đường dẫn xác thực | `server_name` chưa khớp, hoặc site mặc định đang nuốt request |
| Trình duyệt vẫn báo không an toàn | Còn dùng chứng chỉ tự ký cũ | `sudo nginx -T \| grep ssl_certificate` xem đang trỏ đâu |
| Chứng chỉ hết hạn sau 90 ngày | Cổng 80 bị chặn nên không gia hạn được | Mở lại 80, `sudo certbot renew` |
| `dig` ra IP cũ dù đã sửa | TTL cao, còn bộ nhớ đệm | Hỏi thẳng `@8.8.8.8`, hoặc đợi hết TTL |
| Certbot sửa file xong Nginx không khởi động | Xung đột với khối `server` bạn viết tay | `sudo nginx -t` đọc lỗi; gỡ khối trùng |
| 🌐 Mua tên miền xong vẫn không trỏ được | Tên miền đang dùng DNS của nhà cung cấp khác | Kiểm tra **nameserver** đang trỏ về đâu |

---

# H · TÓM TẮT CHO HỌC VIÊN

| Hoàn cảnh của bạn | Làm gì |
|---|---|
| Chỉ cần chạy thử, không ngại cảnh báo | Chứng chỉ tự ký — **BÀI 4** trong file lab |
| Cần nộp bài tập / demo có HTTPS thật, **không có tiền** | **DuckDNS** — phần **B3** |
| Thử nhanh một mình trong 5 phút | **sslip.io** — phần **B2** |
| Làm sản phẩm thật | **Mua tên miền** — phần **C** |
| Muốn HTTPS mà ngại cấu hình | **Caddy** — phần **E** |

<div class="keybox">
<span class="lbl">Điều cần nhớ nhất</span>
<p><strong>HTTPS thật không tốn tiền. Thứ tốn tiền là cái tên đẹp.</strong></p>
<p>Let's Encrypt cấp chứng chỉ miễn phí cho bất kỳ tên miền nào bạn chứng minh được quyền sở hữu — kể cả tên miền con xin miễn phí.</p>
</div>
