# TÀI LIỆU SINH VIÊN — SESSION 10
# Triển khai Hệ thống lên VPS

> **Tài liệu này để đọc hiểu.** Bảng lệnh đầy đủ kèm 4 thí nghiệm gây lỗi nằm ở file **`S10-02-Lab-thuc-hanh.html`**.

---

# Buổi này là buổi gì?

Tám buổi trước ta làm việc với **máy của mình** và **máy của GitHub**. Hôm nay lần đầu tiên ta làm việc với **một máy chủ thật, có địa chỉ công khai, chạy suốt ngày đêm, và thuộc trách nhiệm của ta**.

<div class="keybox">
<span class="lbl">Một câu để nhớ cả buổi</span>
<p><strong>Session 08 dạy cách đóng gói. Session 10 dạy cách giữ cho nó sống và không bị chiếm.</strong></p>
</div>

## Session 08 → Session 10

| | Session 08 | **Session 10** |
|---|---|---|
| Câu hỏi | *"Giao sản phẩm cho người khác thế nào?"* | *"Dựng nó lên và giữ cho nó sống thế nào?"* |
| Sản phẩm cuối | **Image** nằm trên Registry | **Hệ thống đang chạy** trên máy chủ có IP public |
| Máy đích | Runner GitHub — **dùng xong là xoá** | **VPS của bạn** — tồn tại lâu dài |
| Ai vá lỗi, ai lo bảo mật | GitHub | **Bạn** |
| Ai nhìn thấy máy đó | Không ai | **Cả Internet** |
| Compose dùng gì | — | **`image:`** thay cho `build:` |

> **Mối liên hệ giữa hai buổi:** chính nhờ Session 08 đã đẩy image lên Registry mà hôm nay VPS **không cần cài Java, không cần Gradle, không cần mã nguồn**. Nó chỉ `docker compose pull` rồi `up -d`.

## Vì sao VPS khác mọi thứ ta từng dùng

Runner của GitHub sống vài phút rồi bị xoá. Hỏng thì chạy lại workflow. VPS thì khác:

- Nó **tồn tại mãi** cho tới khi bạn trả máy
- Nó có **IP công khai** — và **ngay giây phút được tạo ra, nó đã bị quét**
- Sai cấu hình SSH là **bạn không vào được nữa**

> ⚠️ Các bot dò cổng 22 và thử mật khẩu phổ biến **liên tục, cả ngày lẫn đêm**. Đây không phải chuyện doạ: mở log SSH của một VPS mới sau vài giờ là thấy hàng trăm lượt thử đăng nhập. Đó là lý do phần bảo mật SSH **không phải bài học tuỳ chọn**.

---

# Phần 1 — Máy chủ mới về thì làm gì

## `apt update` và `apt upgrade` khác nhau thế nào

Hai lệnh này hay bị gõ như một cặp mà không hiểu vì sao phải có cả hai:

| Lệnh | Làm gì | Có cài gì không |
|---|---|---|
| `apt update` | Hỏi các kho phần mềm *"ngoài kia đang có phiên bản nào?"* rồi ghi lại danh mục | **Không** |
| `apt upgrade` | Tải về và cài các bản mới theo danh mục đó | **Có** |

> 💡 Chạy `upgrade` mà quên `update` nghĩa là bạn đang nâng cấp dựa trên **danh mục cũ**. Có bản vá bảo mật vừa ra cũng không thấy.

## Vì sao phải kiểm tra `reboot-required`

Khi nhân Linux được vá, **máy vẫn đang chạy nhân cũ** cho tới lần khởi động lại. Nghĩa là bản vá đã tải về nhưng **chưa có tác dụng**. Hệ thống đánh dấu điều này bằng file `/var/run/reboot-required`.

## Đọc tài nguyên máy chủ để làm gì

| Số liệu | Vì sao cần biết |
|---|---|
| RAM | Container Java của QuickBite ăn ~**300 MB**, PostgreSQL ~**90 MB** |
| CPU | Quyết định chạy được bao nhiêu service |
| Đĩa | Image Docker và log tích lại rất nhanh |

> ⚠️ Khi hết RAM, Linux **giết tiến trình ngốn nhiều nhất** — thường chính là ứng dụng của bạn. Lỗi đó hiện ra dưới tên **Exit code 137**, và phần lớn trường hợp nguyên nhân là **máy chủ quá nhỏ**, không phải code bị rò rỉ bộ nhớ.

---

# Phần 2 — Chỉ mình bạn vào được máy chủ

## Khoá công khai và khoá riêng — hiểu bằng một hình ảnh

Hãy coi **khoá công khai** là một **ổ khoá**, còn **khoá riêng** là **chìa**.

- Bạn gắn **ổ khoá** lên cửa máy chủ. Việc này công khai, ai nhìn thấy cũng không sao.
- **Chìa** nằm trong túi bạn. Không ai mượn.
- Lúc đăng nhập, máy chủ **không hỏi chìa**. Nó ra một câu đố mà **chỉ người cầm chìa mới giải được**, rồi kiểm tra lời giải.

<div class="keybox">
<span class="lbl">Điểm mấu chốt</span>
<p>Khoá riêng <strong>không bao giờ rời khỏi máy bạn</strong>, kể cả lúc đang đăng nhập.</p>
<p>Mật khẩu thì ngược lại — nó <strong>phải được gửi đi</strong> mỗi lần. Đó là lý do mật khẩu bị dò được, còn khoá thì không.</p>
</div>

| | Mật khẩu | SSH key |
|---|---|---|
| Có bị gửi qua mạng không | **Có**, mỗi lần | **Không bao giờ** |
| Bot dò được không | **Có** | Không |
| Dùng lại nhiều nơi | Người ta hay dùng lại → lộ một nơi là lộ hết | Mỗi máy chủ một ổ khoá riêng |
| Bị lộ thì xử lý sao | Đổi mật khẩu, không biết ai đã dùng | Xoá một dòng trong `authorized_keys` |

**Hai file được tạo ra, và chúng đi hai hướng khác nhau:**

| File | Là gì | Đi đâu |
|---|---|---|
| `quickbite_vps_ed25519` | **Khoá riêng** | **Ở LẠI máy bạn, vĩnh viễn** |
| `quickbite_vps_ed25519.pub` | **Khoá công khai** | Chép lên VPS |

> ⚠️ Chỉ chép file có đuôi `.pub`. Khoá riêng không gửi qua chat, không upload lên VPS, không commit vào Git. Ai cầm được nó là vào được máy chủ của bạn.

## Vì sao không dùng thẳng `root`

`root` **không có phanh**. Gõ nhầm một lệnh xoá là mất máy. `sudo` buộc bạn **dừng lại nửa giây và gõ mật khẩu** trước mỗi hành động nguy hiểm.

Và `sudo` còn làm một việc mà root thuần không làm được: **ghi lại nhật ký** — ai, lúc nào, lệnh gì. Trên máy chủ nhiều người dùng, nó biến *"ai đó đã xoá thư mục"* thành *"lúc 14:32 tài khoản deployer đã chạy lệnh này"*.

## Nguyên tắc quan trọng nhất: thử trước, khoá sau

Hãy hình dung bạn làm ngược lại — tắt đăng nhập bằng mật khẩu **trước**, rồi mới cài khoá. Nếu dán nhầm public key (thiếu một ký tự, hoặc trình soạn thảo tự xuống dòng):

- Mật khẩu: **đã tắt**
- Khoá: **không khớp**
- Phiên đang mở: nếu đã đóng → **không còn đường nào vào máy**

<div class="keybox">
<span class="lbl">Quy tắc áp dụng cho mọi việc, không riêng SSH</span>
<p>Khi thay đổi <strong>chính cái đường mình đang đứng trên đó</strong>, luôn giữ đường cũ mở cho tới khi đường mới đã được chứng minh là chạy.</p>
</div>

## `sshd -T` — đọc cấu hình đang thật sự chạy

File bạn vừa sửa **chưa chắc là cấu hình đang chạy**. Ubuntu có thư mục `/etc/ssh/sshd_config.d/` chứa các file ghi đè. Có thể bạn sửa `PasswordAuthentication no` mà một file drop-in bật lại thành `yes`.

`sshd -T` in ra **kết quả cuối cùng sau khi gộp tất cả** — đó mới là sự thật.

## Đọc đúng thông báo lỗi của SSH

| Thông báo | Nghĩa | Tìm ở đâu |
|---|---|---|
| `Permission denied (publickey)` | **Gọi tới được**, nhưng không được cho vào | Sai khoá, sai quyền file |
| `Connection timed out` / treo im | **Gói tin không tới được** máy chủ | **Tường lửa**, sai IP, sai cổng |
| `Connection refused` | Tới nơi nhưng **không ai nghe** | Dịch vụ SSH chưa chạy |

> 💡 Phân biệt được ba thông báo này là bạn đã khoanh vùng được quá nửa số sự cố SSH. Chúng chỉ về ba chỗ hoàn toàn khác nhau.

<details class="q"><summary><span>Vì sao `chmod 644` cho `authorized_keys` vẫn đăng nhập được, mà `chmod 666` thì không?</span></summary>

Vì SSH **không quan tâm ai đọc được** file đó — nội dung bên trong vốn là khoá **công khai**, đọc cũng không làm gì được.

SSH chỉ từ chối khi người ngoài **GHI** được, vì ghi được nghĩa là họ **tự thêm khoá của mình vào** rồi vào máy. Tương tự, nếu thư mục `.ssh` là `777` thì người khác **thay được cả file**, nên SSH cũng từ chối.

**Dù vậy vẫn luôn đặt `600`** — đó là thói quen phòng thân, và nhiều công cụ kiểm tra bảo mật sẽ báo lỗi nếu khác.
</details>

<details class="q"><summary><span>Vì sao chọn `ed25519` chứ không phải `rsa`?</span></summary>

| | RSA 2048 | **ed25519** |
|---|---|---|
| Độ dài khoá | ~400 ký tự | **~70 ký tự** |
| Tốc độ | Chậm hơn | **Nhanh hơn** |
| Mức an toàn | Đủ dùng | **Cao hơn** |

Không có lý do thực tế nào để chọn RSA cho máy chủ mới, trừ khi phải nối tới thiết bị rất cũ.
</details>

---

# Phần 3 — Đóng hết, chỉ mở thứ cần

## Vì sao "danh sách cho phép" thắng "danh sách cấm"

Giả sử bạn chọn cách ngược lại: *chặn những cổng nguy hiểm, mở phần còn lại*. Vấn đề là máy chủ có **65.535 cổng**, và mỗi phần mềm cài thêm có thể mở một cổng mới mà bạn không biết. Bạn **không thể liệt kê hết cái xấu**.

Với `default deny incoming`, mọi cổng mới mở ra đều **mặc định không ai gọi vào được**. Bạn chỉ cần nhớ **ba cổng đã mở**, thay vì canh chừng sáu vạn cổng.

| Cổng | Cho ai | Vì sao mở |
|---|---|---|
| 22 (SSH) | Chỉ bạn | Để quản trị máy |
| 80 (HTTP) | Mọi người | Chuyển hướng sang HTTPS |
| 443 (HTTPS) | Mọi người | Nơi người dùng thật truy cập |

> ⚠️ **Phải `ufw allow OpenSSH` TRƯỚC khi `ufw enable`.** Quên dòng này là **tự khoá mình ra khỏi máy chủ ngay lập tức**. Và nếu SSH của bạn chạy ở cổng khác 22, phải mở đúng cổng đó.

## Cái bẫy lớn nhất của cả buổi học

<div class="keybox">
<span class="lbl">Docker đi vòng qua tường lửa</span>
<p>Bạn đã bật UFW chặn hết. Nhưng nếu Compose khai <code>"5432:5432"</code> cho database thì <strong>cổng đó vẫn mở ra Internet</strong>.</p>
<p>Lý do: Docker tạo luật chuyển tiếp ở <strong>tầng thấp hơn</strong> nơi UFW làm việc.</p>
</div>

Ba cách khai `ports` và hậu quả của từng cách:

| Cách viết | Ai gọi được | Dùng khi |
|---|---|---|
| `"8081:8081"` | **Cả Internet** | Dịch vụ thật sự cần công khai |
| `"127.0.0.1:8081:8081"` | Chỉ chính máy chủ đó | Có reverse proxy trên cùng máy |
| *(không khai `ports`)* | Chỉ container cùng mạng | **Database, dịch vụ nội bộ** |

> ⚠️ **Không bao giờ** publish `5432` (PostgreSQL), `3306` (MySQL), `6379` (Redis), `27017` (MongoDB) ra `0.0.0.0`. Rất nhiều vụ lộ dữ liệu bắt đầu đúng từ một dòng `ports` viết ẩu.

## Ba lớp bảo vệ, mỗi lớp chặn một thứ khác nhau

| Lớp | Chặn cái gì | Bị vô hiệu khi |
|---|---|---|
| **SSH key** | Người không có khoá | Bật lại `PasswordAuthentication` |
| **UFW** | Gói tin tới cổng không được phép | Docker publish thẳng ra `0.0.0.0` |
| **`ports` trong Compose** | Dịch vụ không được công bố | Khai `"5432:5432"` |

Ba lớp này **không thay thế nhau**. Thiếu một lớp là có một đường vòng.

## Nhóm `docker` mang quyền rất lớn

> ⚠️ Thêm một tài khoản vào nhóm `docker` **tương đương trao quyền root** cho tài khoản đó. Không phải "gần bằng" — là **tương đương**.

Lý do: Docker daemon chạy bằng quyền root. Thành viên nhóm `docker` ra lệnh được cho daemon, nên chỉ cần một lệnh là **gắn toàn bộ ổ đĩa của máy chủ vào container** rồi sửa bất cứ file nào, kể cả file mật khẩu hệ thống.

**Không bao giờ** thêm tài khoản dùng chung hay tài khoản không tin cậy vào nhóm này.

<details class="q"><summary><span>Vì sao phải cài Docker từ kho của Docker, không dùng gói `docker.io` của Ubuntu?</span></summary>

Gói `docker.io` trong kho Ubuntu thường **cũ hơn vài phiên bản** và không phải bản chính thức, nên có thể thiếu bản vá bảo mật và thiếu plugin như `docker compose`.

Và quan trọng hơn: `apt install` **thành công không chứng minh bạn cài đúng nguồn**. Hãy kiểm tra bằng:

```
apt-cache policy docker-ce
```

Dòng kết quả phải chỉ về `https://download.docker.com/linux/ubuntu`.

> **CE là Community Edition**, không phải "Enterprise". Đây là bản miễn phí, chính thức, dùng cho production được.
</details>

---

# Phần 4 — Dựng hệ thống lên và chứng minh nó sống

## `.env` sống trên máy chủ, không sống trong Git

| File | Chứa gì | Có commit không |
|---|---|---|
| `.env.example` | Chỉ **tên biến** và giá trị mẫu vô hại | ✅ **Có** |
| `.env` | Mật khẩu database, JWT secret, cấu hình production | ❌ **Không bao giờ** |

Kiểm tra Git có thật sự bỏ qua `.env` không — dùng đúng lệnh này:

```
git check-ignore -v .env
```

> 💡 `git status` không thấy `.env` có thể vì nó bị bỏ qua, **cũng có thể** vì bạn đã lỡ commit nó rồi. `git check-ignore -v` chỉ thẳng ra **dòng nào, trong file nào** đang bỏ qua nó.

> ⚠️ **Nếu secret từng bị commit, xoá file đi là chưa đủ.** Nó vẫn nằm trong lịch sử repo và ai cũng xem lại được. Bạn phải **đổi secret đó** (rotate) và xử lý lịch sử repository.

## Vì sao `pull` rồi mới `up -d`

`docker compose pull` là bước **dễ hỏng nhất** (mạng chậm, hết hạn đăng nhập, sai tên image) nhưng lại **vô hại nhất** — nó chỉ tải file về đĩa, **không đụng** tới hệ thống đang chạy.

Nếu `pull` thất bại, dịch vụ cũ vẫn phục vụ khách bình thường. Nếu gộp chung vào `up -d`, hệ thống có thể bị dừng **giữa chừng** rồi mới phát hiện không tải được image mới.

> ⚠️ **Luôn dùng tag cố định** như `1.0.0`, **tránh `latest`**. Dùng `latest` thì mỗi máy pull vào thời điểm khác nhau có thể chạy bản khác nhau, và khi cần quay về bản cũ thì không còn nhãn nào trỏ tới nó.

## Bốn lệnh kiểm tra, mỗi lệnh trả lời một câu khác nhau

| Lệnh | Trả lời câu hỏi |
|---|---|
| `docker compose ps` | Container **đang ở trạng thái nào**? (Up / Exit / Restarting) |
| `docker compose logs` | Ứng dụng **khởi động xong chưa, hỏng ở đâu**? |
| `curl .../actuator/health` | Dịch vụ **sẵn sàng nhận yêu cầu chưa**? |
| `docker stats` | Đang **ăn bao nhiêu CPU và RAM**? |

> ⚠️ Bốn lệnh này **không thay thế nhau**. Container `Up` mà ứng dụng bên trong đã chết — chuyện thường ngày. Chỉ khi `health` trả về `UP` **và** API trả về dữ liệu thật thì mới được kết luận là xong.

## Đọc cột PORTS — nơi nhìn ra lỗ hổng bằng mắt thường

```
NAME                  PORTS
quickbite-prod-db     5432/tcp
quickbite-prod-user   127.0.0.1:8081->8081/tcp
```

| Dòng | Ý nghĩa |
|---|---|
| `5432/tcp` **không có mũi tên** | Database **không có cổng nào ra ngoài** ✅ |
| `127.0.0.1:8081->8081/tcp` | App chỉ nghe trên loopback ✅ |
| `0.0.0.0:5432->5432/tcp` | ❌ **Database đang mở ra Internet** |

> 💡 Vậy người dùng thật vào bằng đường nào? Qua **reverse proxy** (Nginx, Caddy, Traefik) chạy trên cùng máy chủ: nó nghe cổng 443 công khai, nhận HTTPS, rồi chuyển tiếp vào `127.0.0.1:8081`. Nhờ vậy ứng dụng Java **không bao giờ** phải phơi mình ra Internet.

<details class="q"><summary><span>`docker compose config --quiet` báo đạt thì đã chạy được chưa?</span></summary>

**Chưa.** Lệnh đó kiểm tra **cấu trúc**, không kiểm tra **ý nghĩa**.

| Loại lỗi | Bắt được? |
|---|---|
| Sai cú pháp YAML | ✅ |
| Thiếu biến làm mất `image:` | ✅ |
| **Biến có tên nhưng giá trị rỗng** | ❌ **Lọt lưới** |
| Mật khẩu sai | ❌ |
| Image không tồn tại trên Registry | ❌ |

Trong bài lab có một thí nghiệm chứng minh điều này: một `.env` có đủ tên biến nhưng `DB_PASSWORD=` để trống sẽ **qua được** lệnh kiểm tra với `rc=0`, trong khi nó tạo ra một database **không có mật khẩu**.
</details>

<details class="q"><summary><span>Hai khoá SSH trong buổi học dùng cho việc gì, khác nhau ra sao?</span></summary>

| Kết nối | Khoá riêng nằm ở | Khoá công khai nằm ở | Loại |
|---|---|---|---|
| **Máy bạn → VPS** | Máy bạn | `authorized_keys` của `deployer` | Khoá đăng nhập |
| **VPS → GitHub** | **VPS** | Repo → Settings → Deploy keys | **Deploy key, chỉ đọc** |

> ⚠️ **Không bao giờ chép khoá riêng cá nhân lên VPS** để VPS lấy code. Nếu VPS bị chiếm, kẻ tấn công cầm khoá đó vào được **mọi repo** bạn có quyền.

Deploy key thì chỉ dùng cho **một repo**, và để read-only thì cũng không sửa được code.
</details>

<details class="q"><summary><span>`Exit code 137` nghĩa là gì?</span></summary>

Tiến trình **bị giết bằng SIGKILL** — gần như luôn là do **hết RAM** (OOM Killer của Linux).

Đừng vội kết luận "rò rỉ bộ nhớ". Kiểm tra theo thứ tự:

1. VPS có đủ RAM không — `free -h`
2. Có đặt `mem_limit` quá thấp trong Compose không
3. Có tiến trình nào khác ăn hết RAM không — `docker stats`

Phần lớn trường hợp là **máy chủ quá nhỏ**, không phải code sai.

| Exit code | Nghĩa |
|---|---|
| `0` | Kết thúc bình thường |
| `1` | Ứng dụng lỗi — đọc `logs` |
| **`137`** | **Bị giết — hết RAM** |
| `143` | Nhận SIGTERM — thường do bạn `stop` |
</details>

---

# Tổng kết buổi học

| Bài | Câu hỏi trả lời | Kết quả đạt được |
|---|---|---|
| **1** | Máy chủ mới về làm gì? | Nền sạch, đã vá, có mốc baseline |
| **2** | Ai vào được máy chủ? | **Chỉ bạn** — root và mật khẩu bị loại bỏ |
| **3** | Cổng nào mở ra Internet? | **Đóng hết**, chỉ mở SSH/80/443 |
| **4** | Hệ thống sống chưa? | `health` trả `UP`, API trả dữ liệu thật, database **không lộ** |

## Ba điều nếu chỉ nhớ được ba điều

1. **Thử trước, khoá sau.** Khi thay đổi chính cái đường mình đang đứng trên đó, luôn giữ đường cũ mở.
2. **Dòng `ports` trong Compose là quyết định bảo mật.** Bật UFW không cứu được bạn khỏi một dòng `"5432:5432"`.
3. **"Chạy lệnh thành công" không bằng "hệ thống hoạt động".** Chỉ health check và dữ liệu thật mới là bằng chứng.

# Bảng tra nhanh

| Việc | Lệnh |
|---|---|
| Tạo khoá SSH | `ssh-keygen -t ed25519 -C "ghi-chu" -f ~/.ssh/ten-khoa` |
| Đăng nhập bằng khoá | `ssh -i ~/.ssh/ten-khoa deployer@<ip>` |
| Xem quyền cả đường dẫn | `namei -l /home/deployer/.ssh/authorized_keys` |
| Kiểm tra cú pháp SSH trước khi reload | `sudo sshd -t` |
| Xem cấu hình SSH đang chạy | `sudo sshd -T \| grep passwordauth` |
| Chặn hết đầu vào | `sudo ufw default deny incoming` |
| Mở SSH **trước khi** bật | `sudo ufw allow OpenSSH` |
| Xem trạng thái tường lửa | `sudo ufw status verbose` |
| Kiểm tra `.env` bị Git bỏ qua chưa | `git check-ignore -v .env` |
| Kiểm tra cú pháp Compose | `docker compose config --quiet` |
| Kéo image về trước | `docker compose pull` |
| Dựng lên | `docker compose up -d` |
| Trạng thái + cổng | `docker compose ps` |
| Xem cổng có bị publish ra ngoài không | `docker inspect <ten> --format '{{.HostConfig.PortBindings}}'` |

# Từ khoá cần phân biệt

| Cặp khái niệm | Khác nhau ở |
|---|---|
| Khoá riêng ↔ Khoá công khai | Chìa (ở lại máy bạn) ↔ Ổ khoá (gắn lên máy chủ) |
| `apt update` ↔ `apt upgrade` | Tải danh mục ↔ Cài thật |
| `Permission denied` ↔ `Connection timed out` | Bị từ chối ↔ **Không tới được** (tường lửa) |
| `sshd -t` ↔ `sshd -T` | Kiểm tra cú pháp ↔ In cấu hình đang chạy |
| `.env.example` ↔ `.env` | Mẫu, có commit ↔ Thật, **không bao giờ** commit |
| `build:` ↔ `image:` | Tự biên dịch (S04) ↔ **Kéo từ Registry về** (S10) |
| `"8081:8081"` ↔ `"127.0.0.1:8081:8081"` | Cả Internet ↔ Chỉ chính máy chủ |
