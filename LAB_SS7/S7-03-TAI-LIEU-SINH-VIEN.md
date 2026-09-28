# TÀI LIỆU HỌC — SESSION 07

<div class="hero">
<div class="tri"></div>
<h1>Tự động hoá CI/CD với GitHub Actions</h1>
<p class="sub">Để máy chủ chạy test và đóng gói thay bạn — và để code hỏng không bao giờ lọt vào nhánh chung.</p>
<p style="margin:14px 0 0"><span class="pill">Session 07</span><span class="pill s">Thời lượng 3 tiếng</span><span class="pill g">Có repo demo chạy thật</span></p>
</div>

## Ba câu hỏi buổi học này trả lời

<div class="grid3">
<div class="card">
<h4>① Ai chặn code hỏng?</h4>
<p>Bạn sửa vội một dòng rồi push thẳng lên <code>develop</code>. Không chạy test. Cả nhóm 8 người <code>pull</code> về và ai cũng bị lỗi.</p>
</div>
<div class="card">
<h4>② "Máy tôi chạy được" — máy ai?</h4>
<p>Bạn dùng JDK 21, đồng nghiệp dùng JDK 17. Code biên dịch được ở máy bạn, sập ở máy họ. Lấy môi trường nào làm chuẩn?</p>
</div>
<div class="card">
<h4>③ Đưa code lên server thế nào?</h4>
<p>Copy file JAR bằng tay qua SCP? Ai làm? Lúc nào? Lỡ copy nhầm bản cũ thì sao?</p>
</div>
</div>

<div class="keybox">
<span class="lbl">Nói thẳng ngay từ đầu</span>
<p>CI/CD <strong>không</strong> làm code của bạn tốt hơn. Nó chỉ <strong>phát hiện sớm</strong> khi code hỏng và <strong>chặn</strong> code hỏng lọt vào nhánh chung. Chất lượng vẫn do người viết quyết định — CI là cái lưới an toàn, không phải phép màu.</p>
</div>

---

# CI và CD là gì?

<div class="grid2">
<div class="card">
<h4>CI · Continuous Integration</h4>
<p><strong>Tích hợp liên tục.</strong> Mỗi lần có người push code, máy chủ tự động:</p>
<p>① kéo mã nguồn mới nhất<br>
② biên dịch, quét lỗi cú pháp<br>
③ chạy toàn bộ Unit Test</p>
<p><strong>Mục tiêu:</strong> nhánh chung <em>luôn</em> ở trạng thái biên dịch được và an toàn.</p>
</div>
<div class="card ok">
<h4>CD · Continuous Delivery / Deployment</h4>
<p><strong>Chuyển giao / triển khai liên tục.</strong> Sau khi CI xanh:</p>
<p>① đóng gói thành phẩm (JAR, Docker image)<br>
② đẩy lên kho lưu trữ<br>
③ triển khai lên máy chủ</p>
<p><strong>Hai chữ CD khác nhau ở một điểm duy nhất</strong> — xem bảng dưới.</p>
</div>
</div>

| | Continuous **Delivery** | Continuous **Deployment** |
|---|---|---|
| Đóng gói thành phẩm | Tự động | Tự động |
| Đẩy lên Registry | Tự động | Tự động |
| Triển khai lên Production | **Có người bấm nút duyệt** | **Tự động 100%** |
| Khẩu hiệu | "Luôn *sẵn sàng* phát hành" | "Tự động *phát hành* luôn" |

<div class="keybox">
<span class="lbl">Đừng nhầm hai chữ CD</span>
<p>Cả hai đều viết tắt là CD nhưng khác nhau ở <strong>đúng một bước</strong>: có cần người bấm nút duyệt không. Đa số doanh nghiệp Việt Nam dừng ở <strong>Delivery</strong> — và đó là lựa chọn hợp lý, không phải thiếu sót.</p>
</div>

---

# Kiến trúc: Server, Runner và Host OS

<figure class="dg">
<svg viewBox="0 0 700 360" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Kiến trúc GitHub Server Runner Host OS">
  <rect x="196" y="14" width="308" height="66" rx="11" fill="#fff" stroke="#1B1F24" stroke-width="2"/>
  <text x="350" y="42" text-anchor="middle" font-family="Inter,sans-serif" font-size="15" font-weight="780" fill="#1B1F24">GitHub Server</text>
  <text x="350" y="64" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" fill="#5B6572">Web UI · Git Repository · API</text>

  <line x1="350" y1="80" x2="350" y2="112" stroke="#44546A" stroke-width="2"/>
  <path d="M344 108 L350 120 L356 108 Z" fill="#44546A"/>
  <path d="M356 112 L350 100 L344 112 Z" fill="#44546A"/>
  <rect x="242" y="86" width="216" height="24" rx="12" fill="#F1F3F6" stroke="#DCE1E8"/>
  <text x="350" y="103" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" fill="#44546A">Runner POLLING hỏi: có việc không?</text>

  <rect x="140" y="128" width="300" height="76" rx="11" fill="#E8F1FB" stroke="#15559A" stroke-width="2"/>
  <text x="290" y="156" text-anchor="middle" font-family="Inter,sans-serif" font-size="15" font-weight="780" fill="#0E3F73">GitHub Actions Runner</text>
  <text x="290" y="177" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" fill="#2A5F96">máy chủ thực thi</text>
  <text x="290" y="194" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" fill="#4A7AAA">Polling → Lấy Jobs → Thực thi</text>

  <line x1="440" y1="166" x2="488" y2="166" stroke="#2E7D32" stroke-width="2.2"/>
  <path d="M484 161 L494 166 L484 171 Z" fill="#2E7D32"/>
  <text x="464" y="156" text-anchor="middle" font-family="Inter,sans-serif" font-size="10" fill="#2E7D32">chạy Jobs</text>

  <rect x="496" y="128" width="196" height="76" rx="11" fill="#E8F5E9" stroke="#2E7D32" stroke-width="2"/>
  <text x="594" y="156" text-anchor="middle" font-family="Inter,sans-serif" font-size="14" font-weight="780" fill="#1B3A1E">Môi trường Host OS</text>
  <text x="594" y="177" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" fill="#3B5C3E">Docker / Container</text>
  <text x="594" y="194" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" fill="#3B5C3E">hoặc Host OS</text>

  <rect x="14" y="238" width="672" height="106" rx="12" fill="#F9FAFC" stroke="#E3E7EC"/>
  <text x="34" y="264" font-family="Inter,sans-serif" font-size="12.5" font-weight="750" fill="#5B6572">Luồng hoạt động tổng quát</text>
  <g font-family="Inter,sans-serif" font-size="11.5" fill="#1B1F24">
    <rect x="34" y="280" width="104" height="34" rx="7" fill="#fff" stroke="#DCE1E8"/><text x="86" y="301" text-anchor="middle">Push code</text>
    <rect x="164" y="280" width="128" height="34" rx="7" fill="#fff" stroke="#DCE1E8"/><text x="228" y="301" text-anchor="middle">GitHub tạo Workflow</text>
    <rect x="318" y="280" width="118" height="34" rx="7" fill="#fff" stroke="#DCE1E8"/><text x="377" y="301" text-anchor="middle">Runner lấy Jobs</text>
    <rect x="462" y="280" width="102" height="34" rx="7" fill="#fff" stroke="#DCE1E8"/><text x="513" y="301" text-anchor="middle">Thực thi</text>
    <rect x="590" y="280" width="96" height="34" rx="7" fill="#E8F5E9" stroke="#A8CFAB"/><text x="638" y="301" text-anchor="middle" fill="#1B3A1E">Trả kết quả</text>
  </g>
  <g stroke="#8A929C" stroke-width="1.8">
    <line x1="138" y1="297" x2="158" y2="297"/><line x1="292" y1="297" x2="312" y2="297"/>
    <line x1="436" y1="297" x2="456" y2="297"/><line x1="564" y1="297" x2="584" y2="297"/>
  </g>
  <g fill="#8A929C">
    <path d="M154 292 L164 297 L154 302 Z"/><path d="M308 292 L318 297 L308 302 Z"/>
    <path d="M452 292 L462 297 L452 302 Z"/><path d="M580 292 L590 297 L580 302 Z"/>
  </g>
  <text x="350" y="334" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" font-style="italic" fill="#8A929C">Bạn chỉ làm bước đầu tiên. Bốn bước còn lại máy chủ lo.</text>
</svg>
</figure>

<div class="keybox">
<span class="lbl">Chi tiết ít người để ý</span>
<p>Runner <strong>chủ động polling</strong> hỏi GitHub "có việc gì cho tôi không?", chứ GitHub <strong>không</strong> chủ động đẩy việc xuống. Đây là lý do một self-hosted runner đặt sau tường lửa công ty vẫn hoạt động được — nó chỉ cần gọi <strong>ra ngoài</strong>, không cần mở cổng vào.</p>
</div>

## Hai loại Runner

<div class="grid2">
<div class="card">
<h4>GitHub-hosted</h4>
<p>GitHub quản lý hoàn toàn. Máy ảo <strong>mới tinh</strong> cho mỗi job.</p>
<p><span class="pill g">Sạch</span><span class="pill g">Không phải quản lý</span><span class="pill">2 vCPU · 7GB</span></p>
<p>Giới hạn thời gian chạy miễn phí. Hợp với dự án vừa và nhỏ.</p>
</div>
<div class="card ok">
<h4>Self-hosted</h4>
<p>Bạn tự cài trên VPS, VM hoặc máy chủ riêng.</p>
<p><span class="pill g">Miễn phí giờ chạy</span><span class="pill g">Có cache</span><span class="pill s">Tự quản lý</span></p>
<p>Build nhanh hơn nhiều nhờ giữ cache. Hợp với dự án build liên tục.</p>
</div>
</div>

<div class="keybox">
<span class="lbl">Đánh đổi thật sự</span>
<p>Máy ảo sạch mỗi lần chạy vừa là <strong>ưu điểm</strong> (không bị nhiễm bẩn từ lần trước) vừa là <strong>nhược điểm</strong> (phải tải lại thư viện mỗi lần → chậm). Self-hosted giữ được cache nên nhanh hơn, nhưng một runner bị "bẩn" có thể khiến build <strong>pass giả</strong> trong khi lẽ ra phải fail.</p>
</div>

> ⚠️ **Cảnh báo bảo mật:** tuyệt đối **không** dùng self-hosted runner cho repository **public**. Bất kỳ ai gửi Pull Request đều có thể chạy code tuỳ ý trên máy của bạn.

---

# Cấu trúc một Workflow

## Nơi đặt file

```
project-demo/
└── .github/            ← có dấu chấm ở đầu
    └── workflows/      ← có chữ "s" ở cuối
        └── ci.yml
```

> ⚠️ **Ba lỗi khiến workflow KHÔNG BAO GIỜ chạy — và GitHub không báo gì cả:**
> 1. Viết `.github/workflow/` — **thiếu chữ s**
> 2. Đặt ở thư mục con thay vì gốc repository
> 3. Sai thụt lề YAML
>
> Không có thông báo lỗi. Tab Actions chỉ đơn giản là **trống**. Đây là trải nghiệm bực bội nhất của người mới.

## Bốn cấp phân chia

<figure class="dg">
<svg viewBox="0 0 700 300" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Phân cấp Workflow Jobs Steps Actions">
  <rect x="14" y="14" width="672" height="272" rx="12" fill="#FDECEC" stroke="#BD2728" stroke-width="2"/>
  <text x="34" y="40" font-family="Inter,sans-serif" font-size="14" font-weight="780" fill="#8C1D1A">WORKFLOW — toàn bộ pipeline, 1 file YAML</text>

  <rect x="34" y="54" width="196" height="216" rx="10" fill="#fff" stroke="#44546A" stroke-width="1.8"/>
  <text x="132" y="78" text-anchor="middle" font-family="Inter,sans-serif" font-size="12.5" font-weight="750" fill="#44546A">JOB A</text>
  <text x="132" y="95" text-anchor="middle" font-family="Inter,sans-serif" font-size="10.5" fill="#8A929C">máy ảo riêng</text>
  <rect x="48" y="106" width="168" height="30" rx="6" fill="#E8F1FB" stroke="#CADEF5"/>
  <text x="132" y="126" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" fill="#15559A">Step 1 · uses: checkout</text>
  <rect x="48" y="142" width="168" height="30" rx="6" fill="#E8F1FB" stroke="#CADEF5"/>
  <text x="132" y="162" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" fill="#15559A">Step 2 · uses: setup-java</text>
  <rect x="48" y="178" width="168" height="30" rx="6" fill="#E8F5E9" stroke="#A8CFAB"/>
  <text x="132" y="198" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" fill="#1B3A1E">Step 3 · run: ./gradlew test</text>
  <text x="132" y="228" text-anchor="middle" font-family="Inter,sans-serif" font-size="10.5" font-style="italic" fill="#8A929C">Steps chạy TUẦN TỰ</text>
  <text x="132" y="246" text-anchor="middle" font-family="Inter,sans-serif" font-size="10.5" font-style="italic" fill="#8A929C">cùng máy, chung workspace</text>

  <rect x="252" y="54" width="196" height="216" rx="10" fill="#fff" stroke="#44546A" stroke-width="1.8"/>
  <text x="350" y="78" text-anchor="middle" font-family="Inter,sans-serif" font-size="12.5" font-weight="750" fill="#44546A">JOB B</text>
  <text x="350" y="95" text-anchor="middle" font-family="Inter,sans-serif" font-size="10.5" fill="#8A929C">máy ảo riêng KHÁC</text>
  <rect x="266" y="106" width="168" height="30" rx="6" fill="#E8F1FB" stroke="#CADEF5"/>
  <text x="350" y="126" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" fill="#15559A">Step 1 · uses: checkout</text>
  <text x="350" y="158" text-anchor="middle" font-family="Inter,sans-serif" font-size="10.5" fill="#C9553B">phải checkout LẠI</text>
  <text x="350" y="175" text-anchor="middle" font-family="Inter,sans-serif" font-size="10.5" fill="#C9553B">vì không thấy gì của Job A</text>
  <rect x="266" y="190" width="168" height="30" rx="6" fill="#E8F5E9" stroke="#A8CFAB"/>
  <text x="350" y="210" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" fill="#1B3A1E">Step 2 · run: ./gradlew bootJar</text>

  <rect x="470" y="54" width="196" height="216" rx="10" fill="#fff" stroke="#C3CAD3" stroke-width="1.8" stroke-dasharray="5 4"/>
  <text x="568" y="78" text-anchor="middle" font-family="Inter,sans-serif" font-size="12.5" font-weight="750" fill="#8A929C">JOB C</text>
  <text x="568" y="100" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" fill="#8A929C">needs: [A, B]</text>
  <text x="568" y="128" text-anchor="middle" font-family="Inter,sans-serif" font-size="10.5" fill="#8A929C">Bị khoá ở trạng thái Pending</text>
  <text x="568" y="146" text-anchor="middle" font-family="Inter,sans-serif" font-size="10.5" fill="#8A929C">cho tới khi A và B cùng xong</text>
  <rect x="490" y="176" width="156" height="52" rx="8" fill="#FFF4E5" stroke="#E5C9A6"/>
  <text x="568" y="197" text-anchor="middle" font-family="Inter,sans-serif" font-size="10.5" fill="#8A5000">A hoặc B thất bại</text>
  <text x="568" y="214" text-anchor="middle" font-family="Inter,sans-serif" font-size="11" font-weight="700" fill="#B03000">→ C bị Skipped</text>

  <text x="240" y="44" font-family="Inter,sans-serif" font-size="10.5" font-style="italic" fill="#A0413F">Jobs mặc định chạy SONG SONG →</text>
</svg>
</figure>

| Cấp | Là gì |
|---|---|
| **Workflow** | Toàn bộ pipeline, định nghĩa trong một file YAML |
| **Jobs** | Mặc định chạy **song song, độc lập**, mỗi job một Runner |
| **Steps** | Chạy **tuần tự** trong một Job, cùng Runner, chung workspace |
| **Actions** | Khối lệnh viết sẵn, gọi qua `uses` |
| **Run** | Lệnh shell chạy trực tiếp, qua `run` |

## Workflow đầu tiên

```yaml
name: Print Environment Info      # tên hiển thị trên tab Actions

on:                                # khi nào chạy
  push:
    branches: [main]

env:                               # biến dùng chung cho mọi job
  PROJECT_NAME: "QuickBite-User-Service"

jobs:
  print_env_job:
    runs-on: ubuntu-latest         # chọn Runner
    steps:
      - name: Lấy mã nguồn về máy Runner
        uses: actions/checkout@v4  # uses = gọi Action viết sẵn

      - name: Thiết lập môi trường Java 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: In thông tin môi trường
        run: |                     # run = chạy lệnh shell
          echo "Dự án: ${PROJECT_NAME}"
          java -version
          echo "Nhánh Git: ${GITHUB_REF_NAME}"
```

**Hai loại biến môi trường:**

| Loại | Ví dụ | Ai tạo ra |
|---|---|---|
| Tự định nghĩa | `PROJECT_NAME` | Bạn khai báo trong `env` |
| Hệ thống tiêm sẵn | `GITHUB_REF_NAME`, `GITHUB_SHA`, `GITHUB_ACTOR` | GitHub tự tiêm vào Runner |

> 💡 Không cần khai báo `GITHUB_REF_NAME` trong `env` — Runner vẫn tự hiểu và lấy được tên nhánh hiện tại.

> 💡 **Mẹo rất hữu ích:** thêm `workflow_dispatch:` vào khối `on` để có nút **Run workflow** bấm chạy tay — không cần push code vẫn thử được.

---

# Job Isolation — hiểu nhầm phổ biến nhất

<div class="keybox">
<span class="lbl">Điều sinh viên hay nghĩ sai</span>
<p>Nhiều người nghĩ các job nối tiếp nhau trên cùng một máy, giống các dòng trong một script. <strong>Không phải.</strong> Mỗi job là <strong>một máy ảo hoàn toàn mới</strong>. Kể cả khi có <code>needs</code>, Job B vẫn không thấy gì của Job A — kể cả mã nguồn.</p>
</div>

Hệ quả:

<div class="grid2">
<div class="card no">
<h4>File không tự chia sẻ</h4>
<p>File Job A tạo ra ở thư mục làm việc <strong>không</strong> có ở Job B.</p>
</div>
<div class="card no">
<h4>Mã nguồn cũng không</h4>
<p>Job B phải tự chạy <code>actions/checkout</code> của riêng mình. Lệnh checkout ở Job A vô tác dụng với Job B.</p>
</div>
</div>

**Cách duy nhất để truyền dữ liệu — Artifacts:**

```
Job A ──upload-artifact──► Kho lưu trữ tạm GitHub ──download-artifact──► Job B
```

```yaml
# Job A đóng gói rồi đẩy lên
- uses: actions/upload-artifact@v4
  with:
    name: user-service-jar
    path: build/libs/*.jar

# Job B kéo về
- uses: actions/download-artifact@v4
  with:
    name: user-service-jar
```

---

# Ba môi trường: staging · uat · release

Không ai đưa code thẳng từ máy lập trình viên lên máy chủ khách hàng. Phải có các **trạm dừng**.

<figure class="dg">
<svg viewBox="0 0 700 250" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Luồng thăng cấp code qua ba môi trường">
  <g font-family="Inter,sans-serif">
    <rect x="16" y="56" width="126" height="72" rx="10" fill="#fff" stroke="#8A929C" stroke-width="1.8" stroke-dasharray="4 4"/>
    <text x="79" y="82" text-anchor="middle" font-size="12.5" font-weight="750" fill="#5B6572">feature/*</text>
    <text x="79" y="102" text-anchor="middle" font-size="10.5" fill="#8A929C">máy lập trình viên</text>

    <rect x="170" y="56" width="126" height="72" rx="10" fill="#E8F5E9" stroke="#2E7D32" stroke-width="2"/>
    <text x="233" y="80" text-anchor="middle" font-size="12.5" font-weight="750" fill="#1B3A1E">staging</text>
    <text x="233" y="98" text-anchor="middle" font-size="10.5" fill="#3B5C3E">đội phát triển</text>
    <text x="233" y="115" text-anchor="middle" font-size="10.5" font-weight="700" fill="#2E7D32">tự động</text>

    <rect x="324" y="56" width="126" height="72" rx="10" fill="#FFF4E5" stroke="#E07C00" stroke-width="2"/>
    <text x="387" y="80" text-anchor="middle" font-size="12.5" font-weight="750" fill="#8A5000">uat</text>
    <text x="387" y="98" text-anchor="middle" font-size="10.5" fill="#A06A20">khách hàng / QA</text>
    <text x="387" y="115" text-anchor="middle" font-size="10.5" font-weight="700" fill="#B03000">cần duyệt</text>

    <rect x="478" y="56" width="126" height="72" rx="10" fill="#FDECEC" stroke="#BD2728" stroke-width="2"/>
    <text x="541" y="80" text-anchor="middle" font-size="12.5" font-weight="750" fill="#8C1D1A">release</text>
    <text x="541" y="98" text-anchor="middle" font-size="10.5" fill="#A0413F">đội vận hành</text>
    <text x="541" y="115" text-anchor="middle" font-size="10.5" font-weight="700" fill="#8C1D1A">cần duyệt</text>

    <rect x="632" y="56" width="54" height="72" rx="10" fill="#1B1F24"/>
    <text x="659" y="88" text-anchor="middle" font-size="11.5" font-weight="750" fill="#fff">main</text>
    <text x="659" y="105" text-anchor="middle" font-size="9.5" fill="#C3CAD3">prod</text>
  </g>
  <g stroke="#44546A" stroke-width="2">
    <line x1="142" y1="92" x2="164" y2="92"/><line x1="296" y1="92" x2="318" y2="92"/>
    <line x1="450" y1="92" x2="472" y2="92"/><line x1="604" y1="92" x2="626" y2="92"/>
  </g>
  <g fill="#44546A">
    <path d="M160 87 L170 92 L160 97 Z"/><path d="M314 87 L324 92 L314 97 Z"/>
    <path d="M468 87 L478 92 L468 97 Z"/><path d="M622 87 L632 92 L622 97 Z"/>
  </g>
  <text x="350" y="42" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" fill="#8A929C">Code đi MỘT CHIỀU, không nhảy cóc</text>

  <rect x="16" y="164" width="670" height="70" rx="11" fill="#F9FAFC" stroke="#E3E7EC"/>
  <text x="351" y="190" text-anchor="middle" font-family="Inter,sans-serif" font-size="12.5" font-weight="750" fill="#5B6572">Chi phí sửa sai tăng dần theo từng chặng</text>
  <text x="351" y="212" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" fill="#2E7D32">Hỏng ở staging: mất 5 phút</text>
  <text x="351" y="228" text-anchor="middle" font-family="Inter,sans-serif" font-size="11.5" fill="#8C1D1A">Hỏng ở uat: mất uy tín với khách    ·    Hỏng ở release: mất tiền</text>
</svg>
</figure>

| Nhánh | Môi trường | Cổng | Nhãn phiên bản | Duyệt tay |
|---|---|---|---|---|
| `staging` | Staging | 8101 | `snapshot` | Không |
| `uat` | UAT | 8102 | `rc` | **Có** |
| `release` | Release | 8103 | `stable` | **Có** |

## Một file YAML cho cả ba

Nguyên tắc: **không** viết 3 file giống nhau. Viết **một** file, dùng tên nhánh để quyết định.

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
      - run: echo "Triển khai lên ${{ needs.xac_dinh_moi_truong.outputs.ten_moi_truong }}"
```

**Hai kỹ thuật mới:**

<div class="grid2">
<div class="card">
<h4><span class="stepnum">1</span>outputs</h4>
<p>Job Isolation nói <em>file</em> không chia sẻ được — nhưng <strong>giá trị chuỗi</strong> thì có.</p>
<p>Ghi: <code>echo "key=value" &gt;&gt; $GITHUB_OUTPUT</code><br>
Đọc: <code>needs.&lt;job&gt;.outputs.&lt;key&gt;</code></p>
</div>
<div class="card">
<h4><span class="stepnum">2</span>environment</h4>
<p>Vào <em>Settings → Environments</em> tạo <code>staging</code>, <code>uat</code>, <code>release</code>. Mỗi cái có:</p>
<p>• <strong>Required reviewers</strong> — job dừng chờ duyệt<br>
• <strong>Variables / Secrets riêng</strong> — cùng tên, khác giá trị<br>
• <strong>Deployment branches</strong> — giới hạn nhánh</p>
</div>
</div>

<div class="keybox">
<span class="lbl">Đây chính là chỗ hai chữ CD tách đôi</span>
<p>Bật <em>Required reviewers</em> cho <code>uat</code>/<code>release</code> → Continuous <strong>Delivery</strong>.<br>
Không bật gì → Continuous <strong>Deployment</strong>.</p>
<p><strong>Cùng một file YAML</strong>, khác nhau ở cấu hình trên giao diện web — không phải ở code.</p>
</div>

> **Nguyên tắc vàng:** code chỉ đi **một chiều**, không nhảy cóc. Muốn lên `release` phải qua `uat` trước. Có lỗi ở `uat` thì sửa ở nhánh nguồn rồi đẩy lại từ đầu — **không** sửa trực tiếp trên `uat`.

---

# Đọc log khi CI đỏ

## Quy trình 4 bước

<div class="grid2">
<div class="card">
<h4><span class="stepnum">1</span>Xác định Job lỗi</h4>
<p>Tìm job có dấu <strong>X đỏ</strong> trong tab Actions.</p>
</div>
<div class="card">
<h4><span class="stepnum">2</span>Truy cập Console Log</h4>
<p>Bấm vào job lỗi, <strong>mở rộng step bị sập</strong>.</p>
</div>
<div class="card">
<h4><span class="stepnum">3</span>Phân tích dòng log</h4>
<p>Cuộn xuống cuối xem <strong>Exit code</strong>, rồi lần ngược lên đọc Error Trace.</p>
</div>
<div class="card ok">
<h4><span class="stepnum">4</span>Sửa & kiểm chứng</h4>
<p>Sửa code, <strong>chạy thử ở máy thật kỹ</strong> trước khi push commit mới.</p>
</div>
</div>

> ⚠️ **Bước 4 là bước hay bị bỏ qua nhất.** Sửa đại rồi push xem CI có xanh không — mỗi vòng mất 2–3 phút chờ. Chạy `./gradlew test` ở máy mất 10 giây. **CI không phải chỗ để thử nghiệm.**

## Ba lỗi kinh điển

### Lỗi 1 · Permission denied — Exit code 126

```
Run ./gradlew bootJar
/home/runner/work/_temp/...: ./gradlew: Permission denied
Error: Process completed with exit code 126.
```

**Vì sao:** tệp `gradlew` mất thuộc tính quyền thực thi. Thường do file được tạo trên **Windows** — hệ điều hành này không quản lý quyền file như Linux.

**Sửa:**
```yaml
- name: Cấp quyền thực thi cho Gradle Wrapper
  run: chmod +x ./gradlew
```

### Lỗi 2 · Compilation Failed — Exit code 1

```
> Task :compileJava FAILED
.../UserService.java:24: error: cannot find symbol
private UserReposotory userRepository;
                       ^
Error: Process completed with exit code 1.
```

**Vì sao:** trình biên dịch từ chối tạo bytecode do lỗi cú pháp tại **dòng cụ thể** (dòng 24). CI ngắt ngay để ngăn đóng gói sản phẩm lỗi.

**Sửa:** định vị file theo đường dẫn trong log, sửa lại cú pháp — ở đây là lỗi chính tả `UserReposotory` → `UserRepository`.

### Lỗi 3 · Test Failed — Exit code 1

```
UserServiceApplicationTests > testCreateUser() FAILED
    org.opentest4j.AssertionFailedError
2 tests completed, 1 failed
> Task :test FAILED
Error: Process completed with exit code 1.
```

**Vì sao:** biên dịch đã **thành công**, nhưng giá trị khẳng định (Assertion) trong test sai lệch. Gradle "Fail-fast" huỷ đóng gói ngay, ngăn tạo JAR lỗi.

<div class="keybox">
<span class="lbl">Điều tuyệt đối không được làm</span>
<p>Thấy test đỏ thì <strong>xoá test đi</strong>, hoặc sửa assertion cho khớp với kết quả sai.</p>
<p>Phải hỏi trước: <strong>"Code sai hay test sai?"</strong> Nếu code sai mà sửa test thì bạn vừa che giấu một lỗi thật sự — và nó sẽ nổ ở production.</p>
</div>

## Bảng Exit code

| Exit code | Ý nghĩa | Hay gặp khi |
|---|---|---|
| `0` | Thành công | — |
| `1` | Lỗi chung của ứng dụng | Compile fail, test fail |
| `126` | Tìm thấy lệnh nhưng **không chạy được** | Thiếu `chmod +x` |
| `127` | **Không tìm thấy lệnh** | Gõ sai tên, chưa cài công cụ |
| `137` | Bị `SIGKILL` (128+9) | **Hết RAM** trên Runner |

> 💡 **Phân biệt `126` và `127`:** `126` = "có file nhưng không chạy được" (lỗi quyền). `127` = "không có file đó" (sai tên hoặc chưa cài).

---

# Tự kiểm tra

<details class="q"><summary><span>Workflow phải đặt ở thư mục nào?</span></summary>
<div class="ans">
<p><code>.github/workflows/</code> tại <strong>gốc</strong> repository. Có dấu chấm ở đầu <code>.github</code> và chữ <strong>s</strong> ở cuối <code>workflows</code>.</p>
<p>Sai một trong hai thì workflow không bao giờ chạy, và GitHub <strong>không báo lỗi gì cả</strong> — tab Actions chỉ đơn giản là trống.</p>
</div></details>

<details class="q"><summary><span>Các job mặc định chạy thế nào?</span></summary>
<div class="ans">
<p><strong>Song song</strong>, mỗi job trên một máy ảo riêng. Muốn ép tuần tự thì dùng <code>needs</code>.</p>
</div></details>

<details class="q"><summary><span>Job B có thấy file mà Job A tạo ra không?</span></summary>
<div class="ans">
<p><strong>Không.</strong> Mỗi job chạy trên một máy ảo hoàn toàn mới — đây là Job Isolation.</p>
<p>Muốn truyền file thì dùng <code>upload-artifact</code> ở Job A và <code>download-artifact</code> ở Job B. Đó là con đường <strong>duy nhất</strong>.</p>
</div></details>

<details class="q"><summary><span>Vì sao mỗi job phải chạy <code>actions/checkout</code> lại?</span></summary>
<div class="ans">
<p>Vì máy ảo của job mới hoàn toàn trống — không có mã nguồn. Lệnh checkout ở Job A chỉ tải code vào máy ảo của Job A.</p>
</div></details>

<details class="q"><summary><span>Job trước thất bại thì job có <code>needs</code> sẽ ra sao?</span></summary>
<div class="ans">
<p>Bị <strong>Skipped</strong> (bỏ qua, màu xám). Đây là chốt chặn bảo vệ — không lãng phí tài nguyên chạy tiếp trên nền code đã hỏng.</p>
<p>Lưu ý: các job <strong>độc lập</strong> khác vẫn chạy bình thường. Chỉ job phụ thuộc mới bị chặn.</p>
</div></details>

<details class="q"><summary><span>Exit code 126 nghĩa là gì? Khác 127 thế nào?</span></summary>
<div class="ans">
<p><code>126</code> = tìm thấy lệnh nhưng <strong>không chạy được</strong> — thường do thiếu quyền thực thi. Sửa bằng <code>chmod +x ./gradlew</code>.</p>
<p><code>127</code> = <strong>không tìm thấy lệnh</strong> — gõ sai tên hoặc chưa cài công cụ.</p>
</div></details>

<details class="q"><summary><span>Continuous Delivery khác Continuous Deployment ở điểm nào?</span></summary>
<div class="ans">
<p>Đúng <strong>một bước</strong>: có cần người bấm nút duyệt trước khi lên Production hay không.</p>
<p>Delivery = có duyệt tay ("luôn <em>sẵn sàng</em> phát hành"). Deployment = tự động 100% ("tự động <em>phát hành</em> luôn").</p>
<p>Trên GitHub Actions, khác biệt nằm ở việc bật <em>Required reviewers</em> cho environment — <strong>không</strong> phải ở file YAML.</p>
</div></details>

<details class="q"><summary><span>Vì sao không dùng self-hosted runner cho repo public?</span></summary>
<div class="ans">
<p>Vì bất kỳ ai gửi Pull Request đều có thể chạy <strong>code tuỳ ý</strong> trên máy của bạn. Đây là lỗ hổng bảo mật nghiêm trọng.</p>
<p>Self-hosted chỉ nên dùng cho repo private hoặc nội bộ công ty.</p>
</div></details>

<details class="q"><summary><span>Một file YAML làm sao phục vụ được cả 3 môi trường?</span></summary>
<div class="ans">
<p>Dùng <code>github.ref_name</code> (tên nhánh đang push) để suy ra môi trường, ghi kết quả vào <code>$GITHUB_OUTPUT</code>, rồi các job sau đọc qua <code>needs.&lt;job&gt;.outputs.&lt;key&gt;</code>.</p>
<p>Job triển khai gắn <code>environment: name: ${{ ... }}</code> để GitHub áp dụng đúng biến và quy tắc duyệt của môi trường đó.</p>
</div></details>

<details class="q"><summary><span>Thấy test đỏ trên CI thì làm gì đầu tiên?</span></summary>
<div class="ans">
<p>Hỏi: <strong>"Code sai hay test sai?"</strong></p>
<p>Nếu code sai → sửa code. Nếu test sai (yêu cầu nghiệp vụ đã đổi) → sửa test.</p>
<p><strong>Tuyệt đối không</strong> xoá test hoặc sửa assertion cho khớp kết quả sai — đó là che giấu lỗi.</p>
</div></details>

---

# Bảng tra nhanh

| Việc | Lệnh |
|---|---|
| Xem nhánh hiện tại | `git branch --show-current` |
| Liệt kê mọi nhánh | `git branch -a` |
| Chuyển nhánh | `git switch staging` |
| Đồng bộ nhánh môi trường | `git merge main -m "chore: dong bo tu main"` |
| Đẩy nhánh lần đầu | `git push -u origin staging` |
| Commit rỗng để kích hoạt CI | `git commit --allow-empty -m "test: kich hoat CI"` |
| Cấp quyền thực thi trong Git | `git update-index --chmod=+x <file>` |
| Xem quyền file trong Git | `git ls-files -s <file>` |
| Chạy test ở máy | `./gradlew test` |
| Đóng gói JAR ở máy | `./gradlew bootJar` |

**Đường dẫn web hay dùng:**

| Trang | Địa chỉ |
|---|---|
| Danh sách lần chạy | `.../actions` |
| Cấu hình môi trường | `.../settings/environments` |
| Secrets và Variables | `.../settings/secrets/actions` |

> 💡 Bảng lệnh **đầy đủ** kèm 7 thí nghiệm gây lỗi nằm ở file **`S7-02-Lab-thuc-hanh.html`**.

---

# Tám cặp khái niệm hay nhầm

| Cặp | Khác nhau ở chỗ |
|---|---|
| CI ↔ CD | Đảm bảo code tích hợp được ↔ đưa code tới người dùng |
| Continuous **Delivery** ↔ **Deployment** | Có bước duyệt tay ↔ tự động 100% |
| `uses` ↔ `run` | Gọi Action đóng gói sẵn ↔ chạy lệnh shell |
| Job ↔ Step | Máy ảo riêng, song song ↔ cùng máy, tuần tự |
| GitHub-hosted ↔ Self-hosted | GitHub lo, máy sạch, tốn phút ↔ tự lo, có cache, miễn phí |
| `env` ↔ `outputs` | Biến cố định khai báo sẵn ↔ giá trị job trước truyền sang job sau |
| Artifact ↔ Cache | Sản phẩm muốn giữ lại ↔ dữ liệu tạm để tăng tốc build |
| Exit `126` ↔ `127` | Có file nhưng thiếu quyền ↔ không tìm thấy lệnh |

---

# Bài tập về nhà

<div class="grid2">
<div class="card">
<h4>Bài 1 · Bắt buộc</h4>
<p>Viết workflow CI cho <code>restaurant-service</code> dùng <strong>JDK 21</strong>. Giải thích phải đổi những gì so với <code>user-service</code>.</p>
</div>
<div class="card">
<h4>Bài 2 · Bắt buộc</h4>
<p>Thêm job <code>kiem_tra_dinh_dang</code> chạy <strong>song song</strong> với job test, và job <code>tong_ket</code> dùng <code>needs</code> đợi cả hai. <strong>Vẽ sơ đồ luồng trước khi viết YAML.</strong></p>
</div>
<div class="card">
<h4>Bài 3 · Bắt buộc</h4>
<p>Cấu hình GitHub Environments cho <code>uat</code> và <code>release</code> với <em>Required reviewers</em>. Chụp màn hình lúc job dừng chờ duyệt, giải thích đây là Delivery hay Deployment.</p>
</div>
<div class="card ok">
<h4>Bài 4 · Nâng cao</h4>
<p>Dùng <code>matrix</code> chạy test trên <strong>cả JDK 17 và 21</strong> cùng lúc. Giải thích vì sao hữu ích khi nâng cấp phiên bản Java.</p>
</div>
</div>

<div class="card ok" style="margin:17px 0">
<h4>Bài 5 · Nâng cao</h4>
<p>Thêm bước build <strong>Docker image</strong> và đẩy lên GitHub Container Registry (<code>ghcr.io</code>). Giải thích vì sao lưu Docker image tốt hơn lưu file JAR khi triển khai.</p>
</div>

---

# Checklist trước khi rời lớp

- [ ] Biết workflow phải đặt ở `.github/workflows/` tại gốc repository
- [ ] Giải thích được 4 từ khoá `name` / `on` / `env` / `jobs`
- [ ] Phân biệt được `uses` và `run`
- [ ] Biết 3 nguyên nhân khiến tab Actions trống trơn
- [ ] Giải thích được vì sao job mặc định chạy song song
- [ ] Giải thích được `needs` vừa sắp thứ tự vừa là chốt chặn
- [ ] Giải thích được Job Isolation và vì sao mỗi job phải `checkout` lại
- [ ] Biết dùng Artifacts để truyền file giữa các job
- [ ] Kể được vai trò của 3 môi trường `staging` / `uat` / `release`
- [ ] Giải thích được ranh giới giữa Continuous Delivery và Deployment
- [ ] Nhớ bảng Exit code: `1` / `126` / `127` / `137`
- [ ] Biết phải hỏi "code sai hay test sai?" khi thấy test đỏ
