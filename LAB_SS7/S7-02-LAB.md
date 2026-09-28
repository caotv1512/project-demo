# LAB SESSION 07 — BẢNG LỆNH THỰC HÀNH
# GitHub Actions CI/CD · Dự án QuickBite

> **Repo demo:** <https://github.com/caotv1512/project-demo>
> 5 workflow và 3 nhánh môi trường đã chạy thật — mở tab **Actions** là xem được kết quả ngay.

> **Cách dùng:** làm tuần tự BÀI 1 → BÀI 7. Mỗi bài: **lệnh cần gõ** → **kết quả phải thấy** → **thí nghiệm gây lỗi** để hiểu vì sao.

---

# A · CHUẨN BỊ

## A1. Buổi này khác hai buổi trước ở chỗ nào

| | Session 04 · 05 | Session 07 |
|---|---|---|
| Chạy ở đâu | Docker **trên máy bạn** | **Máy chủ của GitHub** |
| Xem kết quả | Terminal | Tab **Actions** trên web |
| Lệnh chính | `docker compose …` | `git push` + đọc log trên web |
| Cần gì | Docker Desktop | Tài khoản GitHub + repo |

> ⚠️ **Đây là thay đổi tư duy lớn nhất.** Bạn không còn "chạy" gì trên máy nữa. Bạn **mô tả** việc cần làm vào file YAML, `git push`, rồi **máy chủ GitHub làm hộ**. Mọi kiểm chứng đều diễn ra trên trình duyệt.

## A2. Đường dẫn và quy tắc thư mục

```
project-demo/                      ← thư mục gốc repository
│
├── .github/                       ← BẮT BUỘC đúng tên này, có dấu chấm ở đầu
│   └── workflows/                 ← BẮT BUỘC có chữ "s" ở cuối
│       ├── 01-in-thong-tin-moi-truong.yml
│       ├── 02-jobs-song-song-va-needs.yml
│       ├── 03-build-jar-va-artifact.yml
│       ├── 04-deploy-3-moi-truong.yml
│       └── 05-tai-hien-3-loi.yml
│
└── quickbite-backend/user-service/   ← mã nguồn Java mà CI sẽ build
    ├── build.gradle
    ├── gradlew
    └── src/
        ├── main/java/com/quickbite/user/WalletRules.java
        └── test/java/com/quickbite/user/WalletRulesTest.java
```

> ⚠️ **Ba lỗi khiến workflow KHÔNG BAO GIỜ chạy — và GitHub không báo gì cả:**
> 1. Viết `.github/workflow/` — **thiếu chữ s**
> 2. Đặt thư mục ở nhánh con thay vì gốc repository
> 3. Sai thụt lề YAML — file không hợp lệ thì GitHub bỏ qua luôn
>
> Không có thông báo lỗi. Tab Actions chỉ đơn giản là **trống**. Nếu gặp tình trạng này, kiểm tra 3 điều trên trước tiên.

## A3. Lệnh Git cần thuộc

| Việc | Lệnh |
|---|---|
| Xem nhánh hiện tại | `git branch --show-current` |
| Liệt kê mọi nhánh | `git branch -a` |
| Chuyển nhánh | `git switch <tên-nhánh>` |
| Tạo nhánh mới từ nhánh hiện tại | `git switch -c <tên-nhánh>` |
| Đẩy nhánh lên GitHub lần đầu | `git push -u origin <tên-nhánh>` |
| Đẩy các lần sau | `git push` |
| Xem trạng thái | `git status` |

## A4. Lệnh theo hệ điều hành

Lệnh `git` giống nhau trên cả 3 hệ. Chỉ lệnh của OS mới khác:

| Việc | macOS · Ubuntu · Git Bash | Windows PowerShell |
|---|---|---|
| Xem file | `cat f` | `Get-Content f` |
| Lọc chữ | `… \| grep x` | `… \| Select-String x` |
| Gọi API | `curl -s <url>` | `curl.exe -s <url>` |
| Cấp quyền thực thi | `chmod +x ./gradlew` | Git quản lý, xem BÀI 6 |

---

# BÀI 1 — WORKFLOW ĐẦU TIÊN

**Mục tiêu:** hiểu 4 từ khoá gốc `name` / `on` / `env` / `jobs`.

## 1.1 · Lấy repo về máy

```bash
git clone https://github.com/caotv1512/project-demo.git
```
```bash
cd project-demo
```

> Nếu đã có sẵn thư mục rồi thì chỉ cần:
> ```bash
> cd ~/Downloads/quickbite-demo && git pull
> ```

## 1.2 · Đọc workflow đầu tiên

```bash
cat .github/workflows/01-in-thong-tin-moi-truong.yml
```

```yaml
name: 01 · In thông tin môi trường      # tên hiển thị trên tab Actions

on:                                      # khi nào chạy
  workflow_dispatch:                     # cho phép bấm nút chạy tay
  push:
    branches: [main, staging, uat, release]

env:                                     # biến dùng chung cho mọi job
  PROJECT_NAME: "QuickBite-User-Service"

jobs:
  in_thong_tin:
    runs-on: ubuntu-latest               # chạy trên Runner của GitHub
    steps:
      - name: Lấy mã nguồn về máy Runner
        uses: actions/checkout@v4        # uses = gọi Action đóng gói sẵn

      - name: Thiết lập môi trường Java 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: In thông tin môi trường
        run: |                           # run = chạy lệnh shell
          echo "Dự án: ${PROJECT_NAME}"
          java -version
          echo "Nhánh Git đang chạy: ${GITHUB_REF_NAME}"
```

| Từ khoá | Nhiệm vụ |
|---|---|
| `name` | Tên hiển thị trên giao diện Actions |
| `on` | Sự kiện kích hoạt. `workflow_dispatch` = nút bấm tay |
| `env` | Biến dùng chung cho **mọi** job |
| `runs-on` | Chọn Runner. Slide dạy `[self-hosted, quickbite]`, ở đây dùng `ubuntu-latest` |
| `uses` | Gọi Action viết sẵn |
| `run` | Chạy lệnh shell trực tiếp |

## 1.3 · Chạy thử bằng nút bấm

Không cần gõ lệnh — làm trên web:

1. Mở <https://github.com/caotv1512/project-demo/actions>
2. Cột trái, chọn **01 · In thông tin môi trường**
3. Bên phải bấm **Run workflow** → chọn nhánh `main` → **Run workflow**
4. Đợi vài giây, tải lại trang, bấm vào lần chạy vừa hiện ra

**Phải thấy:** dấu ✅ xanh, và khi mở step "In thông tin môi trường" sẽ có:
```
Dự án: QuickBite-User-Service
openjdk version "17.0.x" ...
Nhánh Git đang chạy : main
Người kích hoạt     : caotv1512
```

> 💡 **`workflow_dispatch` là người bạn tốt nhất khi dạy học.** Không có nó, muốn chạy thử phải tạo commit giả rồi push — vừa bẩn lịch sử Git vừa chậm.

## 1.4 · Kiểm tra bằng dòng lệnh (không cần mở web)

```bash
curl -s "https://api.github.com/repos/caotv1512/project-demo/actions/runs?per_page=5" | grep -E '"name"|"conclusion"|"head_branch"'
```

**Phải thấy:** tên workflow kèm `"conclusion": "success"`

---

## 🧪 Thí nghiệm 1 — Đặt workflow sai chỗ

```bash
cd ~/Downloads/quickbite-demo
```
```bash
mkdir -p .github/workflow && cp .github/workflows/01-in-thong-tin-moi-truong.yml .github/workflow/sai-cho.yml
```
```bash
git add .github/workflow && git commit -q -m "test: dat workflow sai thu muc" && git push
```

Mở tab Actions, đợi 30 giây rồi tải lại.

**Sẽ thấy:** **không có gì xảy ra**. Không có lần chạy mới, không có thông báo lỗi.

**Vì sao:** GitHub chỉ quét đúng thư mục `.github/workflows/` (có chữ **s**). Thư mục `.github/workflow/` bị bỏ qua hoàn toàn — **im lặng**, không cảnh báo.

**Khôi phục:**
```bash
rm -rf .github/workflow && git add -A && git commit -q -m "revert: xoa thu muc sai" && git push
```

> 💡 **Bài học:** khi tab Actions trống trơn, đừng đoán mò. Kiểm tra 3 thứ theo thứ tự: tên thư mục → vị trí (phải ở gốc repo) → cú pháp YAML.

---

# BÀI 2 — JOBS SONG SONG VÀ `needs`

**Mục tiêu:** thấy tận mắt 2 job chạy cùng lúc, và job thứ 3 phải đợi.

## 2.1 · Đọc workflow

```bash
cat .github/workflows/02-jobs-song-song-va-needs.yml
```

Cấu trúc:
```
job_info_1  ─┐  không có needs → chạy SONG SONG
job_info_2  ─┘
      │
      └──► job_print   (needs: [job_info_1, job_info_2])
```

## 2.2 · Chạy và quan sát sơ đồ

1. Vào Actions → chọn **02 · Jobs song song và needs**
2. Bấm **Run workflow**, để nguyên ô "Cho job_info_1 thất bại" (không tick)
3. Bấm vào lần chạy → xem **sơ đồ luồng** hiện ngay trên trang

**Phải thấy:** `job_info_1` và `job_info_2` nằm **cùng một cột** (song song), `job_print` nằm cột sau, có mũi tên nối vào.

## 2.3 · Chứng minh chúng thật sự chạy cùng lúc

Mở log của `job_info_1` và `job_info_2`, tìm dòng:
```
job_info_1 bắt đầu lúc 09:15:32
job_info_2 bắt đầu lúc 09:15:33
```

**Phải thấy:** hai mốc thời gian **gần như trùng nhau** — đó là bằng chứng chúng chạy song song, không nối tiếp.

> `job_info_2` có bước `sleep 20`. Nếu chạy tuần tự thì `job_info_1` phải đợi 20 giây. Nhìn dấu thời gian sẽ thấy nó **không** đợi.

## 2.4 · Chứng minh Job Isolation

Mở log job **Chứng minh Job Isolation**.

**Phải thấy:**
```
KHÔNG tìm thấy — đúng như lý thuyết.
Mỗi job chạy trên một máy ảo SẠCH, hoàn toàn riêng biệt.
```
và
```
Nội dung thư mục làm việc khi CHƯA checkout:
→ Rỗng. Mỗi job phải tự chạy actions/checkout của riêng mình.
```

> ⚠️ **Đây là hiểu nhầm phổ biến nhất khi mới học.** Sinh viên hay nghĩ các job nối tiếp nhau như các dòng trong một script. **Không phải.** Mỗi job là **một máy ảo hoàn toàn mới**. Kể cả có `needs`, Job B vẫn không thấy gì của Job A — kể cả mã nguồn.

---

## 🧪 Thí nghiệm 2 — Job trước lỗi thì job sau bị Skipped

1. Vào Actions → **02 · Jobs song song và needs** → **Run workflow**
2. Lần này **tick** vào ô *"Cho job_info_1 thất bại"*
3. Bấm Run, đợi chạy xong

**Sẽ thấy trên sơ đồ:**

| Job | Trạng thái |
|---|---|
| `job_info_1` | ❌ **Failure** (đỏ) |
| `job_info_2` | ✅ Success (xanh) — vẫn chạy bình thường vì độc lập |
| `job_print` | ⊘ **Skipped** (xám) |
| `job_chung_minh_co_lap` | ⊘ **Skipped** (xám) |

**Vì sao:** `needs` không chỉ sắp xếp thứ tự — nó còn là **chốt chặn**. Job phụ thuộc bị bỏ qua khi job trước thất bại, để **không lãng phí tài nguyên** chạy tiếp trên nền code đã hỏng.

> 💡 Chú ý `job_info_2` **vẫn chạy** dù `job_info_1` hỏng. Vì hai job này độc lập với nhau — chỉ những job **phụ thuộc** mới bị chặn.

---

# BÀI 3 — BUILD JAR VÀ LƯU ARTIFACT

**Mục tiêu:** CI tự đóng gói JAR, không còn phụ thuộc máy cá nhân.

## 3.1 · Đọc workflow

```bash
cat .github/workflows/03-build-jar-va-artifact.yml
```

Cấu trúc 2 job:
```
kiem_thu (chạy test)  ──needs──►  dong_goi (đóng gói JAR + upload artifact)
```

> **Vì sao tách 2 job:** test và đóng gói là hai mối quan tâm khác nhau. Tách ra thì khi test hỏng, bạn thấy ngay job nào đỏ mà không phải đọc log dài. Và job đóng gói **bị chặn** — không tạo ra JAR từ code lỗi.

## 3.2 · Chạy thử ở máy trước khi đẩy lên CI

```bash
cd ~/Downloads/quickbite-demo/quickbite-backend/user-service
```
```bash
./gradlew test
```
**Phải thấy:** 6 dòng `PASSED` và `BUILD SUCCESSFUL`

> ⚠️ **Luôn chạy test ở máy trước khi push.** Chạy ở máy mất 10 giây. Đẩy lên CI rồi đợi mất 2–3 phút mỗi vòng. **CI không phải chỗ để thử nghiệm.**

## 3.3 · Kích hoạt CI bằng cách push code

```bash
cd ~/Downloads/quickbite-demo
```
```bash
git switch main && git pull
```

Sửa một chỗ nhỏ trong code để có gì đó mà push:
```bash
echo "// thu kich hoat CI $(date +%H:%M:%S)" >> quickbite-backend/user-service/src/main/java/com/quickbite/user/WalletRules.java
```
```bash
git add -A && git commit -q -m "test: kich hoat CI" && git push
```

## 3.4 · Xem kết quả

Mở <https://github.com/caotv1512/project-demo/actions>

**Phải thấy:** workflow **03 · Build JAR và lưu Artifact** đang chạy, với 2 job nối tiếp.

Khi xong, cuộn xuống cuối trang lần chạy:

**Phải thấy** mục **Artifacts** có:
- `user-service-jar` (~21 MB)
- `bao-cao-test`

Bấm vào để tải file JAR về — **đây chính là thành phẩm do máy chủ GitHub build, không phải máy bạn**.

## 3.5 · Kiểm tra artifact bằng dòng lệnh

```bash
curl -s "https://api.github.com/repos/caotv1512/project-demo/actions/artifacts?per_page=10" | grep -E '"name"|"size_in_bytes"'
```

---

## 🧪 Thí nghiệm 3 — Bỏ `cache: gradle` xem chậm thế nào

Mở lần chạy workflow 03, xem thời gian job `kiem_thu`.

**Lần đầu (chưa có cache):** khoảng 2–3 phút
**Lần sau (đã có cache):** khoảng 40–60 giây

**Vì sao:** không có cache, Runner phải tải lại toàn bộ thư viện Spring Boot (~100MB) **mỗi lần chạy**, vì máy ảo luôn mới tinh. Dòng `cache: gradle` trong `actions/setup-java` lưu lại thư mục `~/.gradle` giữa các lần chạy.

> 💡 **Một dòng YAML đổi lấy rất nhiều thời gian chờ** — và nếu repo private thì đổi lấy cả phút miễn phí.

---

# BÀI 4 — BA MÔI TRƯỜNG: staging · uat · release

**Mục tiêu:** một workflow phục vụ cả ba môi trường, nhánh Git quyết định môi trường nào.

## 4.1 · Xem 3 nhánh đã có

```bash
cd ~/Downloads/quickbite-demo && git fetch --all
```
```bash
git branch -a
```
**Phải thấy:** `main`, `staging`, `uat`, `release` và bản `remotes/origin/*` tương ứng

## 4.2 · Hiểu vai trò từng nhánh

| Nhánh | Môi trường | Ai dùng | Cổng | Nhãn phiên bản | Duyệt tay |
|---|---|---|---|---|---|
| `staging` | Staging | Đội phát triển | 8101 | `snapshot` | Không |
| `uat` | UAT | **Khách hàng / QA** | 8102 | `rc` | **Có** |
| `release` | Release | Đội vận hành | 8103 | `stable` | **Có** |

> **Nguyên tắc:** càng về sau, chi phí sửa sai càng đắt. Hỏng ở `staging` mất 5 phút. Hỏng ở `uat` mất uy tín với khách. Hỏng ở `release` mất tiền. Vì vậy mức kiểm soát phải **tăng dần**.

## 4.3 · Đọc workflow 3 môi trường

```bash
cat .github/workflows/04-deploy-3-moi-truong.yml
```

Cấu trúc 3 job:
```
xac_dinh_moi_truong  ──►  kiem_thu_va_dong_goi  ──►  trien_khai
   (đọc tên nhánh)          (test + build JAR)      (environment: ...)
```

**Kỹ thuật ① — `outputs` truyền giá trị giữa các job:**
```yaml
outputs:
  ten_moi_truong: ${{ steps.chon.outputs.ten_moi_truong }}
```
Job Isolation nói file không chia sẻ được — nhưng **giá trị chuỗi** thì có, qua `outputs`.

**Kỹ thuật ② — `environment` gắn job vào môi trường GitHub:**
```yaml
environment:
  name: ${{ needs.xac_dinh_moi_truong.outputs.ten_moi_truong }}
```

## 4.4 · Triển khai lên staging

```bash
git switch staging && git pull
```
```bash
git merge main -m "chore: dong bo tu main" && git push
```

Mở tab Actions.

**Phải thấy:** workflow **04 · Deploy theo môi trường** chạy, job cuối tên là **"Triển khai lên staging"**.

Mở log job cuối, **phải thấy:**
```
==================================================
 TRIỂN KHAI LÊN MÔI TRƯỜNG: staging
==================================================
Cấu hình môi trường staging:
  Cổng dịch vụ : 8101
  Database     : quickbite_user_db_staging
```

## 4.5 · Triển khai lên uat và release

```bash
git switch uat && git pull && git merge main -m "chore: dong bo tu main" && git push
```
```bash
git switch release && git pull && git merge main -m "chore: dong bo tu main" && git push
```

**Phải thấy:** mỗi nhánh kích hoạt **một** lần chạy riêng, với cổng và nhãn phiên bản khác nhau:

| Nhánh | Cổng trong log | Artifact sinh ra |
|---|---|---|
| `staging` | 8101 | `jar-staging` |
| `uat` | 8102 | `jar-uat` |
| `release` | 8103 | `jar-release` |

```bash
curl -s "https://api.github.com/repos/caotv1512/project-demo/actions/artifacts?per_page=10" | grep '"name"'
```
**Phải thấy:** `jar-staging`, `jar-uat`, `jar-release`

> 💡 **Điểm cốt lõi:** chỉ có **một** file YAML. Không copy-paste ba lần. Tên nhánh quyết định mọi thứ.

## 4.6 · Bật duyệt tay cho uat và release

Làm trên web — đây là chỗ Continuous **Delivery** và **Deployment** tách đôi:

1. Vào <https://github.com/caotv1512/project-demo/settings/environments>
2. **New environment** → đặt tên `staging` → **Configure environment** → không bật gì → Save
3. Tạo tiếp `uat`:
   - Tick **Required reviewers** → thêm chính bạn
   - **Save protection rules**
4. Tạo `release` tương tự `uat`

Thêm biến riêng cho từng môi trường: trong mỗi environment, mục **Environment variables** → **Add variable**:

| Environment | Name | Value |
|---|---|---|
| `staging` | `API_URL` | `https://staging.quickbite.vn` |
| `uat` | `API_URL` | `https://uat.quickbite.vn` |
| `release` | `API_URL` | `https://quickbite.vn` |

## 4.7 · Kiểm chứng cơ chế duyệt

```bash
git switch uat && git commit -q --allow-empty -m "test: kiem tra co che duyet" && git push
```

Mở tab Actions.

**Phải thấy:** job **"Triển khai lên uat"** dừng ở trạng thái **Waiting**, kèm nút vàng **Review deployments**.

Bấm nút đó → tick `uat` → **Approve and deploy**. Job mới chạy tiếp.

**Phải thấy trong log:** `API_URL = https://uat.quickbite.vn` — giá trị lấy từ environment, không phải từ YAML.

> 💡 **Đây chính là ranh giới giữa hai chữ CD:**
> - Có *Required reviewers* → Continuous **Delivery** (luôn sẵn sàng phát hành, người quyết định khi nào)
> - Không bật gì → Continuous **Deployment** (tự động 100%)
>
> **Cùng một file YAML**, khác nhau ở cấu hình trên web.

---

## 🧪 Thí nghiệm 4 — Push nhánh không nằm trong danh sách

```bash
git switch -c thu-nghiem main
```
```bash
git commit -q --allow-empty -m "test: nhanh khong nam trong danh sach" && git push -u origin thu-nghiem
```

**Sẽ thấy:** workflow 04 **không chạy**.

**Vì sao:** khối `on` chỉ liệt kê 3 nhánh:
```yaml
on:
  push:
    branches: [staging, uat, release]
```
Nhánh `thu-nghiem` không khớp nên GitHub bỏ qua.

**Dọn dẹp:**
```bash
git push origin --delete thu-nghiem && git switch main && git branch -D thu-nghiem
```

---

# BÀI 5 — BA LỖI CI KINH ĐIỂN

**Mục tiêu:** đọc được log lỗi và nhận diện Exit code.

Workflow `05-tai-hien-3-loi.yml` cho phép **bấm nút để tái hiện từng lỗi**.

## 5.1 · Quy trình 4 bước chẩn đoán

| Bước | Việc làm |
|---|---|
| **01** | Tìm job có dấu **X đỏ** trong tab Actions |
| **02** | Bấm vào job lỗi, **mở rộng step bị sập** |
| **03** | Cuộn xuống cuối xem **Exit code**, rồi lần ngược lên đọc Error Trace |
| **04** | Sửa code, **chạy thử ở máy thật kỹ** rồi mới push |

---

## 🧪 Thí nghiệm 5 — Lỗi Permission denied (Exit code 126)

1. Actions → **05 · Tái hiện 3 lỗi CI kinh điển** → **Run workflow**
2. Chọn `exit-126 Permission denied` → Run

**Sẽ thấy trong log:**
```
Run ./gradlew test
/home/runner/work/_temp/...: line 1: ./gradlew: Permission denied
Error: Process completed with exit code 126.
```

**Vì sao:** tệp `gradlew` mất thuộc tính quyền thực thi (execute bit). Thường xảy ra khi file được tạo trên **Windows** — hệ điều hành này không quản lý quyền file như Linux. Push lên Runner chạy Linux thì bị từ chối.

**Khắc phục — thêm bước trước khi build:**
```yaml
- name: Cấp quyền thực thi cho Gradle Wrapper
  run: chmod +x ./gradlew
```

> 💡 **Cách sửa triệt để hơn** — ghi quyền vào Git một lần cho mãi mãi:
> ```bash
> git update-index --chmod=+x quickbite-backend/user-service/gradlew
> ```
> ```bash
> git commit -q -m "fix: cap quyen thuc thi cho gradlew" && git push
> ```
> Nhưng vẫn **nên giữ** bước `chmod +x` trong YAML như lưới an toàn.

---

## 🧪 Thí nghiệm 6 — Lỗi Compilation Failed (Exit code 1)

1. Actions → workflow 05 → **Run workflow**
2. Chọn `exit-1 Compilation failed` → Run

**Sẽ thấy trong log:**
```
> Task :compileJava FAILED
.../UserController.java:19: error: class UserControler is public, should be declared in a file named UserControler.java
Error: Process completed with exit code 1.
```

**Vì sao:** trình biên dịch Java từ chối tạo bytecode do lỗi cú pháp, tại **dòng cụ thể**. CI ngắt ngay để ngăn đóng gói sản phẩm lỗi.

**Khắc phục:** định vị file theo đường dẫn trong log, sửa lại đúng cú pháp.

> 💡 **Cách đọc log Java:** đọc **dòng đầu tiên** có chữ `error:` — nó chỉ đúng file và số dòng. Các dòng sau thường chỉ là hệ quả dây chuyền.

---

## 🧪 Thí nghiệm 7 — Lỗi Test Failed (Exit code 1)

1. Actions → workflow 05 → **Run workflow**
2. Chọn `exit-1 Test failed` → Run

**Sẽ thấy trong log:**
```
WalletRulesTest > Tinh dung so du con lai FAILED
    org.opentest4j.AssertionFailedError: expected: <999999> but was: <425000>
6 tests completed, 1 failed
> Task :test FAILED
Error: Process completed with exit code 1.
```

**Vì sao:** biên dịch đã **thành công**, nhưng giá trị khẳng định (Assertion) trong test sai lệch so với thực tế. Gradle kích hoạt "Fail-fast" huỷ đóng gói ngay, ngăn tạo ra JAR lỗi.

**Tái hiện ở máy để đối chiếu:**
```bash
cd ~/Downloads/quickbite-demo/quickbite-backend/user-service
```
```bash
sed -i '' 's/assertEquals(425_000/assertEquals(999_999/' src/test/java/com/quickbite/user/WalletRulesTest.java
```
```bash
./gradlew test
```
**Sẽ thấy:** `6 tests completed, 1 failed` — **giống hệt** log trên CI

**Khôi phục:**
```bash
sed -i '' 's/assertEquals(999_999/assertEquals(425_000/' src/test/java/com/quickbite/user/WalletRulesTest.java && ./gradlew test
```

> ⚠️ **Điều tuyệt đối không được làm:** thấy test đỏ thì xoá test đi, hoặc sửa assertion cho khớp kết quả sai. Phải hỏi trước: **"Code sai hay test sai?"** Sửa nhầm là bạn vừa che giấu một lỗi thật — và nó sẽ nổ ở production.

---

## 5.2 · Bảng Exit code

| Exit code | Ý nghĩa | Hay gặp khi |
|---|---|---|
| `0` | Thành công | — |
| `1` | Lỗi chung của ứng dụng | Compile fail, test fail |
| `126` | Tìm thấy lệnh nhưng **không chạy được** | Thiếu `chmod +x` |
| `127` | **Không tìm thấy lệnh** | Gõ sai tên, chưa cài công cụ |
| `137` | Bị `SIGKILL` (128+9) | **Hết RAM** trên Runner |

> 💡 **Phân biệt `126` và `127`:** `126` = "có file nhưng không chạy được" (lỗi quyền). `127` = "không có file đó" (sai tên hoặc chưa cài). Hai số gần nhau nhưng nguyên nhân khác hẳn.

---

# BÀI 6 — LỖI RIÊNG CỦA SINH VIÊN WINDOWS

## 6.1 · Vì sao Windows hay gặp lỗi 126

Windows **không có khái niệm execute bit** như Linux. Khi bạn tạo hoặc sửa `gradlew` trên Windows rồi commit, Git ghi nhận file **không có quyền thực thi**. Runner chạy Linux đọc đúng như vậy và từ chối chạy.

## 6.2 · Kiểm tra quyền hiện tại của file trong Git

```bash
git ls-files -s quickbite-backend/user-service/gradlew
```

**Cách đọc kết quả:**
- Bắt đầu bằng `100755` → **có** quyền thực thi ✅
- Bắt đầu bằng `100644` → **không** có quyền thực thi ❌

## 6.3 · Sửa vĩnh viễn

```bash
git update-index --chmod=+x quickbite-backend/user-service/gradlew
```
```bash
git commit -q -m "fix: cap quyen thuc thi cho gradlew" && git push
```

## 6.4 · Lỗi CRLF

Windows kết thúc dòng bằng `CRLF`, Linux dùng `LF`. File `.sh` bị CRLF sẽ không chạy được trên Runner.

**Phòng ngừa — cấu hình một lần trước khi clone:**
```bash
git config --global core.autocrlf input
```

**Sửa file đã bị hỏng:**
```bash
sed -i 's/\r$//' *.sh
```

---

# BÀI 7 — TÌM LỖI

> ⚠️ **Về đúng thư mục trước đã:**
> ```bash
> cd ~/Downloads/quickbite-demo
> ```

## Bước 1 — Workflow có chạy không?

```bash
curl -s "https://api.github.com/repos/caotv1512/project-demo/actions/runs?per_page=5" | grep -E '"name"|"status"|"conclusion"'
```

**Không có lần chạy nào?** → xem Thí nghiệm 1: sai thư mục, sai vị trí, hoặc YAML lỗi.

## Bước 2 — Workflow đã được đăng ký chưa?

```bash
curl -s "https://api.github.com/repos/caotv1512/project-demo/actions/workflows" | grep -E '"name"|"state"'
```
**Phải thấy:** đủ 5 workflow, `"state": "active"`

## Bước 3 — Kiểm tra cú pháp YAML ở máy

```bash
python3 -c "import yaml,glob;[yaml.safe_load(open(f)) for f in glob.glob('.github/workflows/*.yml')];print('YAML hop le')"
```
**Phải thấy:** `YAML hop le`

> Thiếu thư viện thì cài: `python3 -m pip install --user pyyaml`

## Bước 4 — Chạy thử ở máy trước khi đổ cho CI

```bash
cd ~/Downloads/quickbite-demo/quickbite-backend/user-service && ./gradlew test
```

> **Nguyên tắc vàng:** nếu ở máy đã hỏng thì CI hỏng là **đương nhiên**. Sửa ở máy trước, đừng dùng CI làm chỗ thử.

## Bước 5 — Đọc log trên web

Vào tab Actions → bấm job đỏ → mở rộng step sập → cuộn xuống cuối xem **Exit code** → lần ngược lên đọc Error Trace.

## Bước 6 — Tải log về đọc offline

Trên trang lần chạy, góc phải có nút ⚙️ → **Download log archive**. Tải được file zip chứa toàn bộ log của mọi job.

---

# PHỤ LỤC 1 · BẢNG TRA NHANH

## Git

| Việc | Lệnh |
|---|---|
| Xem nhánh hiện tại | `git branch --show-current` |
| Liệt kê mọi nhánh | `git branch -a` |
| Lấy thông tin nhánh mới từ remote | `git fetch --all` |
| Chuyển nhánh | `git switch staging` |
| Tạo nhánh mới | `git switch -c <tên>` |
| Đồng bộ nhánh môi trường từ main | `git merge main -m "chore: dong bo tu main"` |
| Đẩy lần đầu | `git push -u origin <tên>` |
| Commit rỗng để kích hoạt CI | `git commit --allow-empty -m "test: kich hoat CI"` |
| Cấp quyền thực thi trong Git | `git update-index --chmod=+x <file>` |
| Xem quyền file trong Git | `git ls-files -s <file>` |

## Kiểm tra CI bằng dòng lệnh

| Việc | Lệnh |
|---|---|
| 5 lần chạy gần nhất | `curl -s "https://api.github.com/repos/caotv1512/project-demo/actions/runs?per_page=5" \| grep -E '"name"\|"conclusion"'` |
| Danh sách workflow | `curl -s ".../actions/workflows" \| grep '"name"'` |
| Danh sách artifact | `curl -s ".../actions/artifacts" \| grep '"name"'` |
| Danh sách nhánh | `curl -s ".../branches" \| grep '"name"'` |

## Gradle ở máy

| Việc | Lệnh |
|---|---|
| Chạy test | `./gradlew test` |
| Đóng gói JAR | `./gradlew bootJar` |
| Test + đóng gói | `./gradlew build` |
| Dọn thư mục build | `./gradlew clean` |

## Đường dẫn web hay dùng

| Trang | Địa chỉ |
|---|---|
| Danh sách lần chạy | `github.com/caotv1512/project-demo/actions` |
| Cấu hình môi trường | `github.com/caotv1512/project-demo/settings/environments` |
| Secrets và Variables | `github.com/caotv1512/project-demo/settings/secrets/actions` |
| Bảo vệ nhánh | `github.com/caotv1512/project-demo/settings/branches` |

---

# PHỤ LỤC 2 · BẢNG LỖI

## 7 thí nghiệm trong tài liệu này

| # | Triệu chứng | Nguyên nhân | Sửa |
|---|---|---|---|
| 1 | Tab Actions trống trơn | Sai thư mục `.github/workflow/` (thiếu **s**) | Đổi đúng tên `workflows` |
| 2 | Job sau bị `Skipped` xám | Job trước trong `needs` đã thất bại | Sửa job trước — đây là tính năng bảo vệ, không phải lỗi |
| 3 | Build chậm 2–3 phút mỗi lần | Không bật cache | Thêm `cache: gradle` vào `setup-java` |
| 4 | Push nhánh mà workflow không chạy | Nhánh không có trong `on.push.branches` | Thêm nhánh vào danh sách |
| 5 | `Permission denied` exit 126 | Mất execute bit của `gradlew` | `chmod +x ./gradlew` hoặc `git update-index --chmod=+x` |
| 6 | `cannot find symbol` exit 1 | Lỗi cú pháp Java | Sửa theo file và dòng ghi trong log |
| 7 | `AssertionFailedError` exit 1 | Test thất bại | Hỏi "code sai hay test sai?" rồi mới sửa |

## Lỗi khác

| Triệu chứng | Sửa |
|---|---|
| Job sau không thấy file của job trước | Dùng `upload-artifact` / `download-artifact` |
| Job sau không có mã nguồn | Mỗi job phải tự chạy `actions/checkout` |
| `no tests found` | Thêm `useJUnitPlatform()` vào `build.gradle` |
| Job dừng ở trạng thái `Waiting` | Đúng như thiết kế — environment có *Required reviewers*, bấm **Review deployments** |
| Hết phút miễn phí | Thêm bộ lọc `paths` vào `on`, hoặc chuyển self-hosted |
| Exit code 137 | Hết RAM trên Runner — giảm tải hoặc dùng runner lớn hơn |
| Windows: `.sh` báo `bad interpreter` | Lỗi CRLF — `sed -i 's/\r$//' *.sh` |

---

# ✅ CHECKLIST

- [ ] Biết workflow phải đặt ở `.github/workflows/` tại gốc repository
- [ ] Giải thích được 4 từ khoá `name` / `on` / `env` / `jobs`
- [ ] Phân biệt được `uses` và `run`
- [ ] **Thí nghiệm 1:** biết 3 nguyên nhân khiến tab Actions trống
- [ ] Chứng minh được 2 job chạy song song bằng dấu thời gian
- [ ] **Thí nghiệm 2:** giải thích được vì sao job sau bị `Skipped`
- [ ] Giải thích được Job Isolation và vì sao mỗi job phải `checkout` lại
- [ ] Chạy được workflow build JAR và tải artifact về
- [ ] **Thí nghiệm 3:** hiểu tác dụng của `cache: gradle`
- [ ] Triển khai được lên cả 3 nhánh `staging` / `uat` / `release`
- [ ] Cấu hình được GitHub Environment với *Required reviewers*
- [ ] Giải thích được ranh giới giữa Continuous Delivery và Deployment
- [ ] **Thí nghiệm 5:** nhận diện và sửa được lỗi exit code 126
- [ ] **Thí nghiệm 6:** đọc được log lỗi biên dịch
- [ ] **Thí nghiệm 7:** phân biệt được "code sai" và "test sai"
- [ ] Nhớ bảng Exit code: `1` / `126` / `127` / `137`
- [ ] Biết 6 bước tìm lỗi ở BÀI 7
