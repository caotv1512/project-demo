# GIÁO TRÌNH BUỔI DẠY — SESSION 07
# Tự động hoá quy trình CI/CD với GitHub Actions

> **Thời lượng:** 180 phút (3 tiếng)
> **Điều kiện tiên quyết:** Session 04–05 (Dockerfile, Compose, microservices). Biết dùng Git cơ bản: commit, push, branch.
> **Mục tiêu đầu ra:** sinh viên viết được workflow CI/CD, hiểu cơ chế Job, đọc được log lỗi, và triển khai được lên 3 môi trường staging / uat / release.

> 🔗 **Repo demo có thật:** `github.com/caotv1512/project-demo` — 5 workflow và 3 nhánh môi trường đã chạy thật, dùng để chiếu trực tiếp trên lớp.

---

## 0. BẢNG PHÂN BỔ THỜI GIAN

| Phần | Nội dung | Thời lượng | Hình thức |
|---|---|---|---|
| 0 | Khởi động – Đặt vấn đề | 10' | Hỏi đáp |
| 1 | Tổng quan GitHub Actions và kiến trúc Runner | 30' | Lý thuyết |
| 2 | Cấu trúc workflow CI/CD cơ bản | 30' | Lý thuyết + demo |
| — | **NGHỈ GIẢI LAO** | 10' | |
| 3 | Điều phối và phân tách Jobs | 30' | Demo |
| 4 | Build Spring Boot bằng Gradle trong CI | 25' | Demo |
| 5 | Triển khai 3 môi trường staging / uat / release | 25' | Demo |
| 6 | Chẩn đoán sự cố và quản trị log | 20' | Demo |
| 7 | Tổng kết – Q&A – Giao bài tập | 10' | |

---

## PHẦN 0 — KHỞI ĐỘNG & ĐẶT VẤN ĐỀ (10 phút)

### 0.1. Ba câu hỏi mở đầu

Viết lên bảng, chưa trả lời ngay:

**① Ai đảm bảo code đẩy lên không làm hỏng nhánh chung?** Hôm nay bạn sửa vội một dòng rồi push thẳng lên `develop`. Không chạy test. Cả nhóm 8 người `pull` về và ai cũng bị lỗi. Làm sao ngăn được chuyện này?

**② "Máy tôi chạy được mà" — nhưng máy ai?** Bạn dùng JDK 21, đồng nghiệp dùng JDK 17. Code bạn viết biên dịch được ở máy bạn, sập ở máy họ. Lấy môi trường nào làm chuẩn?

**③ Code đã test xong, giờ đưa lên server thế nào?** Copy file JAR bằng tay qua SCP? Ai làm? Làm lúc nào? Lỡ copy nhầm bản cũ thì sao?

> Ba câu hỏi ứng với ba chữ: **CI** (tích hợp liên tục), **chuẩn hoá môi trường**, và **CD** (chuyển giao liên tục).

### 0.2. Thách thức thực tế trong dự án QuickBite

| Vấn đề | Biểu hiện |
|---|---|
| **Quên chạy Unit Test** | Lập trình viên quên chạy test cục bộ hoặc không biên dịch thử trước khi đẩy code lên Git |
| **Hậu quả nghiêm trọng** | Code lỗi cú pháp hoặc hỏng logic vẫn bị merge vào nhánh chung (`main`, `develop`), gây gãy đổ luồng phát triển |
| **Khác biệt môi trường** | "Chạy tốt trên máy tôi" nhưng sập ở nơi khác do lệch phiên bản JDK (17 vs 21) |

### 0.3. Giải pháp: tự động hoá tập trung

1. **Xây dựng máy chủ độc lập (Runner)** — một môi trường build biệt lập, chuyên kéo mã nguồn mới nhất về.
2. **Kiểm thử liên tục (CI)** — tự động chạy toàn bộ Unit Test ngay khi có thay đổi code.
3. **Chuẩn hoá biên dịch** — đảm bảo mã nguồn được đóng gói đồng nhất trên **một** phiên bản JDK tiêu chuẩn.

> **Điểm cần nhấn mạnh ngay:** CI **không** làm code của bạn tốt hơn. Nó chỉ **phát hiện sớm** khi code hỏng, và **chặn** code hỏng lọt vào nhánh chung. Chất lượng vẫn do người viết quyết định — CI là cái lưới an toàn, không phải phép màu.

---

## PHẦN 1 — TỔNG QUAN GITHUB ACTIONS & KIẾN TRÚC RUNNER (30 phút)

### 1.1. Khái niệm cốt lõi CI/CD

#### Continuous Integration (CI) — Tích hợp liên tục

- **Tự động hoá toàn diện:** kéo mã nguồn mới nhất từ kho lưu trữ chung ngay khi có thay đổi.
- **Kiểm tra chất lượng & biên dịch:** chạy Linter quét lỗi cú pháp, chuẩn hoá định dạng, rồi biên dịch ứng dụng.
- **Chạy kiểm thử:** kích hoạt toàn bộ Unit Tests và Integration Tests để phát hiện sớm xung đột logic.
- **Mục tiêu cốt lõi:** đảm bảo mã nguồn mới khi tích hợp vào nhánh chung **luôn ở trạng thái biên dịch thành công và an toàn**.

#### Continuous Delivery / Deployment (CD)

| | Continuous **Delivery** | Continuous **Deployment** |
|---|---|---|
| Đóng gói thành phẩm (JAR, Docker image) | Tự động | Tự động |
| Đẩy lên Registry | Tự động | Tự động |
| Triển khai lên Production | **Có bước xác nhận thủ công** | **Tự động 100%**, không cần người |

> **Hai chữ CD rất dễ nhầm.** Cả hai đều viết tắt là CD nhưng khác nhau ở **một bước duy nhất**: có cần người bấm nút duyệt không.
> Delivery = "luôn *sẵn sàng* để phát hành". Deployment = "tự động *phát hành* luôn".
> Đa số doanh nghiệp Việt Nam dừng ở **Delivery** — và đó là lựa chọn hợp lý, không phải thiếu sót.

### 🔍 GIẢI THÍCH TƯỜNG TẬN — Vì sao CI lại quan trọng đến thế?

**Cách dẫn dắt trên lớp (nên hỏi trước khi giảng):**

> *"Nhóm 8 người cùng làm một dự án. Mỗi người một nhánh. Cuối tuần merge hết vào `develop`. Chuyện gì xảy ra?"*

Để sinh viên trả lời, rồi chốt bằng con số:

| Tần suất tích hợp | Số xung đột trung bình mỗi lần | Thời gian sửa |
|---|---|---|
| Mỗi tuần một lần | Rất nhiều, chồng chéo | Cả ngày |
| Mỗi ngày một lần | Vài chỗ nhỏ | Vài chục phút |
| **Mỗi lần commit** | Gần như không có | Vài phút |

**Chữ "Continuous" chính là mấu chốt.** Không phải "tự động" — mà là **"liên tục"**, tức *tích hợp thường xuyên đến mức mỗi lần chỉ có một thay đổi nhỏ để đối chiếu*. Tự động hoá chỉ là phương tiện để làm được điều đó mà không mệt.

**Ẩn dụ nên dùng:** CI giống như **rửa bát ngay sau khi ăn**, thay vì dồn cả tuần. Cùng một khối lượng công việc, nhưng dồn lại thì vừa khó rửa vừa bốc mùi.

**Ba điều CI *không* làm — phải nói rõ để sinh viên không kỳ vọng sai:**

| CI KHÔNG làm | Vì sao |
|---|---|
| Không làm code bạn đúng hơn | Nó chỉ chạy đúng những test bạn viết. Không viết test thì CI xanh vô nghĩa |
| Không thay thế code review | Máy kiểm tra được cú pháp, không kiểm tra được thiết kế tồi |
| Không bắt được lỗi nghiệp vụ | Test chỉ so sánh kết quả với **kỳ vọng do bạn đặt ra**. Kỳ vọng sai thì test sai theo |

> **Câu chốt nên viết lên bảng:** *"CI xanh không có nghĩa code đúng. CI đỏ chắc chắn có nghĩa code sai."*
> Đây là mệnh đề một chiều — sinh viên rất hay hiểu ngược.

### 1.2. Kiến trúc điều phối Server – Runner

```
        ┌─────────────────────────────────┐
        │        GitHub Server            │
        │   (Web UI + Git Repository)     │
        └───────────────┬─────────────────┘
                        │  REST API / Polling
                        ▼
        ┌─────────────────────────────────┐
        │    GitHub Actions Runner        │
        │      (máy chủ thực thi)         │
        │  Polling → Lấy Jobs → Thực thi  │
        └───────────────┬─────────────────┘
                        │  (chạy Jobs)
                        ▼
        ┌─────────────────────────────────┐
        │      Môi trường Host OS         │
        │   Docker / Container · Host OS  │
        └─────────────────────────────────┘
```

| Thành phần | Nhiệm vụ |
|---|---|
| **GitHub Server** | Lưu mã nguồn · Quản lý workflow (`.github/workflows/*.yml`) · Cung cấp API cho Runner lấy job · Giao diện web |
| **Runner** | Đăng ký với GitHub Server · Polling để lấy job · Thực thi job · Gửi kết quả, log, trạng thái về Server |
| **Host OS** | Nơi job thật sự chạy · Có thể là Docker container hoặc OS trực tiếp · Cung cấp công cụ build · Cô lập môi trường |

**Luồng tổng quát:**
```
Push code → GitHub tạo Workflow → Runner lấy Jobs → Thực thi → Gửi kết quả về GitHub
```

> **Chi tiết quan trọng mà sơ đồ nói rõ:** Runner **chủ động polling** hỏi GitHub "có việc gì cho tôi không?", chứ GitHub **không** chủ động đẩy việc xuống. Đây là lý do một self-hosted runner đặt sau tường lửa công ty vẫn hoạt động được — nó chỉ cần gọi **ra ngoài**, không cần mở cổng vào.

### 🔍 GIẢI THÍCH TƯỜNG TẬN — Chuyện gì xảy ra trong 3 giây sau khi bạn gõ `git push`?

Đây là phần sinh viên mơ hồ nhất. Hãy kể theo **trình tự thời gian**, như kể chuyện:

| Giây | Việc xảy ra | Diễn ra ở đâu |
|---|---|---|
| 0.0 | Bạn gõ `git push` | Máy bạn |
| 0.5 | GitHub nhận commit, ghi vào repository | Máy chủ GitHub |
| 0.6 | GitHub đọc **mọi file** trong `.github/workflows/` | Máy chủ GitHub |
| 0.7 | Với mỗi file, kiểm tra khối `on:` — sự kiện này có khớp không? | Máy chủ GitHub |
| 0.8 | File nào khớp → tạo một **workflow run**, đưa các job vào **hàng đợi** | Máy chủ GitHub |
| 1–20 | Runner rảnh polling thấy job → nhận về | Runner |
| 20+ | Runner **tạo máy ảo mới tinh**, chạy từng step | Runner |
| … | Sau mỗi step, Runner gửi log về GitHub theo thời gian thực | Runner → GitHub |

**Ba điều rút ra từ trình tự này — nên hỏi ngược lại sinh viên:**

**① "Vì sao đôi khi push xong mà chờ mãi chưa thấy chạy?"**
→ Job đang nằm trong **hàng đợi**, chưa có Runner nào rảnh. Trạng thái `Queued`. Không phải hỏng.

**② "Vì sao sửa file YAML ở nhánh A mà nhánh B không bị ảnh hưởng?"**
→ Vì GitHub đọc file workflow **ở đúng commit vừa được push**. Mỗi nhánh có bản YAML riêng của nó.

**③ "Vì sao log hiện dần từng dòng chứ không đợi xong mới hiện?"**
→ Vì Runner **stream** log về GitHub liên tục trong lúc chạy. Bạn đang xem gần như trực tiếp.

### 🔍 GIẢI THÍCH TƯỜNG TẬN — "Máy ảo mới tinh" nghĩa là gì?

Sinh viên hay tưởng tượng Runner như một cái máy tính luôn bật, chạy hết job này tới job khác. **Không phải.**

Với GitHub-hosted runner, **mỗi job** được cấp:
- Một máy ảo **hoàn toàn mới**, vừa được tạo ra
- Ổ đĩa trống, chỉ có hệ điều hành và vài công cụ cài sẵn
- Chạy xong job là **máy ảo bị huỷ vĩnh viễn**

**Cách chỉ cho sinh viên thấy ngay trên lớp:**

```yaml
- name: Tạo một file
  run: echo "xin chao" > /tmp/dau-vet.txt

- name: Tìm lại file đó
  run: ls -la /tmp/dau-vet.txt    # thấy, vì cùng job
```

Nhưng đặt bước thứ hai sang **job khác** thì không thấy. Workflow `02` trong project mẫu đã làm sẵn thí nghiệm này.

**Hệ quả thực tế của "máy ảo mới tinh":**

| Điều này đúng | Vì sao |
|---|---|
| Không bị nhiễm bẩn từ lần chạy trước | Máy mới nên sạch tuyệt đối |
| Build lần nào cũng như lần nào | Không có "máy tôi có sẵn cái này" |
| **Nhưng phải tải lại thư viện mỗi lần** | Nên mới cần `cache: gradle` |
| Không lưu được gì giữa các lần chạy | Nên mới cần Artifacts |

> **Đây là gốc rễ của phần lớn câu hỏi trong buổi học.** Hiểu "máy ảo mới tinh mỗi job" thì tự trả lời được: vì sao phải `checkout` lại, vì sao cần artifact, vì sao cần cache, vì sao self-hosted nhanh hơn.

### 1.3. GitHub-hosted vs Self-hosted Runner

| | **GitHub-hosted** | **Self-hosted** |
|---|---|---|
| Ai quản lý | GitHub quản lý hoàn toàn | Bạn tự cài đặt và quản trị |
| Môi trường | Máy ảo **mới hoàn toàn** cho mỗi job → luôn sạch | VPS / VM / máy chủ vật lý riêng |
| Tài nguyên | Giới hạn (2 vCPU, 7GB RAM) | Tuỳ biến không giới hạn, có cache cục bộ |
| Chi phí | Giới hạn thời gian chạy miễn phí | **Miễn phí thời gian chạy** |
| Phù hợp | Dự án vừa và nhỏ, không muốn quản lý hạ tầng | Dự án build liên tục, cần tối ưu tốc độ và chi phí |

> **Đánh đổi thật sự nằm ở chỗ này:** máy ảo sạch mỗi lần chạy vừa là **ưu điểm** (không bị nhiễm bẩn từ lần chạy trước) vừa là **nhược điểm** (phải tải lại toàn bộ thư viện mỗi lần → chậm). Self-hosted giữ được cache nên build nhanh hơn nhiều, nhưng bạn phải tự chịu trách nhiệm dọn dẹp — và một runner bị "bẩn" có thể khiến build **pass giả** trong khi lẽ ra phải fail.

> ⚠️ **Cảnh báo bảo mật cần nói với sinh viên:** tuyệt đối **không** dùng self-hosted runner cho repository **public**. Bất kỳ ai gửi Pull Request đều có thể chạy code tuỳ ý trên máy của bạn. Self-hosted chỉ dùng cho repo private hoặc nội bộ công ty.

**Trong project demo của buổi học này:** dùng `ubuntu-latest` (GitHub-hosted) để chạy được ngay mà không phải cài runner agent. Slide dạy `[self-hosted, quickbite]` — khác biệt duy nhất là **một dòng `runs-on`**, toàn bộ phần còn lại giữ nguyên.

---

## PHẦN 2 — CẤU TRÚC WORKFLOW CI/CD CƠ BẢN (30 phút)

### 2.1. Quy ước vị trí và định dạng

- **Đường dẫn bắt buộc:** mọi kịch bản workflow phải đặt trong `.github/workflows/` tại **thư mục gốc** của repository.
- **Định dạng:** cú pháp YAML, đuôi `.yml` hoặc `.yaml`.
- **Ví dụ:** `.github/workflows/ci.yml`

> **Ba chỗ sai là workflow không bao giờ chạy — và GitHub không báo gì cả:**
> 1. Đặt nhầm `.github/workflow/` (thiếu chữ **s**)
> 2. Đặt ở thư mục con thay vì gốc repository
> 3. Sai thụt lề YAML — file không hợp lệ thì GitHub bỏ qua luôn
>
> Không có thông báo lỗi. Tab Actions chỉ đơn giản là trống. Đây là trải nghiệm bực bội nhất của người mới.

### 2.2. Phân cấp cấu trúc Workflow

```
Workflow  (toàn bộ pipeline — 1 file YAML)
│
├── Job A  ─┐
├── Job B  ─┤  mặc định chạy SONG SONG, mỗi job một Runner riêng
└── Job C  ─┘
     │
     └── Step 1 ─┐
         Step 2 ─┤  chạy TUẦN TỰ, cùng một Runner, chung workspace
         Step 3 ─┘
              │
              ├── uses:  gọi Action đóng gói sẵn
              └── run:   chạy lệnh shell trực tiếp
```

| Cấp | Định nghĩa |
|---|---|
| **Workflow** | Toàn bộ pipeline tự động hoá cao nhất, định nghĩa trong một file YAML riêng |
| **Jobs** | Tập hợp công việc. Mặc định chạy **song song, độc lập** trên các Runner khác nhau |
| **Steps** | Các bước **tuần tự** trong một Job. Cùng Runner, **chung thư mục làm việc** |
| **Actions** | Khối lệnh viết sẵn, gọi qua `uses` (ví dụ `actions/checkout`, `actions/setup-java`) |
| **Run** | Thực thi lệnh shell trực tiếp trên Runner qua `run:` |

### 2.3. Các từ khoá cú pháp nền tảng

| Từ khoá | Nhiệm vụ |
|---|---|
| `name` | Tên hiển thị của workflow trên giao diện GitHub Actions |
| `on` | Sự kiện kích hoạt (`push`, `pull_request`…) kèm bộ lọc theo nhánh |
| `env` | Biến môi trường dùng chung toàn workflow |
| `jobs` | Chứa một hoặc nhiều công việc chạy độc lập, song song |
| `runs-on` | Chỉ định Runner thực thi (`ubuntu-latest` hoặc `[self-hosted, quickbite]`) |
| `steps` | Tập hợp các bước tuần tự trong một Job |

### 2.4. Workflow đầu tiên — in thông tin môi trường

```yaml
name: Print Environment Info

on:
  push:
    branches:
      - main

env:
  PROJECT_NAME: "QuickBite-User-Service"

jobs:
  print_env_job:
    runs-on: ubuntu-latest        # slide dạy [self-hosted, quickbite]
    steps:
      - name: Lấy mã nguồn về máy Runner
        uses: actions/checkout@v4

      - name: Thiết lập môi trường Java 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: In thông tin môi trường
        run: |
          echo "Chuẩn bị in thông tin cho dự án ${PROJECT_NAME}..."
          java -version
          echo "Nhánh Git đang chạy workflow là ${GITHUB_REF_NAME}"
```

### 🔍 GIẢI THÍCH TƯỜNG TẬN — Đọc file YAML theo đúng thứ tự máy đọc

Sinh viên hay đọc file YAML từ trên xuống như đọc văn. **Máy không đọc như vậy.** Hãy dạy đọc theo 4 câu hỏi:

| Thứ tự | Câu hỏi | Nhìn vào từ khoá |
|---|---|---|
| **1** | *Khi nào chạy?* | `on:` |
| **2** | *Chạy ở đâu?* | `runs-on:` |
| **3** | *Làm những việc gì?* | `steps:` |
| **4** | *Có phụ thuộc gì không?* | `needs:` |

Áp vào file mẫu:

```yaml
name: Print Environment Info     # (4) tên hiển thị — không ảnh hưởng gì tới việc chạy

on:                              # (1) KHI NÀO
  push:
    branches: [main]             #     chỉ khi push lên nhánh main

jobs:
  print_env_job:                 #     tên job — bạn tự đặt, hiện trên giao diện
    runs-on: ubuntu-latest       # (2) Ở ĐÂU — máy ảo Ubuntu của GitHub
    steps:                       # (3) LÀM GÌ — chạy tuần tự từ trên xuống
      - uses: actions/checkout@v5
      - uses: actions/setup-java@v5
      - run: java -version
```

### 🔍 GIẢI THÍCH TƯỜNG TẬN — `uses` và `run` khác nhau chỗ nào?

Đây là cặp khái niệm sinh viên nhầm nhiều nhất trong phần này.

| | `uses` | `run` |
|---|---|---|
| Bản chất | Gọi **một chương trình người khác viết sẵn** | Chạy **lệnh shell** của chính bạn |
| Ví dụ | `uses: actions/checkout@v5` | `run: ./gradlew test` |
| Tham số truyền thế nào | Qua khối `with:` | Viết thẳng vào dòng lệnh |
| Chạy trên gì | JavaScript hoặc Docker, do Action quy định | `bash` trên Runner |

**Ẩn dụ dễ nhớ:** `uses` là **gọi hàm thư viện**, `run` là **tự viết code**.

**Vì sao `actions/checkout` phải là một Action chứ không phải `run: git clone`?**

Hỏi câu này để sinh viên thấy giá trị của Action. Bởi vì `checkout` phải lo rất nhiều việc:
- Xác thực bằng token tạm thời (không lộ mật khẩu)
- Chỉ tải đúng commit đang được build, không tải cả lịch sử (nhanh hơn nhiều)
- Xử lý submodule, LFS, symlink
- Dọn sạch thư mục làm việc trước khi tải

Viết tay bằng `git clone` thì phải tự lo hết. Action đóng gói sẵn tất cả.

**Con số sau `@` là gì?**

```
actions/checkout@v5
   ↑        ↑     ↑
  chủ sở   tên   phiên bản
```

> ⚠️ **Luôn ghim phiên bản.** Viết `@v5` thì hôm nay và một năm nữa đều chạy giống nhau. Không ghim (hoặc dùng `@main`) thì một ngày đẹp trời tác giả đổi code, pipeline của bạn hỏng mà bạn **không sửa gì cả**.

**Hai loại biến môi trường — phân biệt rất quan trọng:**

| Loại | Ví dụ | Ai tạo ra |
|---|---|---|
| **Tự định nghĩa** | `PROJECT_NAME` | Bạn khai báo trong khối `env` |
| **Hệ thống tiêm sẵn** | `GITHUB_REF_NAME`, `GITHUB_SHA`, `GITHUB_ACTOR` | GitHub Actions tự động tiêm vào Runner |

> **Lưu ý:** không cần khai báo `GITHUB_REF_NAME` trong `env` — Runner vẫn tự hiểu và lấy được tên nhánh hiện tại.

> 💡 **Mẹo dạy học rất hữu ích:** thêm `workflow_dispatch:` vào khối `on`. Khi đó tab Actions sẽ có nút **Run workflow** để bấm chạy tay — không cần push code vẫn demo được. Cả 5 workflow trong project mẫu đều có nút này.

---

## ☕ NGHỈ GIẢI LAO (10 phút)

---

## PHẦN 3 — ĐIỀU PHỐI VÀ PHÂN TÁCH JOBS (30 phút)

### 3.1. Song song mặc định, tuần tự bằng `needs`

**Hành vi mặc định — song song:**
```
Job A ─┐
Job B ─┼─ chạy đồng thời, tối ưu tốc độ pipeline
Job C ─┘
```
Các job ngang hàng tự động được kích hoạt **cùng lúc**.

**Ràng buộc tuần tự với `needs`:**
```yaml
job_print:
  needs: [job_info_1, job_info_2]
```
- Job B bị khoá ở trạng thái `Pending` cho tới khi Job A hoàn thành **thành công**.
- **Chốt chặn bảo mật:** nếu Job A thất bại, hệ thống tự động **bỏ qua (Skipped)** các job phụ thuộc phía sau để bảo vệ tài nguyên.

> **Demo nên làm live:** project mẫu có workflow `02-jobs-song-song-va-needs.yml` với nút bật/tắt gây lỗi. Chạy hai lần — một lần bình thường (thấy 2 job chạy song song, dấu thời gian trùng nhau), một lần bật gây lỗi (thấy job sau bị `Skipped` màu xám). Sơ đồ trực quan trên giao diện GitHub rất thuyết phục.

### 3.2. Cơ chế cô lập công việc (Job Isolation)

**Nguyên lý:**
- **Không gian riêng biệt:** mỗi job chạy trong môi trường sạch, hoàn toàn độc lập và khép kín.
- **Không chia sẻ tự động:** file sinh ra ở Job A **không** tự động dùng được ở Job B.
- **Yêu cầu tái khởi tạo:** để Job B có mã nguồn, **bắt buộc** phải khai báo lại `actions/checkout` ở bước đầu tiên của Job B.

> ⚠️ **Đây là hiểu nhầm phổ biến nhất khi mới học.** Sinh viên hay nghĩ các job nối tiếp nhau trên cùng một máy, giống như các dòng trong một script. **Không phải.** Mỗi job là một **máy ảo hoàn toàn mới**. Kể cả khi có `needs`, Job B vẫn không thấy gì của Job A.

**Giải pháp chia sẻ dữ liệu — Artifacts:**

```
Job A ──(upload-artifact)──► Kho lưu trữ tạm GitHub ──(download-artifact)──► Job B
```

- **Upload Artifacts:** job trước đóng gói và đẩy kết quả lên bộ lưu trữ tạm.
- **Download Artifacts:** job sau kéo về không gian làm việc riêng để xử lý tiếp.

> **Đây là con đường duy nhất** để duy trì tính liên tục của dữ liệu mà vẫn giữ an toàn hệ thống.

### 🔍 GIẢI THÍCH TƯỜNG TẬN — Vì sao GitHub cố tình cô lập các job?

Sinh viên hay hỏi *"Sao không cho job dùng chung thư mục cho tiện?"*. Đây là câu hỏi hay, phải trả lời cho đến nơi.

**Ba lý do, theo thứ tự quan trọng:**

**① Để chạy song song được.** Nếu các job dùng chung thư mục, hai job ghi cùng một file cùng lúc sẽ hỏng dữ liệu. Muốn song song thì bắt buộc phải tách. Mà song song là thứ làm pipeline nhanh gấp 2–3 lần.

**② Để mỗi job chọn được môi trường riêng.** Job test cần JDK 17, job build Docker cần Docker, job deploy cần `kubectl`. Cô lập thì mỗi job tự cài đúng thứ mình cần, không đụng nhau.

**③ Để lỗi không lan.** Job A cài nhầm phiên bản thư viện, làm bẩn máy. Nếu dùng chung, job B kế thừa cái bẩn đó và **build ra kết quả sai mà vẫn xanh**. Cô lập chặn được chuyện này.

> **Câu chốt:** cô lập **không phải giới hạn kỹ thuật** mà là **lựa chọn thiết kế có chủ đích**. Đổi lại sự bất tiện (phải checkout lại, phải dùng artifact), bạn được tốc độ và độ tin cậy.

### 🔍 GIẢI THÍCH TƯỜNG TẬN — Artifact so với Cache

Hai thứ này đều "lưu file lại dùng sau" nên sinh viên nhầm liên tục. Bảng phân biệt:

| | **Artifact** | **Cache** |
|---|---|---|
| Để làm gì | Giữ **sản phẩm** bạn muốn lấy ra | Giữ **dữ liệu tạm** để chạy nhanh hơn |
| Ví dụ | File JAR, báo cáo test, ảnh chụp lỗi | Thư viện Gradle/npm tải về |
| Mất đi thì sao | **Mất luôn thành phẩm** | Chỉ chậm lại, tải lại là có |
| Tải về được không | **Có** — bấm nút trên giao diện | Không, chỉ máy dùng |
| Khai báo bằng | `actions/upload-artifact` | `cache: gradle` trong `setup-java` |

**Câu hỏi kiểm tra hiểu bài:** *"File JAR nên là artifact hay cache?"*
→ **Artifact.** Vì đó là thành phẩm cần lấy ra để triển khai. Thư viện Gradle mới là cache.

**Nếu vẫn nhầm, hỏi tiếp:** *"Xoá đi có tạo lại được không?"* Tạo lại được → cache. Mất là mất luôn → artifact.

### 3.3. Thực hành: luồng 3 jobs phụ thuộc

```yaml
jobs:
  job_info_1:
    runs-on: ubuntu-latest
    steps:
      - name: Thu thập thông tin OS
        run: uname -a

  job_info_2:
    runs-on: ubuntu-latest
    steps:
      - name: Thu thập thông tin User
        run: whoami

  job_print:
    needs: [job_info_1, job_info_2]
    runs-on: ubuntu-latest
    steps:
      - name: In kết quả
        run: echo "Chỉ chạy sau khi job_info_1 và job_info_2 thành công."
```

**Phân tích:**
- `job_info_1` và `job_info_2` **không** khai báo `needs` → tự động chạy **song song**.
- `job_print` khai báo `needs` → chỉ bắt đầu sau khi **cả hai** job trước hoàn thành thành công.

---

## PHẦN 4 — BUILD SPRING BOOT BẰNG GRADLE TRONG CI (25 phút)

### 4.1. Chuyển dịch từ Local Build sang CI Build

| | **Quy trình thủ công (Local)** | **Quy trình tự động (CI)** |
|---|---|---|
| Cài JDK | Từng người tự cài trên máy mình | Runner tự cài qua `actions/setup-java` |
| Biên dịch | Tự chạy `./gradlew bootJar` ở máy | Tự động chạy mỗi khi push code |
| Đưa lên server | Upload thủ công | Lưu vào Artifact / đẩy lên Registry |
| Rủi ro | **Phụ thuộc nặng vào máy cá nhân**, dễ lệch phiên bản JDK | Môi trường sạch, nhất quán mọi lần |

> **Tối ưu hiệu năng:** kịch bản CI chỉ chạy `bootJar` (chỉ đóng gói) thay vì `build` (đóng gói **kèm** chạy lại test), để tiết kiệm tài nguyên Runner — với điều kiện test đã chạy ở job trước.

### 4.2. Workflow biên dịch và lưu Artifact

```yaml
name: Build Spring Boot App
on:
  push:
    branches: [main]

jobs:
  build_executable_jar:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout mã nguồn
        uses: actions/checkout@v4

      - name: Cài đặt môi trường JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: gradle              # tăng tốc các lần chạy sau

      - name: Cấp quyền thực thi cho Gradle Wrapper
        run: chmod +x ./gradlew

      - name: Biên dịch và đóng gói tệp JAR
        run: ./gradlew bootJar

      - name: Lưu trữ sản phẩm (Artifact)
        uses: actions/upload-artifact@v4
        with:
          name: user-service-jar
          path: build/libs/*.jar
          retention-days: 3
```

> **Đồng bộ JDK linh hoạt:** áp dụng cho `restaurant-service` chỉ cần đổi `java-version` thành `'21'`. Toàn bộ phần còn lại giữ nguyên.

> 💡 **Nên bổ sung `cache: gradle`.** Không có nó, mỗi lần chạy Runner phải tải lại toàn bộ thư viện Spring Boot (~100MB) — mất 2–3 phút. Có cache, lần chạy thứ hai chỉ còn vài chục giây. Một dòng đổi lấy rất nhiều thời gian chờ.

---

## PHẦN 5 — TRIỂN KHAI 3 MÔI TRƯỜNG (25 phút)

> Phần này mở rộng ngoài slide, phục vụ yêu cầu thực tế của dự án.

### 5.1. Vì sao cần nhiều môi trường?

Không ai đưa code thẳng từ máy lập trình viên lên máy chủ khách hàng. Phải có các **trạm dừng** để kiểm chứng dần:

| Nhánh Git | Môi trường | Ai dùng | Mục đích |
|---|---|---|---|
| `staging` | Staging | Đội phát triển | Tích hợp code nhiều người, test nội bộ. Hỏng cũng không sao |
| `uat` | UAT (User Acceptance Test) | **Khách hàng / QA** | Nghiệm thu tính năng trước khi phát hành |
| `release` | Release | Đội vận hành | Bản ứng viên phát hành, đã đóng băng tính năng |

> **Điểm mấu chốt về mức độ rủi ro:** càng về sau, chi phí sửa sai càng đắt. Hỏng ở `staging` mất 5 phút. Hỏng ở `uat` mất uy tín với khách. Hỏng ở `release` mất tiền. Vì vậy mức độ kiểm soát phải **tăng dần**: `staging` tự động hoàn toàn, `uat` và `release` bắt buộc có người duyệt.

### 5.2. Một workflow phục vụ cả ba môi trường

Nguyên tắc: **không** viết 3 file YAML giống nhau. Viết **một** file, dùng tên nhánh để quyết định môi trường.

```yaml
on:
  push:
    branches: [staging, uat, release]

jobs:
  xac_dinh_moi_truong:
    runs-on: ubuntu-latest
    outputs:
      ten_moi_truong: ${{ steps.chon.outputs.ten_moi_truong }}
    steps:
      - id: chon
        run: |
          case "${{ github.ref_name }}" in
            staging) echo "ten_moi_truong=staging" >> $GITHUB_OUTPUT ;;
            uat)     echo "ten_moi_truong=uat"     >> $GITHUB_OUTPUT ;;
            release) echo "ten_moi_truong=release" >> $GITHUB_OUTPUT ;;
          esac

  trien_khai:
    needs: [xac_dinh_moi_truong]
    runs-on: ubuntu-latest
    environment:
      name: ${{ needs.xac_dinh_moi_truong.outputs.ten_moi_truong }}
    steps:
      - run: echo "Đang triển khai lên ${{ needs.xac_dinh_moi_truong.outputs.ten_moi_truong }}"
```

**Hai kỹ thuật mới ở đây:**

**① `outputs` — truyền giá trị giữa các job.** Job isolation nói rằng file không chia sẻ được, nhưng **giá trị chuỗi** thì có — qua `outputs`. Ghi bằng `echo "key=value" >> $GITHUB_OUTPUT`, đọc bằng `needs.<job>.outputs.<key>`.

**② `environment` — cơ chế môi trường của GitHub.** Vào *Settings → Environments* tạo `staging`, `uat`, `release`. Mỗi môi trường có:
- **Required reviewers** — job dừng lại chờ người bấm Approve
- **Variables / Secrets riêng** — cùng tên biến, giá trị khác nhau theo môi trường
- **Deployment branches** — giới hạn nhánh nào được triển khai lên môi trường đó

> **Đây chính là chỗ Continuous Delivery và Continuous Deployment tách đôi.** Bật *Required reviewers* cho `uat`/`release` → Delivery. Không bật gì → Deployment. Cùng một file YAML, khác nhau ở **cấu hình trên giao diện web**, không phải ở code.

### 5.3. Luồng thăng cấp code

```
   feature/*  ──PR──►  staging  ──PR──►  uat  ──PR──►  release  ──PR──►  main
                          │                │              │                │
                      tự động          cần duyệt      cần duyệt        production
```

> **Nguyên tắc vàng:** code chỉ đi **một chiều**, không bao giờ nhảy cóc. Muốn lên `release` thì phải qua `uat` trước. Có lỗi ở `uat` thì sửa ở nhánh nguồn rồi đẩy lại từ đầu — **không** sửa trực tiếp trên `uat`.

### 🔍 GIẢI THÍCH TƯỜNG TẬN — `outputs` hoạt động ra sao?

Phần này sinh viên bối rối vì vừa học "job không chia sẻ được gì" xong lại thấy job này đọc được giá trị của job kia.

**Mấu chốt: file không chia sẻ được, nhưng *chuỗi ký tự* thì có.**

GitHub giữ hộ một bảng nhỏ trong bộ nhớ của nó — không phải trên Runner:

```
Job "xac_dinh_moi_truong" chạy xong
        │
        │  ghi:  echo "ten_moi_truong=uat" >> $GITHUB_OUTPUT
        ▼
   ┌──────────────────────────────┐
   │  GitHub giữ hộ bảng giá trị  │
   │  xac_dinh_moi_truong:        │
   │     ten_moi_truong = "uat"   │
   └──────────────┬───────────────┘
                  │  đọc: needs.xac_dinh_moi_truong.outputs.ten_moi_truong
                  ▼
        Job "trien_khai" (máy ảo KHÁC hoàn toàn)
```

**Ba điều kiện bắt buộc — thiếu một là không chạy:**

| # | Điều kiện | Viết ở đâu |
|---|---|---|
| 1 | Step phải có `id` | `- id: chon` |
| 2 | Job phải khai báo `outputs` trỏ tới step đó | `outputs: ten_moi_truong: ${{ steps.chon.outputs.ten_moi_truong }}` |
| 3 | Job đọc phải có `needs` job ghi | `needs: [xac_dinh_moi_truong]` |

> ⚠️ **Lỗi hay gặp nhất:** quên điều kiện số 3. Không khai báo `needs` thì `needs.<job>.outputs` luôn rỗng — và GitHub **không báo lỗi**, chỉ đưa chuỗi rỗng. Kết quả là job chạy với giá trị trống, sai mà không biết vì sao.

**Vì sao chỉ truyền được chuỗi, không truyền được file?** Vì bảng này nằm trên máy chủ GitHub, không phải trên đĩa Runner. Nó sinh ra để mang **quyết định** (tên môi trường, số phiên bản, có nên chạy tiếp không), không phải để mang dữ liệu lớn. Dữ liệu lớn dùng artifact.

### 🔍 GIẢI THÍCH TƯỜNG TẬN — `environment` không chỉ là cái nhãn

Nhiều người tưởng `environment: name: uat` chỉ để hiển thị cho đẹp. Thực ra nó bật **bốn cơ chế** cùng lúc:

**① Chặn job lại chờ duyệt.** Nếu môi trường bật *Required reviewers*, job chuyển sang trạng thái `Waiting` và **không tiêu tốn Runner** trong lúc chờ. Người duyệt nhận thông báo.

**② Cấp đúng bộ biến và secret.** Cùng viết `${{ vars.API_URL }}`, nhưng job gắn `environment: staging` nhận giá trị khác job gắn `environment: release`. Code không cần biết mình đang ở đâu.

**③ Giới hạn nhánh được phép triển khai.** Cấu hình *Deployment branches* để chỉ nhánh `release` mới được deploy lên môi trường `release`. Ai đó tạo nhánh `release-test` rồi push cũng không lên được.

**④ Ghi lịch sử triển khai.** GitHub tự lưu: commit nào, ai đẩy, lúc nào, ai duyệt. Xem ở mục **Environments** ngoài trang chính repo. Rất hữu ích khi cần truy vết sự cố.

> **Cách chỉ cho sinh viên thấy rõ nhất:** push lên `staging` (chạy thẳng) rồi push lên `uat` (dừng chờ duyệt) — **cùng một file YAML**. Sự khác biệt hoàn toàn nằm ở cấu hình trên giao diện web, không có một dòng code nào phân biệt.

### 🔍 GIẢI THÍCH TƯỜNG TẬN — Vì sao không viết 3 file YAML riêng?

Sinh viên hay nghĩ cách đơn giản là copy file thành `deploy-staging.yml`, `deploy-uat.yml`, `deploy-release.yml`. Hãy để họ thấy vì sao cách đó tệ:

| Tình huống | 3 file riêng | 1 file dùng chung |
|---|---|---|
| Sửa bước build | Sửa **3 chỗ** | Sửa **1 chỗ** |
| Quên sửa 1 file | `release` build khác `staging` → **lỗi chỉ hiện ở production** | Không thể xảy ra |
| Thêm môi trường thứ 4 | Copy file thứ 4 | Thêm 4 dòng vào `case` |
| Đọc để hiểu hệ thống | Phải đọc 3 file, tự so sánh | Đọc 1 file |

> **Nguyên tắc chung của CI/CD:** *môi trường khác nhau chỉ ở **dữ liệu cấu hình**, không khác ở **quy trình**.* Quy trình build phải giống hệt nhau — nếu không, thứ bạn test ở `staging` không phải thứ chạy ở production.

---

## PHẦN 6 — CHẨN ĐOÁN SỰ CỐ VÀ QUẢN TRỊ LOG (20 phút)

### 6.1. Quy trình 4 bước chẩn đoán

| Bước | Việc làm |
|---|---|
| **01** | **Xác định Job lỗi** — tìm job có dấu **X đỏ** trong tab Actions |
| **02** | **Truy cập Console Log** — bấm vào job lỗi, mở rộng step bị sập |
| **03** | **Phân tích dòng log** — cuộn xuống cuối xem **Exit code**, rồi lần ngược lên đọc Error Trace |
| **04** | **Sửa lỗi & kiểm chứng** — sửa code, **chạy thử ở máy thật kỹ** trước khi push commit mới |

> **Bước 4 là bước sinh viên hay bỏ qua nhất.** Sửa đại rồi push lên xem CI có xanh không — mỗi vòng mất 2–3 phút chờ. Chạy `./gradlew test` ở máy mất 10 giây. **CI không phải chỗ để thử nghiệm.**

### 6.2. Kịch bản lỗi 1: Permission denied (Exit code 126)

**Dấu hiệu trong log:**
```
Run ./gradlew bootJar
/home/runner/work/_temp/...: line 2: ./gradlew: Permission denied
Error: Process completed with exit code 126.
```

**Bản chất:**
- Tệp `./gradlew` bị mất thuộc tính quyền thực thi (execute bit).
- Nguyên nhân: file được tạo trên Windows — hệ điều hành này không quản lý quyền file như Linux.
- Khi push lên Runner chạy Linux, hệ thống từ chối chạy file.

**Khắc phục:**
```yaml
- name: Cấp quyền thực thi cho Gradle Wrapper
  run: chmod +x ./gradlew

- name: Biên dịch và đóng gói tệp JAR
  run: ./gradlew bootJar
```

> 💡 **Cách sửa triệt để hơn** — ghi quyền vào Git một lần cho mãi mãi:
> ```bash
> git update-index --chmod=+x gradlew && git commit -m "fix: cap quyen thuc thi gradlew"
> ```
> Nhưng vẫn **nên giữ** bước `chmod +x` trong YAML như một lưới an toàn.

### 6.3. Kịch bản lỗi 2: Compilation Failed (Exit code 1)

**Dấu hiệu trong log:**
```
Run ./gradlew bootJar
> Task :compileJava FAILED
/home/runner/.../UserService.java:24: error: cannot find symbol
private UserReposotory userRepository;
^
Error: Process completed with exit code 1.
```

**Bản chất:** trình biên dịch Java từ chối tạo bytecode do lỗi cú pháp hoặc import sai thư viện, tại **dòng cụ thể** (dòng 24). CI ngắt tiến trình ngay để ngăn đóng gói sản phẩm lỗi.

**Khắc phục:** định vị file theo đường dẫn trong log, sửa lại đúng cú pháp.
```java
@Service
public class UserService {
    // Sửa lỗi chính tả từ UserReposotory thành UserRepository
    @Autowired
    private UserRepository userRepository;
}
```

### 6.4. Kịch bản lỗi 3: Test Failed (Exit code 1)

**Dấu hiệu trong log:**
```
Run ./gradlew build
UserServiceApplicationTests > testCreateUser() FAILED
    org.opentest4j.AssertionFailedError
        at UserServiceApplicationTests.java:17
2 tests completed, 1 failed
> Task :test FAILED
Error: Process completed with exit code 1.
```

**Bản chất:** biên dịch đã **thành công**, nhưng giá trị khẳng định (Assertion) trong test sai lệch so với thực tế. Gradle kích hoạt "Fail-fast" để huỷ đóng gói ngay, ngăn tạo ra JAR lỗi.

**Khắc phục:** rà soát lại logic nghiệp vụ hoặc sửa assertion cho đúng thiết kế.

> ⚠️ **Điều tuyệt đối không được dạy sinh viên làm:** thấy test đỏ thì xoá test đi, hoặc sửa assertion cho khớp với kết quả sai. Phải hỏi trước: **"Code sai hay test sai?"** Nếu code sai mà sửa test thì bạn vừa che giấu một lỗi thật sự — và nó sẽ nổ ở production.

### 6.5. Bảng phân biệt Exit code

| Exit code | Ý nghĩa | Hay gặp khi |
|---|---|---|
| `0` | Thành công | — |
| `1` | Lỗi chung của ứng dụng | Compile fail, test fail |
| `126` | Tìm thấy lệnh nhưng **không chạy được** | Thiếu quyền thực thi (`chmod +x`) |
| `127` | **Không tìm thấy lệnh** | Gõ sai tên lệnh, chưa cài công cụ |
| `128+n` | Bị tín hiệu n giết | `137` = 128+9 = bị `SIGKILL`, thường do **hết RAM** |

> **Phân biệt `126` và `127` rất đáng dạy:** `126` là "có file nhưng không chạy được" (lỗi quyền). `127` là "không có file đó" (sai tên hoặc chưa cài). Hai con số gần nhau nhưng nguyên nhân khác hẳn.

### 🔍 GIẢI THÍCH TƯỜNG TẬN — Exit code là gì và ai sinh ra nó?

Sinh viên biết "exit code 1 là lỗi" nhưng không biết **ai** quyết định con số đó. Giải thích bằng chuỗi bàn giao:

```
./gradlew test  →  thất bại, trả về  1
        │
        ▼
  bash chạy step ghi nhận mã 1, kết thúc step với mã 1
        │
        ▼
  Runner thấy step khác 0  →  đánh dấu step ĐỎ, dừng các step sau
        │
        ▼
  Runner báo về GitHub  →  job ĐỎ  →  các job có needs bị Skipped
```

**Quy ước chung của mọi chương trình Unix:** trả về `0` là thành công, **khác 0** là thất bại. Toàn bộ CI/CD thế giới dựa trên một quy ước đơn giản như vậy.

**Cách chỉ cho sinh viên thấy ngay:**

```bash
ls /thu-muc-khong-ton-tai; echo "Exit code = $?"
```
```bash
ls /tmp; echo "Exit code = $?"
```

`$?` là mã thoát của lệnh vừa chạy. Sinh viên tự thấy `0` và khác `0`.

> 💡 **Hệ quả quan trọng:** nếu bạn viết một step mà lệnh cuối luôn trả về 0, CI **sẽ luôn xanh** dù bên trong hỏng. Ví dụ `run: ./gradlew test || true` — dấu `|| true` nuốt mất lỗi. Đây là cách **giả mạo CI xanh** mà một số người dùng để "cho nhanh". Phải nói rõ với sinh viên đó là hành vi sai.

### 🔍 GIẢI THÍCH TƯỜNG TẬN — Cách đọc một log dài 500 dòng

Sinh viên mở log ra, thấy tường chữ, rồi bỏ cuộc. Dạy họ **thứ tự đọc**, không đọc từ đầu:

| Bước | Đọc chỗ nào | Tìm gì |
|---|---|---|
| **1** | **Dòng cuối cùng** | `Error: Process completed with exit code N` — biết loại lỗi |
| **2** | Lần ngược lên, tìm dòng đầu tiên có `error:` hoặc `FAILED` | Đây là **nguyên nhân gốc** |
| **3** | Đọc đường dẫn file và số dòng ngay cạnh đó | Biết sửa ở đâu |
| **4** | Bỏ qua mọi dòng còn lại | Chúng thường là hệ quả dây chuyền |

**Ví dụ áp dụng vào log thật:**

```
> Task :compileJava FAILED                                    ← (2) nguyên nhân bắt đầu ở đây
/home/runner/.../UserService.java:24: error: cannot find symbol
private UserReposotory userRepository;                        ← (3) file và dòng 24
                       ^
1 error
FAILURE: Build failed with an exception.                      ← hệ quả, bỏ qua
* What went wrong:                                            ← hệ quả, bỏ qua
Execution failed for task ':compileJava'.                     ← hệ quả, bỏ qua
Error: Process completed with exit code 1.                    ← (1) đọc dòng này TRƯỚC
```

> **Quy tắc vàng:** Java in lỗi theo kiểu "cái sai thật nằm ở trên, những dòng bên dưới chỉ là dây chuyền hệ quả". Đọc ngược từ dưới lên để biết **loại lỗi**, rồi tìm **dòng `error:` đầu tiên** để biết **chỗ sai**.

### 🔍 GIẢI THÍCH TƯỜNG TẬN — Vì sao lỗi quyền chỉ xảy ra trên CI mà không xảy ra ở máy?

Đây là câu hỏi sinh viên Windows nào cũng hỏi.

**Nguyên nhân nằm ở chỗ Git lưu quyền file như một con số.**

```bash
git ls-files -s quickbite-backend/user-service/gradlew
```

| Kết quả | Nghĩa là |
|---|---|
| `100755` | Có quyền thực thi ✅ |
| `100644` | Không có quyền thực thi ❌ |

- Trên **Windows**, hệ điều hành không có khái niệm execute bit → Git ghi `100644`
- Trên **máy Windows** vẫn chạy được `gradlew.bat`, nên không ai phát hiện
- Đẩy lên **Runner chạy Linux**, Linux đọc đúng `100644` → **từ chối chạy** → exit 126

**Hai cách sửa, nên dạy cả hai:**

| Cách | Lệnh | Ưu điểm |
|---|---|---|
| Sửa trong YAML | `run: chmod +x ./gradlew` | Lưới an toàn, luôn đúng |
| Sửa vĩnh viễn trong Git | `git update-index --chmod=+x gradlew` | Sửa tận gốc, một lần cho mãi mãi |

> **Nên làm cả hai.** Sửa trong Git để đúng bản chất, giữ `chmod +x` trong YAML phòng khi có người vô tình làm mất quyền lần nữa.

---

## PHẦN 7 — TỔNG KẾT (10 phút)

### 7.1. Quay lại ba câu hỏi đầu buổi

| Câu hỏi | Đáp án |
|---|---|
| ① Ai đảm bảo code không làm hỏng nhánh chung? | **CI** — tự động chạy test mỗi lần push; kết hợp Branch Protection để chặn merge khi CI đỏ |
| ② Lấy môi trường nào làm chuẩn? | **Runner** — `actions/setup-java` khai báo rõ JDK 17/21, mọi lần build đều giống nhau |
| ③ Đưa code lên server thế nào? | **CD** — artifact được đóng gói tự động, triển khai theo nhánh, có duyệt tay ở `uat`/`release` |

### 7.2. Bản đồ 8 kiến thức cốt lõi — dùng để kiểm tra sinh viên đã hiểu chưa

Mỗi dòng là một khái niệm gốc. Cột **"Hiểu rồi thì trả lời được"** là câu hỏi dùng để kiểm tra — nếu sinh viên trả lời trôi chảy nghĩa là đã nắm bản chất, không phải học vẹt.

| # | Kiến thức cốt lõi | Hiểu rồi thì trả lời được | Nếu chưa hiểu, quay lại |
|---|---|---|---|
| **1** | **Chữ "Continuous" là tích hợp *thường xuyên*, không phải *tự động*** | "Vì sao merge mỗi ngày dễ hơn merge mỗi tuần?" | Phần 0 + Phần 1.1 |
| **2** | **Runner chủ động polling, không phải GitHub đẩy xuống** | "Vì sao runner sau tường lửa công ty vẫn chạy được?" | Phần 1.2 |
| **3** | **Mỗi job = một máy ảo mới tinh, bị huỷ sau khi xong** | "Vì sao mỗi job phải `checkout` lại?" | Phần 1.2 + Phần 3.2 |
| **4** | **`uses` là gọi thư viện, `run` là tự viết lệnh** | "Vì sao `checkout` phải là Action chứ không phải `git clone`?" | Phần 2.4 |
| **5** | **`needs` vừa xếp thứ tự vừa là chốt chặn** | "Job trước đỏ thì job sau ra sao? Còn job không phụ thuộc?" | Phần 3.1 |
| **6** | **Artifact giữ sản phẩm, Cache chỉ để chạy nhanh** | "File JAR nên là artifact hay cache? Vì sao?" | Phần 3.2 |
| **7** | **`environment` bật 4 cơ chế, không chỉ là cái nhãn** | "Cùng một file YAML, vì sao `staging` chạy thẳng mà `uat` phải chờ?" | Phần 5.2 |
| **8** | **Exit code 0 là thành công, khác 0 là hỏng** | "`126` và `127` khác nhau chỗ nào?" | Phần 6.5 |

> **Cách dùng bảng này trên lớp:** 10 phút cuối buổi, chiếu cột giữa lên, gọi ngẫu nhiên sinh viên trả lời. Ai trả lời được 6/8 là đạt. Chỗ nào cả lớp lúng túng thì quay lại phần tương ứng ở cột phải.

### 7.2b. Ba hiểu nhầm phải phá bỏ trước khi kết thúc buổi

**① "CI xanh nghĩa là code đúng."**
→ Sai. CI chỉ chạy đúng những test **bạn viết**. Không viết test thì CI xanh chẳng chứng minh điều gì.
→ Mệnh đề đúng là một chiều: *CI đỏ **chắc chắn** có vấn đề. CI xanh **chưa chắc** đã ổn.*

**② "Các job nối tiếp nhau trên cùng một máy."**
→ Sai. Mỗi job là một máy ảo riêng biệt, hoàn toàn mới. Ngay cả khi có `needs`.
→ Đây là gốc rễ của hầu hết thắc mắc: vì sao phải checkout lại, vì sao cần artifact, vì sao cần cache.

**③ "Muốn deploy 3 môi trường thì viết 3 file YAML."**
→ Sai. Viết **một** file, dùng tên nhánh để phân biệt.
→ Ba file riêng nghĩa là sửa một chỗ phải sửa ba lần — và hôm nào quên một chỗ thì quy trình build ở production **khác** với chỗ bạn đã test.

### 7.3. Checklist kiến thức

- ❏ Đóng gói JAR tự động trên CI
- ❏ Kiến trúc giao tiếp giữa Server và Runner
- ❏ Cấu trúc kịch bản YAML, đặt trong `.github/workflows`
- ❏ Sử dụng `needs` để ràng buộc tuần tự job
- ❏ Cơ chế Job Isolation và Artifacts
- ❏ Triển khai theo 3 môi trường staging / uat / release
- ❏ Phân tích lỗi và xử lý các tình huống lỗi phổ biến

### 7.4. Bảng khái niệm hay nhầm

| Cặp | Khác nhau ở chỗ |
|---|---|
| CI ↔ CD | Đảm bảo code tích hợp được ↔ đưa code tới người dùng |
| Continuous **Delivery** ↔ **Deployment** | Có bước duyệt tay ↔ tự động 100% |
| `uses` ↔ `run` | Gọi Action đóng gói sẵn ↔ chạy lệnh shell |
| Job ↔ Step | Máy ảo riêng, chạy song song ↔ cùng máy, chạy tuần tự |
| GitHub-hosted ↔ Self-hosted | GitHub lo, máy sạch, tốn phút ↔ tự lo, có cache, miễn phí |
| `env` ↔ `outputs` | Biến cố định khai báo sẵn ↔ giá trị job trước truyền sang job sau |
| Artifact ↔ Cache | Sản phẩm muốn giữ lại để dùng ↔ dữ liệu tạm để tăng tốc build |
| Exit `126` ↔ `127` | Có file nhưng thiếu quyền ↔ không tìm thấy lệnh |

### 7.5. Mười lỗi thường gặp

| # | Triệu chứng | Nguyên nhân | Xử lý |
|---|---|---|---|
| 1 | Tab Actions trống trơn | Sai đường dẫn `.github/workflows/` hoặc YAML lỗi | Kiểm tra đúng tên thư mục (có chữ **s**) và thụt lề |
| 2 | `Permission denied` exit 126 | Mất execute bit của `gradlew` | Thêm `chmod +x ./gradlew` |
| 3 | `cannot find symbol` exit 1 | Lỗi cú pháp Java | Sửa theo dòng ghi trong log |
| 4 | `AssertionFailedError` exit 1 | Test thất bại | Hỏi "code sai hay test sai?" rồi mới sửa |
| 5 | Job sau báo không thấy file của job trước | Job Isolation | Dùng upload/download artifact |
| 6 | Job sau không có mã nguồn | Thiếu `actions/checkout` | Mỗi job phải checkout riêng |
| 7 | `no tests found` | Thiếu `useJUnitPlatform()` | Thêm vào `build.gradle` |
| 8 | Build rất chậm mỗi lần | Không bật cache | Thêm `cache: gradle` vào `setup-java` |
| 9 | Workflow không chạy khi push nhánh | `on.push.branches` không khớp | Kiểm tra danh sách nhánh trong `on` |
| 10 | Hết phút miễn phí | Workflow chạy quá thường xuyên | Thêm bộ lọc `paths`, hoặc chuyển self-hosted |

### 7.6. Bài tập về nhà

**Bài 1 (bắt buộc).** Viết workflow CI cho `restaurant-service` dùng **JDK 21**. Giải thích phải đổi những gì so với `user-service`.

**Bài 2 (bắt buộc).** Thêm một job `kiem_tra_dinh_dang` chạy **song song** với job test, và một job `tong_ket` dùng `needs` đợi cả hai. Vẽ sơ đồ luồng trước khi viết YAML.

**Bài 3 (bắt buộc).** Cấu hình GitHub Environments cho `uat` và `release` với **Required reviewers**. Chụp màn hình lúc job dừng chờ duyệt, giải thích đây là Delivery hay Deployment.

**Bài 4 (nâng cao).** Dùng `matrix` để chạy test trên **cả JDK 17 và 21** cùng lúc. Giải thích vì sao việc này hữu ích khi nâng cấp phiên bản Java.

**Bài 5 (nâng cao).** Thêm bước build **Docker image** và đẩy lên GitHub Container Registry (`ghcr.io`). Giải thích vì sao lưu Docker image tốt hơn lưu file JAR khi triển khai.

### 7.7. Câu hỏi vấn đáp nhanh

1. Workflow phải đặt ở thư mục nào? *(`.github/workflows/` tại gốc repository)*
2. Các job mặc định chạy thế nào? *(Song song, mỗi job một máy ảo riêng)*
3. Làm sao ép job chạy tuần tự? *(Dùng `needs`)*
4. Job B có thấy file Job A tạo ra không? *(Không — phải dùng artifact)*
5. Vì sao mỗi job phải `checkout` lại? *(Job Isolation — máy ảo mới, workspace rỗng)*
6. Exit code 126 nghĩa là gì? *(Có file nhưng thiếu quyền thực thi)*
7. Delivery khác Deployment ở điểm nào? *(Có bước duyệt tay hay không)*
8. Vì sao không dùng self-hosted runner cho repo public? *(Ai gửi PR cũng chạy được code tuỳ ý trên máy bạn)*

---

**Hết giáo trình — chuyển sang `S7-02-LAB` để thực hành.**
