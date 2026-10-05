# TÀI LIỆU SINH VIÊN — SESSION 10
# Triển khai Hệ thống lên VPS

> **Tài liệu này bám sát slide bài giảng.** Bốn Lesson và các mục con đánh số **đúng như trên slide**, để bạn đối chiếu được giữa lúc nghe giảng và lúc đọc lại.

> **Ba tài liệu của buổi học:**
>
> | Tài liệu | Dùng khi nào |
> |---|---|
> | Slide bài giảng | Nghe giảng trên lớp |
> | **Tài liệu này** | Đọc lại để **hiểu vì sao** |
> | `S10-02-Lab-thuc-hanh.html` | **Gõ lệnh** — bảng lệnh đầy đủ kèm 4 thí nghiệm gây lỗi |
> | `S10-04-Trien-khai-VPS-that.html` | Khi làm trên **máy chủ AWS thật** |

## Bản đồ: slide ↔ tài liệu ↔ bài lab

| Slide | Lesson | Tài liệu này | Bài lab |
|---|---|---|---|
| 4–6 | **01** · Khởi tạo VPS và thiết lập kết nối quản trị | Lesson 01 | BÀI 1 |
| 8–11 | **02** · Tạo user triển khai và bảo mật truy cập SSH | Lesson 02 | BÀI 2 |
| 13–16 | **03** · Cài Docker, cấu hình UFW và kiểm soát cổng public | Lesson 03 | BÀI 3 |
| 18–21 | **04** · Đồng bộ cấu hình và vận hành QuickBite bằng Compose | Lesson 04 | BÀI 4 |
| — | Tìm lỗi | Rải trong từng Lesson | BÀI 5 |
| — | **(bổ sung)** Đưa lên server thật, gọi qua API Gateway bằng IP | **Lesson 05** | — |

---

# Trước khi vào bài: buổi này nối tiếp Session 08 thế nào

<div class="keybox">
<span class="lbl">Một câu để nhớ cả buổi</span>
<p><strong>Session 08 dạy cách đóng gói. Session 10 dạy cách giữ cho nó sống và không bị chiếm.</strong></p>
</div>

| | Session 08 | **Session 10** |
|---|---|---|
| Câu hỏi | *"Giao sản phẩm cho người khác thế nào?"* | *"Dựng nó lên và giữ cho nó sống thế nào?"* |
| Sản phẩm cuối | **Image** nằm trên Registry | **Hệ thống đang chạy** trên máy chủ có IP public |
| Máy đích | Runner GitHub — **dùng xong là xoá** | **VPS của bạn** — tồn tại lâu dài |
| Ai vá lỗi, ai lo bảo mật | GitHub | **Bạn** |
| Ai nhìn thấy máy đó | Không ai | **Cả Internet** |
| Compose dùng gì | — | **`image:`** thay cho `build:` |

> **Mối liên hệ giữa hai buổi:** chính nhờ Session 08 đã đẩy image lên Registry mà hôm nay VPS **không cần cài Java, không cần Gradle, không cần mã nguồn**. Nó chỉ `docker compose pull` rồi `up -d`.

---

# LESSON 01 · KHỞI TẠO VPS VÀ THIẾT LẬP KẾT NỐI QUẢN TRỊ

## 1.1 · Một máy chủ public đi kèm toàn bộ trách nhiệm vận hành

Thuê một máy chủ không chỉ là có thêm chỗ chạy ứng dụng — nó là **nhận thêm một danh sách việc phải làm suốt đời máy đó**.

| Hạ tầng | Mức kiểm soát | Công việc bạn phải tự quản trị |
|---|---|---|
| **VPS** | OS, network và runtime | Cập nhật, bảo mật, triển khai, giám sát |
| **Cloud VM** | Tương tự VPS, tích hợp thêm dịch vụ cloud | IAM, network cloud, chi phí, vận hành VM |
| **PaaS** | Ít quyền hệ điều hành hơn | Chủ yếu cấu hình và ứng dụng |

> 💡 **Đọc bảng này từ dưới lên:** càng xuống dưới càng ít việc, nhưng cũng càng ít quyền. PaaS lo hộ bạn gần hết, đổi lại bạn không chạm được vào hệ điều hành. VPS cho bạn toàn quyền, đổi lại **mọi thứ hỏng đều là việc của bạn**.

### Phạm vi thực hành của QuickBite

| | Cụ thể |
|---|---|
| Hệ điều hành | **Ubuntu Server 24.04 LTS** với public IP |
| Tài nguyên | Phải đủ cho container Java, database và Docker Engine — **kiểm tra RAM, CPU, dung lượng thật**, đừng áp một cấu hình tối thiểu rập khuôn |
| Đặc tính VPS | Là **máy chủ đơn** — không tự có high availability, không autoscaling, không backup tự động |

> ⚠️ **Dòng cuối quan trọng hơn vẻ ngoài của nó.** VPS **không tự sao lưu**. Máy hỏng là mất dữ liệu, trừ khi bạn tự dựng cơ chế sao lưu. Đừng nhầm VPS với các dịch vụ được quản lý sẵn.

### Mô hình luồng kết nối của dự án

```
┌───────────┐      ┌──────────┐      ┌─────────────────────────────┐
│ Localhost │ ───▶ │ Internet │ ───▶ │          VPS Host           │
│ (máy bạn) │      │          │      │  ┌───────────────────────┐  │
└───────────┘      └──────────┘      │  │    Docker Compose     │  │
                                     │  │  ┌─────────────────┐  │  │
                                     │  │  │  QuickBite App  │  │  │
                                     │  │  └─────────────────┘  │  │
                                     │  └───────────────────────┘  │
                                     └─────────────────────────────┘
```

Bạn ngồi ở **Localhost**, đi qua **Internet**, tới **VPS Host**. Trên đó **Docker Compose** điều phối các container, và **QuickBite App** chạy bên trong một container.

> 💡 **Nhìn sơ đồ này để hiểu vì sao có nhiều lớp bảo vệ.** Mỗi mũi tên là một chỗ có thể chặn: Internet → VPS chặn bằng **tường lửa**; vào được VPS rồi thì chặn tiếp bằng **SSH key**; container nào được lộ ra ngoài thì quyết định bằng **`ports`**. Ba lớp ở ba vị trí khác nhau trên cùng sơ đồ này.

### Vì sao VPS khác mọi thứ ta từng dùng

| | GitHub Runner (Session 07–08) | **VPS (buổi này)** |
|---|---|---|
| Sống bao lâu | Vài phút rồi **bị xoá** | **Mãi mãi** cho tới khi bạn trả máy |
| Hỏng thì sao | Chạy lại workflow | **Tự sửa**, có thể mất dịch vụ |
| Ai nhìn thấy nó | Không ai | **Cả Internet** — nó có IP public |

> ⚠️ **Ngay giây phút VPS được tạo ra, nó đã bị quét.** Các bot dò cổng 22 và thử mật khẩu phổ biến liên tục, cả ngày lẫn đêm. Đây không phải chuyện doạ — mở log SSH của một VPS mới sau vài giờ là thấy hàng trăm lượt thử đăng nhập. Đó là lý do **Lesson 02 không phải bài học tuỳ chọn**.

## 1.2 · Công cụ hỗ trợ thao tác, không thay thế cơ chế bảo mật SSH

Ngoài lệnh `ssh` trong terminal, có nhiều phần mềm SSH client có giao diện (Termius, MobaXterm, Xshell, Tabby…). Chúng **tiện hơn**, nhưng cần hiểu rõ chúng **không thay thế** bất cứ cơ chế bảo mật nào.

### Profile kết nối

| Việc | Nội dung |
|---|---|
| **Khai báo thông tin** | Điền **Host**, **Port**, **Username** rồi lưu profile (ví dụ file `.tlp`) theo tên dễ nhận diện |
| **Nguyên tắc bảo mật** | **Không chia sẻ** profile có chứa thông tin xác thực; ưu tiên chuyển sang **SSH key** ở Lesson 02 |

> 💡 **Terminal thuần làm được y hệt mà không cần cài gì.** Thêm vài dòng vào `~/.ssh/config` là có "profile" riêng:
> ```
> Host quickbite
>     HostName 13.210.134.235
>     User deployer
>     IdentityFile ~/.ssh/quickbite_vps_ed25519
> ```
> Từ đó chỉ cần gõ `ssh quickbite`. Cách này chạy trên **mọi hệ điều hành**, không phụ thuộc phần mềm nào, và `scp` cũng dùng được luôn bí danh đó.

### Hai cửa sổ làm việc

| Cửa sổ | Dùng để |
|---|---|
| **New terminal console** | Chạy các lệnh quản trị trực tiếp trên hệ điều hành VPS |
| **New SFTP window** | Truyền tải file **có chủ đích**, trực quan giữa máy local và VPS |

### Hai giới hạn cần hiểu rõ

**Thao tác thủ công.** SFTP tiện cho thao tác nhanh, nhưng **không tạo ra lịch sử triển khai rõ ràng như Git**.

> ⚠️ **Đây là cái bẫy lớn nhất của SFTP.** Bạn kéo thả một file sửa lỗi lên máy chủ lúc 11 giờ đêm. Ba tuần sau hệ thống hỏng, và **không ai biết file trên máy chủ khác file trong Git ở chỗ nào** — kể cả bạn. Mọi thay đổi nên đi qua Git và Registry, giống hệt những gì ta làm từ Session 07 tới nay. SFTP chỉ nên dùng cho thứ **không thuộc về mã nguồn**, ví dụ file `.env` production.

**Duy trì session.** Keep-alive chỉ giữ kết nối **tạm thời**. Nếu mạng rớt giữa chừng, lệnh đang chạy **chết theo**.

> 💡 **Tác vụ dài cần `tmux` hoặc `screen`.** Chúng tạo một phiên **sống độc lập với kết nối SSH** — mạng rớt thì phiên vẫn chạy tiếp, bạn vào lại và nối tiếp đúng chỗ cũ:
>
> | Việc | Lệnh |
> |---|---|
> | Tạo phiên mới | `tmux new -s deploy` |
> | Rời phiên (vẫn chạy tiếp) | Nhấn `Ctrl+B` rồi `D` |
> | Xem các phiên đang có | `tmux ls` |
> | Vào lại phiên cũ | `tmux attach -t deploy` |
>
> Dùng cho những việc kéo dài như `apt upgrade` lớn, migration database, hoặc build nặng. Với `docker compose up -d` thì không cần, vì lệnh đó trả về ngay.

## 1.3 · Cập nhật gói, kiểm tra reboot và ghi lại trạng thái ban đầu

### `apt update` và `apt upgrade` khác nhau thế nào

Hai lệnh này hay bị gõ như một cặp mà không hiểu vì sao phải có cả hai:

| Lệnh | Làm gì | Có cài gì không |
|---|---|---|
| `apt update` | Hỏi các kho phần mềm *"ngoài kia đang có phiên bản nào?"* rồi ghi lại danh mục | **Không** |
| `apt upgrade` | Tải về và cài các bản mới theo danh mục đó | **Có** |

> 💡 `apt update` là **đi xem catalogue**, `apt upgrade` là **đặt hàng**. Chạy `upgrade` mà quên `update` là đặt hàng theo catalogue năm ngoái — có bản vá bảo mật vừa ra cũng không thấy.

### Vì sao phải kiểm tra `reboot-required`

Khi nhân Linux được vá, **máy vẫn đang chạy nhân cũ** cho tới lần khởi động lại. Bản vá đã tải về nhưng **chưa có tác dụng**. Hệ thống đánh dấu điều này bằng file `/var/run/reboot-required`.

> ⚠️ Nếu cờ này xuất hiện, hãy khởi động lại **trong giờ bảo trì**, rồi SSH vào lại để xác nhận máy lên bình thường — đừng reboot rồi bỏ đi.

### Ghi lại bằng chứng: baseline

Lưu lại **phiên bản OS, tài nguyên VPS hiện tại và kết quả cập nhật** để làm mốc cho các bước sau.

| Số liệu | Vì sao cần biết |
|---|---|
| RAM | Container Java của QuickBite ăn ~**300 MB**, PostgreSQL ~**90 MB** |
| CPU | Quyết định chạy được bao nhiêu service |
| Đĩa | Image Docker và log tích lại rất nhanh |
| Phiên bản OS và nhân | Để sau này biết "nó đã đổi gì so với lúc đầu" |

> 💡 **Vì sao phải ghi baseline?** Khi hệ thống hỏng sau vài tuần, câu hỏi đầu tiên luôn là *"nó khác lúc đầu ở chỗ nào?"*. Không có mốc ban đầu thì không trả lời được, và bạn sẽ sửa bằng cách đoán.

> ⚠️ Khi hết RAM, Linux **giết tiến trình ngốn nhiều nhất** — thường chính là ứng dụng của bạn. Lỗi đó hiện ra dưới tên **Exit code 137**, và phần lớn trường hợp nguyên nhân là **máy chủ quá nhỏ**, không phải code bị rò rỉ bộ nhớ.

### Kết quả đạt được sau Lesson 01

| | |
|---|---|
| ✅ | Kết nối đúng VPS |
| ✅ | Mở được Terminal và SFTP |
| ✅ | Có baseline cập nhật rõ ràng |

---

# LESSON 02 · TẠO USER TRIỂN KHAI VÀ BẢO MẬT TRUY CẬP SSH

## 2.1 · SSH hardening phải giảm cả bề mặt tấn công và hậu quả thao tác sai

Hai mục tiêu, không phải một:

| Mục tiêu | Nghĩa là | Đạt bằng cách |
|---|---|---|
| Giảm **bề mặt tấn công** | Bớt đi những đường mà kẻ lạ có thể thử | Tắt đăng nhập mật khẩu, tắt root |
| Giảm **hậu quả thao tác sai** | Bạn gõ nhầm thì thiệt hại nhỏ lại | Dùng user thường, chỉ nâng quyền khi cần |

### Mô hình phân rã đặc quyền

> Người dùng thông thường **không có quyền phá hoại**, trừ khi chủ động nâng quyền qua một cơ chế kiểm soát chặt chẽ.

### Bốn nguyên tắc thiết lập an toàn

| Nguyên tắc | Nội dung |
|---|---|
| **Hạn chế tài khoản root** | Không dùng root cho công việc hằng ngày; tạo user `deployer` và chỉ nâng quyền bằng `sudo` khi thực sự cần |
| **Xác thực bằng khoá** | Private key ở máy local; public key của user nằm trong `/home/deployer/.ssh/authorized_keys` để **loại bỏ hoàn toàn mật khẩu** |
| **Bảo vệ khoá private** | SSH key thay thế mật khẩu, nhưng private key **bắt buộc** phải được bảo vệ bằng quyền file nghiêm ngặt và passphrase phù hợp |
| **Quy trình an toàn** | **Không tắt root/password trước khi** luồng đăng nhập mới đã được kiểm tra và xác nhận thành công trên một session khác |

### Vì sao không dùng thẳng `root`

`root` **không có phanh**. Gõ nhầm một lệnh xoá là mất máy. `sudo` buộc bạn **dừng lại nửa giây và gõ mật khẩu** trước mỗi hành động nguy hiểm.

Và `sudo` còn làm một việc mà root thuần không làm được: **ghi lại nhật ký** — ai, lúc nào, lệnh gì. Trên máy chủ nhiều người dùng, nó biến *"ai đó đã xoá thư mục"* thành *"lúc 14:32 tài khoản deployer đã chạy lệnh này"*.

## 2.2 · Thiết lập SSH key và phân quyền tài khoản deployer

### Khoá công khai và khoá riêng — hiểu bằng một hình ảnh

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

### Việc làm trên hai máy, không trộn lẫn

| Máy | Việc |
|---|---|
| **Trên VPS** (bằng root) | `adduser deployer`, `usermod -aG sudo deployer` |
| **Trên máy local** | `ssh-keygen -t ed25519`, rồi xem nội dung file `.pub` |
| **Trên VPS** (cấu hình deployer) | Tạo thư mục `.ssh` quyền `700`, dán public key vào `authorized_keys`, đặt quyền `600` |

**Hai file được tạo ra, và chúng đi hai hướng khác nhau:**

| File | Là gì | Đi đâu |
|---|---|---|
| `quickbite_vps_ed25519` | **Khoá riêng** | **Ở LẠI máy bạn, vĩnh viễn** |
| `quickbite_vps_ed25519.pub` | **Khoá công khai** | Chép lên VPS |

> ⚠️ **Chỉ dán nội dung file `.pub`.** Khoá bí mật (`id_ed25519`) phải được giữ tuyệt mật tại máy cá nhân — **không tải lên VPS**, không chia sẻ qua bất kỳ kênh nào, không commit vào Git. Ai cầm được nó là vào được máy chủ của bạn.

<details class="q"><summary><span>Vì sao chọn `ed25519` chứ không phải `rsa`?</span></summary>

| | RSA 2048 | **ed25519** |
|---|---|---|
| Độ dài khoá | ~400 ký tự | **~70 ký tự** |
| Tốc độ | Chậm hơn | **Nhanh hơn** |
| Mức an toàn | Đủ dùng | **Cao hơn** |
| Hỗ trợ | Mọi nơi | Mọi hệ thống từ 2014 |

Không có lý do thực tế nào để chọn RSA cho máy chủ mới, trừ khi phải nối tới thiết bị rất cũ.
</details>

## 2.3 · Hardening SSH theo quy trình thử trước, khoá sau

### Giữ session cũ mở cho đến khi session mới hoạt động

Thứ tự năm bước, **không được đảo**:

| # | Việc | Phải thấy gì mới đi tiếp |
|---|---|---|
| 1 | Mở terminal **mới** test kết nối bằng deployer | Vào được, **không hỏi mật khẩu** |
| 2 | Kiểm tra quyền `sudo` | `sudo -v` chạy được |
| 3 | Sửa `/etc/ssh/sshd_config` | `PermitRootLogin no`, `PasswordAuthentication no`, `PubkeyAuthentication yes` |
| 4 | **Kiểm tra cú pháp** rồi nạp lại | `sshd -t` không báo lỗi |
| 5 | Mở session mới test lần cuối | Vào được → **giờ mới đóng session root cũ** |

> ⚠️ **Tuyệt đối không đóng session root hiện tại** cho tới khi xác nhận kết nối mới thành công. Nếu cấu hình sai, session root cũ là **"phao cứu sinh" duy nhất** giúp bạn sửa lại mà không bị khoá hoàn toàn khỏi VPS.

### Vì sao thứ tự này không được đảo

Hãy hình dung bạn làm ngược lại — tắt đăng nhập bằng mật khẩu **trước**, rồi mới cài khoá. Nếu dán nhầm public key (thiếu một ký tự, hoặc trình soạn thảo tự xuống dòng):

- Mật khẩu: **đã tắt**
- Khoá: **không khớp**
- Phiên đang mở: nếu đã đóng → **không còn đường nào vào máy**

<div class="keybox">
<span class="lbl">Quy tắc áp dụng cho mọi việc, không riêng SSH</span>
<p>Khi thay đổi <strong>chính cái đường mình đang đứng trên đó</strong>, luôn giữ đường cũ mở cho tới khi đường mới đã được chứng minh là chạy.</p>
</div>

### `sshd -t` và `sshd -T` — hai lệnh khác nhau một chữ

| Lệnh | Làm gì |
|---|---|
| `sshd -t` (chữ thường) | **Kiểm tra cú pháp** file cấu hình. Chạy **trước khi** nạp lại |
| `sshd -T` (chữ hoa) | **In ra cấu hình đang thật sự chạy**, sau khi gộp mọi file |

> 💡 **Vì sao không đọc thẳng file config?** Vì file bạn vừa sửa **chưa chắc là cấu hình đang chạy**. Ubuntu có thư mục `/etc/ssh/sshd_config.d/` chứa các file ghi đè. Có thể bạn sửa `PasswordAuthentication no` mà một file drop-in bật lại thành `yes`. `sshd -T` in ra **kết quả cuối cùng** — đó mới là sự thật.

### Bằng chứng cửa đã khoá đúng

Sau khi hardening, thử đăng nhập bằng mật khẩu sẽ nhận:

```
Trước:  Permission denied (publickey,password)
Sau:    Permission denied (publickey)
```

> ✅ **Một chữ biến mất.** Đó không phải thông báo lỗi — đó là **bằng chứng** mật khẩu đã bị loại khỏi hệ thống.

## 2.4 · Khi SSH key không hoạt động, kiểm tra từ quyền file đến log

> ⚠️ **Không sửa mò cấu hình trong khi chỉ còn một đường truy cập.** Kiểm tra theo thứ tự, đừng đổi lung tung rồi thử lại.

### Đọc đúng thông báo lỗi — bước khoanh vùng đầu tiên

| Thông báo | Nghĩa | Tìm ở đâu |
|---|---|---|
| `Permission denied (publickey)` | **Gọi tới được**, nhưng không được cho vào | Sai khoá, sai quyền file |
| `Connection timed out` / treo im | **Gói tin không tới được** máy chủ | **Tường lửa**, sai IP, sai cổng |
| `Connection refused` | Tới nơi nhưng **không ai nghe** | Dịch vụ SSH chưa chạy |

> 💡 Phân biệt được ba thông báo này là bạn đã khoanh vùng được quá nửa số sự cố SSH. Chúng chỉ về ba chỗ hoàn toàn khác nhau.

### Ba nhóm lỗi cấu hình phổ biến nhất

| Nhóm | Biểu hiện | Kiểm tra bằng |
|---|---|---|
| **Quyền file nghiêm ngặt** | Sai owner hoặc permission của thư mục home, thư mục `.ssh`, hoặc file `authorized_keys` | `namei -l /home/deployer/.ssh/authorized_keys` |
| **Lỗi khớp khoá** | Dán sai hoặc thiếu chuỗi public key khi copy lên VPS; hoặc client local đang chọn **sai file private key** | `ssh -v` xem khoá nào được đưa ra |
| **Xung đột cấu hình ẩn** | Thiết lập bị ghi đè bởi file include/drop-in khác, hoặc lỗi cú pháp làm SSHD nhận sai thông số | `sudo sshd -T \| grep ...` |

> 💡 **`namei -l` hơn `ls -l` ở chỗ nào?** `ls -l` chỉ xem **một** file. `namei -l` đi **suốt cả đường dẫn** từ `/` xuống, in quyền từng chặng. SSH kiểm tra **cả chuỗi** — chỉ cần một thư mục trên đường bị nới lỏng là nó từ chối, và `ls -l` sẽ không cho bạn thấy điều đó.

<details class="q"><summary><span>Vì sao `chmod 644` cho `authorized_keys` vẫn đăng nhập được, mà `chmod 666` thì không?</span></summary>

Vì SSH **không quan tâm ai đọc được** file đó — nội dung bên trong vốn là khoá **công khai**, đọc cũng không làm gì được.

SSH chỉ từ chối khi người ngoài **GHI** được, vì ghi được nghĩa là họ **tự thêm khoá của mình vào** rồi vào máy. Tương tự, nếu thư mục `.ssh` là `777` thì người khác **thay được cả file**, nên SSH cũng từ chối.

| Trường hợp | Vào được? |
|---|---|
| `600` authorized_keys | ✅ |
| `644` authorized_keys | ✅ **Có** |
| `666` authorized_keys | ❌ |
| `.ssh` là `777` | ❌ |

**Dù vậy vẫn luôn đặt `600`** — đó là thói quen phòng thân, và nhiều công cụ kiểm tra bảo mật sẽ báo lỗi nếu khác.

> Bài lab có thí nghiệm chạy thật để bạn tự đo bốn trường hợp này.
</details>

### Đường phục hồi khẩn cấp

| | |
|---|---|
| **Luôn giữ session cũ** | Tuyệt đối không tắt terminal đang kết nối cho tới khi chắc chắn mọi thứ đã hoạt động |
| **Dùng Web Console** | Nếu mất kết nối, dùng Rescue / Web Console của nhà cung cấp VPS để khôi phục cấu hình |

> ⚠️ **Hãy mở thử Web Console của nhà cung cấp ngay hôm nay**, lúc mọi thứ còn bình thường. Tìm nút đó lần đầu trong lúc đang mất kết nối, giữa đêm, với dịch vụ đang ngừng, là trải nghiệm không ai muốn có.

### Kết quả đạt được sau Lesson 02

| | |
|---|---|
| ✅ | Tài khoản `deployer` đăng nhập thành công bằng SSH key an toàn |
| ✅ | Sử dụng quyền quản trị qua `sudo`, tắt hoàn toàn đăng nhập root/password |
| ✅ | Thiết lập bảo mật tiêu chuẩn và **luôn có đường cứu hộ dự phòng** |

---

# LESSON 03 · CÀI ĐẶT DOCKER, CẤU HÌNH UFW VÀ KIỂM SOÁT CỔNG PUBLIC

## 3.1 · Cài Docker Engine từ repository chính thức

Ubuntu có sẵn gói tên `docker.io`, nhưng nó thường **cũ hơn vài phiên bản**, không phải bản chính thức, và có thể thiếu plugin như `docker compose`.

Quy trình đúng gồm hai phần:

| Phần | Làm gì |
|---|---|
| **1. Thiết lập APT repository** | Cài `ca-certificates` và `curl`, tạo thư mục keyring an toàn, tải và phân quyền GPG key của Docker |
| **2. Cài Docker CE và plugin** | Cài `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin` |

### Kiểm chứng mới là phần quan trọng

> ⚠️ **`apt install` thành công KHÔNG chứng minh bạn cài đúng nguồn** — nó cũng thành công nếu lấy nhầm gói cũ của Ubuntu.

```
apt-cache policy docker-ce
```

Dòng kết quả phải chỉ về `https://download.docker.com/linux/ubuntu`. Đây mới là câu trả lời cho câu hỏi *"gói này được lấy từ máy chủ nào?"*.

Và đừng chỉ nhìn lệnh `apt` chạy xong — **xác minh daemon thật sự đang chạy**:

| Lệnh | Xác nhận điều gì |
|---|---|
| `sudo systemctl is-active docker` | Docker daemon **đang chạy** |
| `sudo docker run --rm hello-world` | Chạy container được |
| `docker compose version` | Plugin Compose đã có |

> 💡 **CE là Community Edition**, không phải "Enterprise". Đây là bản **miễn phí, chính thức, dùng cho production được**. Bản trả phí tên là Docker Business. Nhầm hai chữ này dẫn tới việc tìm nhầm tài liệu.

## 3.2 · Nhóm `docker` tiện lợi nhưng mang quyền rất cao

> ⚠️ Thêm một tài khoản vào nhóm `docker` **tương đương trao quyền root** cho tài khoản đó. Không phải "gần bằng" — là **tương đương**.

### Cơ chế hoạt động và rủi ro

| | Nội dung |
|---|---|
| **Unix socket và quyền root** | Docker daemon chạy với quyền root và expose socket cho group `docker` |
| **Đạt quyền root gián tiếp** | Thành viên nhóm này có thể điều khiển daemon, **mount filesystem của host** và leo thang đặc quyền |
| **Cách kiểm chứng tốt nhất** | `newgrp docker` chỉ cập nhật shell hiện tại — hãy **đăng xuất và đăng nhập lại**, rồi kiểm tra bằng `id -nG` |

> ⚠️ **Tuyệt đối không** thêm tài khoản không tin cậy hoặc tài khoản dùng chung vào nhóm `docker`.
>
> **Rootless mode** là hướng đi bảo mật tốt hơn, nhưng nằm ngoài phạm vi bài thực hành này.

## 3.3 · UFW: giữ an toàn kết nối và kiểm soát cổng public

### Default deny incoming, chỉ mở đúng dịch vụ public

| Chính sách | Nghĩa là |
|---|---|
| `ufw default deny incoming` | *"Không ai được chủ động gọi vào máy tôi"* |
| `ufw default allow outgoing` | *"Máy tôi vẫn gọi ra ngoài được"* — cần cho `apt update` và `docker pull` |

Rồi mở đúng ba cổng:

| Cổng | Cho ai | Vì sao mở |
|---|---|---|
| 22 (SSH) | Chỉ bạn | Để quản trị máy |
| 80 (HTTP) | Mọi người | Chuyển hướng sang HTTPS |
| 443 (HTTPS) | Mọi người | Nơi người dùng thật truy cập |

### Vì sao "danh sách cho phép" thắng "danh sách cấm"

Giả sử bạn chọn cách ngược lại: *chặn những cổng nguy hiểm, mở phần còn lại*. Vấn đề là máy chủ có **65.535 cổng**, và mỗi phần mềm cài thêm có thể mở một cổng mới mà bạn không biết. Bạn **không thể liệt kê hết cái xấu**.

Với `default deny incoming`, mọi cổng mới mở ra đều **mặc định không ai gọi vào được**. Bạn chỉ cần nhớ **ba cổng đã mở**, thay vì canh chừng sáu vạn cổng.

> ⚠️ **Hai điều bắt buộc về SSH:**
> 1. Nếu SSH dùng port khác 22, phải `allow` **đúng port đó trước khi** enable tường lửa.
> 2. Sau khi bật UFW, **mở session SSH mới để kiểm tra** — không đóng session đang dùng ngay.
>
> Quên điều 1 là **tự khoá mình ra khỏi máy chủ ngay lập tức**. Bài lab có thí nghiệm cho bạn trải nghiệm chuyện này trong môi trường an toàn.

## 3.4 · `ports` là quyết định public network, không chỉ là cấu hình Compose

<div class="keybox">
<span class="lbl">Cái bẫy lớn nhất của cả buổi học</span>
<p>Bạn đã bật UFW chặn hết. Nhưng nếu Compose khai <code>"5432:5432"</code> cho database thì <strong>cổng đó vẫn mở ra Internet</strong>.</p>
<p>Lý do: Docker tạo luật NAT/firewall cho bridge network, và traffic tới published port có thể được <strong>chuyển hướng trước các chain UFW thường dùng</strong>.</p>
</div>

### Ba cách khai `ports` và hậu quả

| Cách viết | Ai gọi được | Dùng khi |
|---|---|---|
| `"8081:8081"` | **Cả Internet** | Dịch vụ thật sự cần công khai |
| `"127.0.0.1:8081:8081"` | Chỉ chính máy chủ đó | Có **reverse proxy** trên cùng VPS |
| *(không khai `ports`)* | Chỉ container cùng mạng | **Database, dịch vụ nội bộ** |

### Bốn nguyên tắc thiết lập network

| Nguyên tắc | Nội dung |
|---|---|
| Hiểu cơ chế | Docker tạo rule NAT riêng; traffic tới published port có thể đi **trước** các chain UFW |
| Không public cổng nội bộ | **Không** mở `5432`, `3306`, `6379`, `27017` nếu không có nhu cầu thực sự |
| Bind loopback khi có proxy | Dùng `127.0.0.1` khi chỉ reverse proxy trên cùng VPS cần truy cập |
| Không tắt iptables của Docker | Làm vậy **phá vỡ networking của container** — đừng dùng như một "cách sửa nhanh" |

### Ba lớp bảo vệ, mỗi lớp chặn một thứ khác nhau

| Lớp | Chặn cái gì | Bị vô hiệu khi |
|---|---|---|
| **SSH key** | Người không có khoá | Bật lại `PasswordAuthentication` |
| **UFW** | Gói tin tới cổng không được phép | Docker publish thẳng ra `0.0.0.0` |
| **`ports` trong Compose** | Dịch vụ không được công bố | Khai `"5432:5432"` |

Ba lớp này **không thay thế nhau**. Thiếu một lớp là có một đường vòng.

### Kết quả đạt được sau Lesson 03

| | |
|---|---|
| ✅ | Docker chạy ổn định, quyền socket được kiểm soát an toàn |
| ✅ | UFW bảo vệ chặt chẽ SSH/HTTP/HTTPS |
| ✅ | Compose chuẩn hoá, **ngăn rò rỉ database và dịch vụ nội bộ ra Internet** |

---

# LESSON 04 · ĐỒNG BỘ CẤU HÌNH VÀ VẬN HÀNH QUICKBITE BẰNG DOCKER COMPOSE

## 4.1 · Hai SSH key phục vụ hai quan hệ tin cậy khác nhau

### Bản đồ phân phối khoá

| Kết nối | **Private key** nằm ở đâu | **Public key** nằm ở đâu |
|---|---|---|
| **Local → VPS** | Máy local | `authorized_keys` của `deployer` |
| **VPS → GitHub** | **VPS** | Repo → Settings → **Deploy keys** |

> ⚠️ **Không sao chép private key cá nhân lên VPS** để VPS lấy code. Nếu VPS bị chiếm, kẻ tấn công cầm khoá đó **vào được mọi repo** mà bạn có quyền — kể cả những repo không liên quan gì tới dự án này.

### Hai nguyên tắc thiết lập tin cậy

| Nguyên tắc | Nội dung |
|---|---|
| **Giới hạn đặc quyền tối thiểu** | Với một repo hạ tầng, **Deploy Key read-only** giới hạn quyền tốt hơn SSH key gắn với tài khoản cá nhân |
| **Thiết kế credential cô lập** | Mỗi Deploy Key **chỉ dùng cho một repository**; hệ thống nhiều repo cần cơ chế định danh độc lập, tránh dùng chung |

## 4.2 · `.env` production tồn tại trên VPS, không tồn tại trong Git

### Phân tách môi trường

| File | Chứa gì | Có commit không |
|---|---|---|
| `.env.example` | Chỉ **tên biến** và giá trị mẫu không nhạy cảm | ✅ **Có** |
| `.env` | Mật khẩu database, JWT secret, cấu hình production | ❌ **Không bao giờ** |

Quy trình: **tạo từ mẫu → giới hạn quyền đọc → kiểm tra trước khi chạy Compose**.

```
cp .env.example .env
nano .env
chmod 600 .env
```

### Kiểm tra Git có thật sự bỏ qua `.env` không

```
git check-ignore .env
```

> 💡 **Vì sao dùng lệnh này chứ không nhìn `git status`?** `git status` không thấy `.env` có thể vì nó bị bỏ qua, **cũng có thể** vì bạn đã lỡ commit nó rồi. `git check-ignore -v` chỉ thẳng ra **dòng nào, trong file nào** đang bỏ qua nó.

> ⚠️ **Nếu secret từng bị commit, xoá file đi là chưa đủ.** Nó vẫn nằm trong lịch sử repo và ai cũng xem lại được. Bạn phải **rotate secret** đó và xử lý lịch sử repository.

### Kiểm tra cấu trúc trước khi chạy

```
docker compose config --quiet
```

Lệnh này giúp kiểm tra **cấu trúc và nội suy biến** — nhưng **không đảm bảo** các service sẽ khởi động thành công.

<details class="q"><summary><span>`docker compose config --quiet` báo đạt thì đã chạy được chưa?</span></summary>

**Chưa.** Lệnh đó kiểm tra **cấu trúc**, không kiểm tra **ý nghĩa**.

| Loại lỗi | Bắt được? |
|---|---|
| Sai cú pháp YAML | ✅ |
| Thiếu biến làm mất `image:` | ✅ |
| **Biến có tên nhưng giá trị rỗng** | ❌ **Lọt lưới** |
| Mật khẩu sai | ❌ |
| Image không tồn tại trên Registry | ❌ |

Trong bài lab có một thí nghiệm chạy thật chứng minh điều này: một `.env` có đủ tên biến nhưng `DB_PASSWORD=` để trống sẽ **qua được** lệnh kiểm tra với `rc=0`, trong khi nó tạo ra một database **không có mật khẩu**.

**Cách phòng thủ thật sự:** tự kiểm tra biến bắt buộc trước khi deploy, ví dụ
`grep -q '^DB_PASSWORD=.\+' .env || echo "THIEU MAT KHAU"`
</details>

## 4.3 · Pull image trước, sau đó mới tạo hoặc cập nhật container

Tách bước **tải image** khỏi bước **thay đổi trạng thái hệ thống**:

```
docker compose pull     # chỉ tải về đĩa
docker compose up -d    # mới thật sự đổi hệ thống
docker compose ps       # kiểm tra sau deploy
```

### Ba nguyên tắc vận hành

| Nguyên tắc | Nội dung |
|---|---|
| **Cô lập rủi ro tải file** | Nếu `pull` thất bại do mạng hoặc xác thực, hệ thống hiện tại **vẫn chạy an toàn**, chưa bị thay đổi hay ngắt quãng |
| **Cập nhật chính xác** | `up -d` tạo mới hoặc thay thế container để khớp với cấu hình Compose mới |
| **Quản lý phiên bản chặt chẽ** | **Luôn dùng tag release cụ thể**; tuyệt đối tránh phụ thuộc `latest` khi cần truy vết và rollback nhanh |

> 💡 **Vì sao `latest` nguy hiểm?** Mỗi máy pull vào thời điểm khác nhau có thể nhận **bản khác nhau**, và khi cần quay về bản cũ thì **không còn nhãn nào trỏ tới nó**.

## 4.4 · Chỉ kết luận thành công sau khi kiểm tra toàn diện

Trạng thái, log, health và tài nguyên trả lời **các câu hỏi khác nhau**:

| Lệnh kiểm tra | Xác nhận thực tế điều gì |
|---|---|
| `docker compose ps` | Container đang ở trạng thái nào (**Up / Exit**) |
| `docker compose logs` | Ứng dụng khởi động thành công hay **lỗi ở đâu** |
| `curl .../actuator/health` | Service đã **sẵn sàng phục vụ** yêu cầu chưa |
| `docker stats --no-stream` | Snapshot mức tiêu thụ **CPU và RAM** hiện tại |

> ⚠️ Bốn lệnh này **không thay thế nhau**. Container `Up` mà ứng dụng bên trong đã chết — chuyện thường ngày. Chỉ khi `health` trả về `UP` **và** API trả về dữ liệu thật thì mới được kết luận là xong.

### Đọc cột PORTS — nơi nhìn ra lỗ hổng bằng mắt thường

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

> 💡 **Vậy người dùng thật vào bằng đường nào?** Qua **reverse proxy** (Nginx, Caddy, Traefik) chạy trên cùng máy chủ: nó nghe cổng 443 công khai, nhận HTTPS, rồi chuyển tiếp vào `127.0.0.1:8081`. Nhờ vậy ứng dụng Java **không bao giờ** phải phơi mình ra Internet.

<details class="q"><summary><span>`Exit code 137` nghĩa là gì?</span></summary>

Tiến trình **bị buộc dừng đột ngột bằng SIGKILL** — gần như luôn là do **hết RAM** (OOM Killer của Linux).

Cần rà soát kỹ **OOM, hành vi quản trị hệ thống hoặc log hệ điều hành** trước khi kết luận có memory leak:

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

# LESSON 05 (THỰC CHIẾN) · ĐƯA QUICKBITE LÊN SERVER VÀ GỌI QUA API GATEWAY BẰNG IP

> **Phần này không có trên slide.** Nó ghép cả bốn Lesson lại thành một việc duy nhất: **hệ thống chạy thật trên server ngay sau buổi học**, gọi được bằng **IP**, chưa cần tên miền.

> **Ví dụ xuyên suốt:** server có IP `13.210.134.235`. **Thay bằng IP máy của bạn** ở mọi lệnh.

## 5.1 · Toàn cảnh: cái gì chạy ở đâu

```
   Internet
      │
      │  chỉ MỘT cổng được mở
      ▼
┌─────────────────────────────────────────────────────┐
│ SERVER 13.210.134.235                               │
│                                                     │
│   :8080  ┌──────────────┐                           │
│  ◀───────│ api-gateway  │  ← cửa duy nhất ra ngoài  │
│          └──────┬───────┘                           │
│                 │ mạng Docker nội bộ                │
│       ┌─────────┼─────────┬──────────────┐          │
│       ▼         ▼         ▼              ▼          │
│  ┌────────┐ ┌────────┐ ┌───────┐ ┌──────────────┐   │
│  │ user   │ │restaur.│ │ order │ │ notification │   │
│  │ :8081  │ │ :8082  │ │ :8083 │ │    :8084     │   │
│  └───┬────┘ └───┬────┘ └───┬───┘ └──────┬───────┘   │
│      └──────────┴──────────┴────────────┘           │
│                      ▼                              │
│              ┌───────────────┐                      │
│              │ PostgreSQL    │  ← KHÔNG cổng ra     │
│              └───────────────┘                      │
└─────────────────────────────────────────────────────┘
```

| Thành phần | Cổng trên server | Internet gọi được? |
|---|---|---|
| **api-gateway** | **8080** | ✅ **Có — đây là cửa duy nhất** |
| user-service | 8081 | ❌ Không |
| restaurant-service | 8082 | ❌ Không |
| order-service | 8083 | ❌ Không |
| notification-service | 8084 | ❌ Không |
| PostgreSQL | 5432 | ❌ Không |

> 💡 **Đây chính là bài học Lesson 03 mục 3.4 áp dụng vào thật.** Bốn service và database **không khai `ports`** nên chúng chỉ tồn tại trong mạng Docker. Chỉ gateway được publish. Kẻ tấn công quét server bạn sẽ thấy **đúng một cổng ứng dụng**, thay vì sáu.

## 5.2 · Server cần gì — và **không** cần gì

| Cần | Không cần |
|---|---|
| **Docker** (đã cài ở Lesson 03) | ❌ Java / JDK |
| **git** | ❌ Gradle |
| Khoảng **4 GB** đĩa trống | ❌ Maven, Node, hay bất cứ runtime nào |

> 💡 **Vì sao server không cần Java?** Vì việc build JAR cũng **chạy bên trong Docker** — script `build-all.sh` dùng image `gradle:8.10-jdk17` làm "xưởng gia công tạm". Đúng tinh thần multi-stage của Session 08: máy chủ chỉ cần Docker, mọi công cụ biên dịch nằm trong container.

Kiểm tra server đã sẵn sàng:

```
docker --version && docker compose version && git --version
```

Nếu thiếu `git`:

```
sudo apt install -y git
```

## 5.3 · Lấy code về server

```
cd ~
git clone https://github.com/caotv1512/project-demo.git
cd project-demo/session-05
```

**Phải thấy:** `build-all.sh`, `start-all.sh`, `check.sh`, `stack/`, `quickbite5-db/`

> 💡 **Vì sao dùng `https://` mà không cần SSH key?** Vì repo này **công khai** — ai cũng clone được, không cần xác thực. Deploy key ở Lesson 04 chỉ cần khi repo **riêng tư**. Với repo riêng tư, lệnh sẽ là `git clone git@github.com:<ns>/<repo>.git` và server phải có deploy key.

## 5.4 · Tạo `.env` — áp dụng ngay Lesson 04

Repo **cố tình không chứa `.env`** (nó nằm trong `.gitignore`). Bạn phải tạo từ mẫu:

```
cd ~/project-demo/session-05/stack
cp .env.example .env
nano .env
```

**Các giá trị phải khớp với `quickbite5-db/init-db.sql`** — file đó tạo sẵn 4 user trong PostgreSQL:

| Biến | Giá trị |
|---|---|
| `USER_DB_USERNAME` / `USER_DB_PASSWORD` | `quickbite_user` / `quickbite_user` |
| `RESTAURANT_DB_USERNAME` / `..._PASSWORD` | `quickbite_restaurant` / `quickbite_restaurant` |
| `ORDER_DB_USERNAME` / `..._PASSWORD` | `quickbite_order` / `quickbite_order` |
| `NOTIFICATION_DB_USERNAME` / `..._PASSWORD` | `quickbite_notification` / `quickbite_notification` |
| `GATEWAY_HOST_PORT` | `8080` |

```
chmod 600 .env
```

> ⚠️ **Mật khẩu ở trên là mật khẩu demo, trùng với tên user.** Dùng được để chạy thử, nhưng **không được giữ nguyên trên một server thật phục vụ người dùng**. Muốn đổi, bạn phải sửa **cả hai nơi**: `.env` và `quickbite5-db/init-db.sql` — rồi **xoá volume database** để script khởi tạo chạy lại (`docker compose down -v` trong thư mục `quickbite5-db`). Sửa mỗi `.env` thì service sẽ không đăng nhập được vào database.

Kiểm tra lại đúng cách của Lesson 04:

```
git check-ignore -v .env
docker compose config --quiet && echo "Cu phap OK"
```

## 5.5 · Build 5 JAR — bên trong Docker

```
cd ~/project-demo/session-05
./build-all.sh
```

**Phải thấy:** lần lượt `🔨 Build user-service ...` cho tới `api-gateway`, rồi `✅ Xong tat ca.`

> ⚠️ **Bước này nặng nhất của cả quy trình.** Lần đầu phải tải Gradle và toàn bộ thư viện — mất **5–15 phút** tuỳ đường truyền, và ăn nhiều RAM.
>
> **Nếu server chỉ có 1 GB RAM**, hãy tạo swap **trước khi** chạy lệnh này, nếu không Gradle sẽ bị hệ điều hành giết giữa chừng:
>
> ```
> sudo fallocate -l 2G /swapfile
> sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
> echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
> ```
>
> 💡 Đây là tác vụ dài — **nên chạy trong `tmux`** (mục 1.2) để mạng rớt cũng không mất tiến trình:
> `tmux new -s build` → chạy → `Ctrl+B` rồi `D` để rời ra.

## 5.6 · Khởi chạy hệ thống

```
./start-all.sh
```

Script này làm ba việc **theo đúng thứ tự**:

| # | Việc | Vì sao thứ tự này |
|---|---|---|
| 1 | Bật **database trước**, đợi `pg_isready` | Service bật trước database sẽ chết vì không kết nối được |
| 2 | Bật 4 microservice + gateway | Chúng cần database đã sẵn sàng |
| 3 | **Restart riêng gateway** | Gateway (Netty) **cache kết quả phân giải DNS** — nếu một service vừa được tạo lại và đổi IP, gateway vẫn gọi vào IP cũ và báo `Connection refused` |

Kiểm tra:

```
cd stack && docker compose ps
```

**Phải thấy** 5 container `Up`, và **chỉ gateway có mũi tên cổng**:

```
quickbite5-gateway          0.0.0.0:8080->8080/tcp
quickbite5-user             8081/tcp
quickbite5-restaurant       8082/tcp
quickbite5-order            8083/tcp
quickbite5-notification     8084/tcp
```

## 5.7 · Mở đúng **một** cổng cho Gateway

Hệ thống đang chạy nhưng **chưa ai ngoài Internet gọi được** — vì Lesson 03 đã chặn hết. Giờ mở đúng cổng gateway:

```
sudo ufw allow 8080/tcp
sudo ufw status verbose
```

**Phải thấy** `8080/tcp ALLOW IN Anywhere` bên cạnh OpenSSH, 80 và 443.

> ⚠️ 🌐 **Nếu server nằm trên AWS, phải mở ở CẢ HAI nơi.** Mở UFW thôi là chưa đủ — Security Group vẫn chặn. Vào **EC2 → chọn máy → Security → Edit inbound rules → Add rule**: Custom TCP, Port `8080`, Source `0.0.0.0/0`.
>
> Đây đúng là tình huống "hai tầng tường lửa" ở file `S10-04`. Mở một tầng mà quên tầng kia là triệu chứng *"mở cổng rồi mà vẫn không gọi được"*.

## 5.8 · Gọi API bằng IP — bằng chứng deploy thành công

Từ **máy của bạn** (không phải từ server):

```
curl http://13.210.134.235:8080/api/v1/users
```

**Phải thấy dữ liệu thật:**

```json
[{"id":1,"full_name":"Nguyen Van An","email":"an.nguyen@quickbite.vn","wallet_balance":425000}, ...]
```

Thử cả bốn đường:

| Đường gọi | Gateway chuyển tới | Trả về |
|---|---|---|
| `http://13.210.134.235:8080/api/v1/users` | user-service:8081 | Danh sách người dùng |
| `http://13.210.134.235:8080/api/v1/restaurants` | restaurant-service:8082 | Danh sách nhà hàng |
| `http://13.210.134.235:8080/api/v1/orders` | order-service:8083 | Danh sách đơn hàng |
| `http://13.210.134.235:8080/api/v1/notifications` | notification-service:8084 | Danh sách thông báo |

> 💡 **Gateway biến đường dẫn thế nào?** Nó khớp `Path=/api/v1/users/**` rồi áp `StripPrefix=2` — **cắt bỏ 2 đoạn đầu** (`api` và `v1`) trước khi chuyển tiếp. Nên `/api/v1/users` ở ngoài trở thành `/users` khi tới user-service.
>
> Nhờ vậy bạn **đổi được cấu trúc URL công khai mà không phải sửa code service nào** — chỉ sửa cấu hình gateway.

Mở trình duyệt và dán thẳng vào thanh địa chỉ cũng ra kết quả — đó là lúc sinh viên thấy rõ nhất rằng **hệ thống đã thật sự lên mạng**.

<div class="keybox">
<span class="lbl">Đây là khoảnh khắc deploy thành công</span>
<p>Một người bất kỳ, ở một máy bất kỳ, gõ <code>http://13.210.134.235:8080/api/v1/users</code> vào trình duyệt và nhận được dữ liệu thật từ PostgreSQL đang chạy trên server của bạn.</p>
<p><strong>Chưa cần tên miền. Chưa cần HTTPS. Hệ thống đã chạy.</strong></p>
</div>

## 5.9 · Kiểm tra bảo mật — và sửa một lỗ hổng có thật

Deploy chạy được **chưa có nghĩa là an toàn**. Hãy soát lại bằng đúng công cụ của Lesson 03.

**Bước 1 — xem mọi cổng đang mở ra ngoài:**

```
docker ps --format '{{.Names}}\t{{.Ports}}'
```

**Bước 2 — kiểm tra từng service có bị publish ra ngoài không.**

Đây mới là phép thử **chắc chắn**, vì nó hỏi thẳng Docker thay vì đoán qua cổng:

```
for c in quickbite5-user quickbite5-restaurant quickbite5-order quickbite5-notification quickbite5-db; do
  printf '%-28s %s\n' "$c" "$(docker inspect $c --format '{{.HostConfig.PortBindings}}')"
done
```

**Phải thấy `map[]` ở cả năm dòng.** Dòng nào khác `map[]` là service đó **đang mở ra ngoài**.

Thử thêm từ máy bạn cho trực quan:

```
curl --max-time 5 http://13.210.134.235:8081/users
```

**Phải thấy:** treo rồi timeout, hoặc `Connection refused`.

> ⚠️ **Nếu lệnh `curl` này lại trả về một mã HTTP nào đó, đừng vội kết luận service bị hở.** Có thể **một container khác** trên cùng máy đang nghe cổng 8081 và trả lời thay. Trên máy cá nhân dùng cho nhiều buổi học, chuyện này rất hay xảy ra — chính tài liệu này đã gặp khi chạy thử.
>
> **Kết luận dựa vào `docker inspect` ở trên**, không dựa vào `curl`. Muốn biết ai đang giữ cổng:
> ```
> docker ps --format '{{.Names}}\t{{.Ports}}' | grep 8081
> ```

**Bước 3 — bạn sẽ phát hiện database đang hở.**

Mở `quickbite5-db/docker-compose.yml` và nhìn kỹ:

```yaml
services:
  quickbite5-db:
    image: postgres:15-alpine
    ports:
      - "5433:5432"     ← DÒNG NÀY MỞ DATABASE RA INTERNET
```

> ⚠️ **Dòng này hoàn toàn hợp lý ở Session 05** — lúc đó ta chạy trên máy cá nhân và cần nối DBeaver vào xem dữ liệu. Nhưng trên một **server public**, nó có nghĩa là **bất kỳ ai trên Internet cũng gõ cửa PostgreSQL của bạn được**, và mật khẩu lại là mật khẩu demo.
>
> Đây chính là loại lỗi mà Lesson 03 mục 3.4 cảnh báo: **UFW không cứu được bạn**, vì Docker publish cổng ở tầng thấp hơn.

**Sửa:** xoá hai dòng `ports:` đó đi.

```
nano ~/project-demo/session-05/quickbite5-db/docker-compose.yml
```
```
cd ~/project-demo/session-05/quickbite5-db && docker compose up -d --force-recreate
```

**Bước 4 — xác nhận đã bịt:**

```
docker inspect quickbite5-db --format '{{.HostConfig.PortBindings}}'
```

**Phải thấy:** `map[]` — rỗng, không còn ánh xạ cổng nào.

```
cd ../stack && docker compose restart && sleep 30
curl http://13.210.134.235:8080/api/v1/users
```

> ✅ **Hệ thống vẫn chạy bình thường sau khi bịt cổng database** — đã kiểm chứng thật. Lý do: các service nói chuyện với database **qua mạng Docker nội bộ**, chúng chưa bao giờ cần tới cổng publish trên máy chủ. Cổng đó chỉ phục vụ con người ngồi ngoài nối vào.
>
> 💡 **Vậy muốn xem database thì làm sao?** Dùng **SSH tunnel** — không phải mở cổng:
> ```
> ssh -L 5433:localhost:5433 deployer@13.210.134.235
> ```
> Rồi nối DBeaver vào `localhost:5433` ở máy bạn. Dữ liệu đi trong đường hầm SSH đã mã hoá, và **không có cổng nào mở ra Internet**.

## 5.10 · Checklist "chạy được ngay sau buổi học"

**Trên server**

- [ ] `docker --version`, `docker compose version`, `git --version` đều chạy
- [ ] Đã `git clone` repo về và thấy thư mục `session-05`
- [ ] Đã `cp .env.example .env`, điền đủ giá trị khớp `init-db.sql`, `chmod 600`
- [ ] `git check-ignore -v .env` xác nhận `.env` không bị commit
- [ ] Đã tạo swap nếu RAM ≤ 2 GB
- [ ] `./build-all.sh` chạy xong, đủ 5 file JAR
- [ ] `./start-all.sh` chạy xong, `docker compose ps` thấy 5 container `Up`

**Bảo mật**

- [ ] `docker ps` cho thấy **chỉ gateway** có mũi tên cổng
- [ ] `docker inspect quickbite5-db` trả về `PortBindings = map[]`
- [ ] Gọi thẳng `http://<ip>:8081` **không được**
- [ ] UFW chỉ mở OpenSSH, 80, 443 và 8080
- [ ] 🌐 AWS: Security Group cũng chỉ mở đúng những cổng đó

**Bằng chứng deploy thành công**

- [ ] `curl http://<ip>:8080/api/v1/users` trả về dữ liệu thật
- [ ] Cả 4 route `users` / `restaurants` / `orders` / `notifications` đều trả `200`
- [ ] Mở được trên trình duyệt từ một máy khác
- [ ] `sudo reboot` rồi hệ thống **tự lên lại** (nhờ `restart: always`)

## 5.11 · Khi hỏng thì tìm ở đâu

| Triệu chứng | Nguyên nhân thường gặp | Kiểm tra bằng |
|---|---|---|
| `curl` từ máy bạn **treo rồi timeout** | Chưa mở cổng 8080 ở UFW, hoặc 🌐 chưa mở ở Security Group | `sudo ufw status` và kiểm tra inbound rules |
| `Connection refused` ngay lập tức | Gateway chưa chạy | `docker compose ps` |
| Gateway trả **503 Service Unavailable** | Service đích chưa sẵn sàng, hoặc gateway còn cache DNS cũ | `docker compose restart api-gateway` |
| Gateway trả **404** | Sai đường dẫn — phải có đủ `/api/v1/` | Đối chiếu bảng ở mục 5.8 |
| Service chết ngay khi bật | `.env` sai mật khẩu, không khớp `init-db.sql` | `docker compose logs user-service` |
| Build dừng giữa chừng không báo lỗi rõ | **Hết RAM** khi Gradle chạy | `free -h`, tạo swap rồi build lại |
| Container `Up` nhưng API không trả lời | Ứng dụng bên trong đã chết | `docker compose logs --tail=50 <service>` |
| Mọi thứ hỏng sau khi sửa `.env` | Container chưa đọc lại biến mới | `docker compose up -d --force-recreate` |

> 💡 **Thứ tự chẩn đoán luôn đi từ ngoài vào trong:** tường lửa → gateway → service → database. Đừng nhảy thẳng vào đọc log ứng dụng khi chưa chắc gói tin có tới được server hay không.

## 5.12 · Bước tiếp theo sau buổi học

Hệ thống đã chạy bằng IP. Ba việc nên làm tiếp, theo thứ tự ưu tiên:

| Ưu tiên | Việc | Vì sao |
|---|---|---|
| **1** | Đổi mật khẩu database khỏi giá trị demo | Mật khẩu trùng tên user là mời gọi |
| **2** | Gắn **tên miền + HTTPS** qua reverse proxy (Caddy/Nginx) | Trình duyệt cảnh báo "Not secure" với HTTP thuần |
| **3** | Đẩy 5 image lên **Registry** rồi server chỉ `pull` | Server không phải build nữa — đúng tinh thần Session 08 |

> 💡 **Việc số 3 mới là đích đến thật sự.** Hiện tại server vẫn phải build, nên mỗi lần deploy mất 5–15 phút và tốn RAM. Khi cả 5 service đã có image trên Registry, quy trình rút gọn thành `docker compose pull && docker compose up -d` — vài giây, và **giống hệt nhau trên mọi server**.

---

# TỔNG KẾT

| Lesson | Nội dung | Kết quả |
|---|---|---|
| **01** | Khởi tạo VPS: thuê máy, khởi tạo ban đầu | Nền sạch, đã vá, có baseline |
| **02** | SSH hardening: thay thế đăng nhập root và mật khẩu | **Chỉ bạn vào được** |
| **03** | Cài Docker và firewall để bảo vệ VPS | **Đóng hết, chỉ mở thứ cần** |
| **04** | Đưa dự án lên và khởi chạy thực tế | Dịch vụ sống, **database không lộ** |

## Ba điều nếu chỉ nhớ được ba điều

1. **Thử trước, khoá sau.** Khi thay đổi chính cái đường mình đang đứng trên đó, luôn giữ đường cũ mở.
2. **Dòng `ports` trong Compose là quyết định bảo mật.** Bật UFW không cứu được bạn khỏi một dòng `"5432:5432"`.
3. **"Chạy lệnh thành công" không bằng "hệ thống hoạt động".** Chỉ health check và dữ liệu thật mới là bằng chứng.

# Bảng tra nhanh

| Việc | Lệnh |
|---|---|
| Tạo khoá SSH | `ssh-keygen -t ed25519 -C "ghi-chu" -f ~/.ssh/ten-khoa` |
| Đăng nhập bằng khoá | `ssh -i ~/.ssh/ten-khoa deployer@<ip>` |
| Đặt bí danh máy chủ | Thêm khối `Host` vào `~/.ssh/config`, rồi `ssh <bi-danh>` |
| Giữ tác vụ dài không chết khi rớt mạng | `tmux new -s deploy` → `Ctrl+B` `D` → `tmux attach -t deploy` |
| Xem quyền cả đường dẫn | `namei -l /home/deployer/.ssh/authorized_keys` |
| Kiểm tra cú pháp SSH **trước khi** reload | `sudo sshd -t` |
| Xem cấu hình SSH **đang chạy** | `sudo sshd -T \| grep passwordauth` |
| Xem log đăng nhập SSH | `sudo journalctl -u ssh --since "10 minutes ago"` |
| Kiểm chứng Docker cài đúng nguồn | `apt-cache policy docker-ce` |
| Chặn hết đầu vào | `sudo ufw default deny incoming` |
| Mở SSH **trước khi** bật | `sudo ufw allow OpenSSH` |
| Xem trạng thái tường lửa | `sudo ufw status verbose` |
| Kiểm tra `.env` bị Git bỏ qua chưa | `git check-ignore -v .env` |
| Kiểm tra cú pháp Compose | `docker compose config --quiet` |
| Kéo image về trước | `docker compose pull` |
| Dựng lên | `docker compose up -d` |
| Xem cổng có bị publish ra ngoài không | `docker inspect <ten> --format '{{.HostConfig.PortBindings}}'` |

# Từ khoá cần phân biệt

| Cặp khái niệm | Khác nhau ở |
|---|---|
| Khoá riêng ↔ Khoá công khai | Chìa (ở lại máy bạn) ↔ Ổ khoá (gắn lên máy chủ) |
| `apt update` ↔ `apt upgrade` | Tải danh mục ↔ Cài thật |
| `sshd -t` ↔ `sshd -T` | Kiểm tra cú pháp ↔ In cấu hình **đang chạy** |
| `Permission denied` ↔ `Connection timed out` | Bị từ chối ↔ **Không tới được** (tường lửa) |
| SSH key đăng nhập ↔ Deploy key | Local → VPS ↔ VPS → GitHub (read-only) |
| `.env.example` ↔ `.env` | Mẫu, có commit ↔ Thật, **không bao giờ** commit |
| `build:` ↔ `image:` | Tự biên dịch (S04) ↔ **Kéo từ Registry về** (S10) |
| `"8081:8081"` ↔ `"127.0.0.1:8081:8081"` | Cả Internet ↔ Chỉ chính máy chủ |
| Docker CE ↔ Docker Business | Community, miễn phí ↔ Bản trả phí |
| SFTP ↔ Git + Registry | Nhanh, **không có lịch sử** ↔ Có truy vết đầy đủ |
