# ĐỒ ÁN CUỐI MÔN — MiniMart

> Thời lượng: **4 ngày**. Hình thức: **nhóm 3 sinh viên**. Nộp theo mốc cuối mỗi ngày.
> Đề ra cho nhóm 3 người; nhóm 2 người được giảm một hạng mục theo mục 10.3.

---

# 1. Tóm tắt một trang

Mỗi nhóm xây dựng **MiniMart** — một hệ thống bán hàng trực tuyến thu nhỏ gồm bốn microservice và một cổng vào, rồi đưa hệ thống đó lên môi trường thật: có tên miền, có HTTPS, có pipeline tự động, có giám sát, có log tập trung và truy vết được từng request.

Trọng tâm chấm điểm **không nằm ở nghiệp vụ**. Nghiệp vụ được cố ý giữ ở mức nhỏ nhất đủ để sinh ra một chuỗi gọi liên service có thể thất bại. Toàn bộ điểm số nằm ở chuỗi vận hành: đóng gói, tự động hoá, triển khai, bảo vệ, quan sát và điều tra sự cố.

Sản phẩm cuối cùng phải chứng minh được một việc duy nhất, và đây cũng là câu hỏi đầu tiên của buổi vấn đáp:

> Một đơn hàng thất bại trên môi trường thật. Nhóm có chỉ ra được **service nào gây ra**, **lúc mấy giờ**, **vì lý do gì** — chỉ bằng một mã truy vết, không mở mã nguồn, không đoán — hay không?

---

# 2. Phạm vi bắt buộc

Chín hạng mục dưới đây ánh xạ trực tiếp về các buổi học. Thiếu hạng mục nào thì mất trọn điểm của hạng mục đó.

| # | Hạng mục | Buổi học nguồn |
|---|---|---|
| 1 | Mỗi service có `Dockerfile` riêng, dựng được bằng một file Compose | Session 04 |
| 2 | Bốn service độc lập, mỗi service một database riêng, gọi nhau qua một cổng vào duy nhất | Session 05 |
| 3 | Pipeline CI chạy trên GitHub Actions: build, test, báo trạng thái | Session 07 |
| 4 | CI dựng image và đẩy lên registry `ghcr.io`, gắn tag theo commit | Session 08 |
| 5 | Triển khai lên một máy chủ công khai Ubuntu 24.04, có người dùng quản trị riêng và SSH khoá | Session 10 |
| 6 | Nginx làm reverse proxy, HTTPS bằng chứng chỉ Let's Encrypt trên tên miền thật | Session 11 |
| 7 | Prometheus thu thập số đo từ `actuator/prometheus` của cả bốn service | Session 13 |
| 8 | Grafana có dashboard riêng của nhóm, tối thiểu sáu biểu đồ có ý nghĩa | Session 14 |
| 9 | Log dạng JSON theo chuẩn ECS, gom vào EFK, truy vết một request xuyên bốn service bằng `trace.id` | Session 16, 17 |

---

# 3. Kiến trúc tối thiểu

## 3.1 · Năm thành phần ứng dụng

| Thành phần | Trách nhiệm | Database |
|---|---|---|
| `gateway` | Cổng vào duy nhất, định tuyến theo đường dẫn | Không |
| `catalog-service` | Danh mục hàng và tồn kho | `minimart_catalog_db` |
| `customer-service` | Khách hàng và số dư ví | `minimart_customer_db` |
| `order-service` | Tạo đơn và điều phối toàn bộ luồng | `minimart_order_db` |
| `shipping-service` | Lập phiếu giao, có quyền **từ chối** đơn | `minimart_shipping_db` |

Bốn database nằm trong cùng một container PostgreSQL nhưng là bốn database tách biệt. Một service **không được** truy cập database của service khác; mọi trao đổi dữ liệu đi qua lời gọi HTTP.

## 3.2 · Luồng nghiệp vụ xương sống

Toàn bộ đồ án chỉ cần đúng một luồng nghiệp vụ, gồm sáu bước:

| Bước | Service thực hiện | Việc làm |
|---|---|---|
| 1 | `order-service` | Nhận yêu cầu đặt hàng, tạo đơn trạng thái `PENDING` |
| 2 | `catalog-service` | Kiểm tra và giữ tồn kho |
| 3 | `customer-service` | Trừ tiền trong ví khách hàng |
| 4 | `shipping-service` | Lập phiếu giao — **hoặc từ chối** |
| 5 | `customer-service` | Hoàn tiền nếu bước 4 từ chối |
| 6 | `order-service` | Kết đơn ở trạng thái `CONFIRMED` hoặc `CANCELLED` |

Ngoài luồng này, mỗi service được phép có thêm tối đa ba endpoint phụ trợ phục vụ việc tạo dữ liệu mẫu và kiểm tra. Viết thêm nghiệp vụ không làm tăng điểm.

## 3.3 · Kịch bản sự cố bắt buộc

Hệ thống phải có **một điều kiện từ chối có kiểm soát** ở `shipping-service`, bật tắt được bằng một lời gọi API. Ví dụ: địa chỉ nằm ngoài vùng giao hàng.

Yêu cầu với kịch bản này:

- Khi bị từ chối, API vẫn trả về `HTTP 200` kèm đơn ở trạng thái `CANCELLED`, tiền đã được hoàn.
- `shipping-service` ghi log mức `WARN` **không kèm ngoại lệ** — đây là nguyên nhân gốc.
- `order-service` ghi log mức `WARN` **có kèm ngoại lệ** của lời gọi liên service — đây là hậu quả.
- Hai dòng log trên phải cách nhau một khoảng đo được bằng mili giây, và cùng mang một `trace.id`.

Kịch bản này là vật liệu cho báo cáo sự cố ở mục 6.6. Hệ thống không dựng được sự cố thì không có gì để điều tra, và mất trọn 15 điểm của hạng mục 9.

---

# 4. Biến thể đề theo nhóm

Khung kỹ thuật giống nhau, lĩnh vực nghiệp vụ khác nhau. Giảng viên gán biến thể cho từng nhóm trước khi bắt đầu. Nhóm nộp bài với biến thể không được gán sẽ bị chấm lại từ đầu.

| Nhóm | Lĩnh vực | Bốn service tương ứng | Điều kiện từ chối có kiểm soát |
|---|---|---|---|
| 1 | Bán lẻ trực tuyến | catalog, customer, order, shipping | Địa chỉ ngoài vùng giao |
| 2 | Đặt vé xem phim | suất chiếu, khán giả, đặt chỗ, xuất vé | Suất chiếu đã khoá trước giờ chiếu |
| 3 | Đặt phòng khách sạn | phòng, khách, đặt phòng, xác nhận | Phòng đang bảo trì |
| 4 | Thuê xe tự lái | xe, khách, hợp đồng, bàn giao | Xe chưa qua kiểm định |
| 5 | Khoá học trực tuyến | khoá học, học viên, ghi danh, cấp quyền | Lớp đã đủ sĩ số |
| 6 | Phòng khám | lịch bác sĩ, bệnh nhân, đặt lịch, xác nhận | Bác sĩ nghỉ đột xuất |
| 7 | Giao đồ ăn | món, khách, đơn, nhà hàng nhận đơn | Nhà hàng ngoài giờ mở cửa |
| 8 | Giao hàng nội thành | bưu kiện, người gửi, vận đơn, điều phối | Quá tải trọng cho phép |

---

# 5. Kế hoạch bốn ngày

Mỗi ngày có một mốc nộp. Mốc nộp là **ảnh chụp màn hình kèm liên kết commit**, gửi vào kênh của lớp trước 22 giờ cùng ngày. Nộp dồn vào ngày cuối bị trừ 10 điểm.

## Ngày 1 — Chạy được trên máy cá nhân

| Việc | Kết quả phải có |
|---|---|
| Dựng bốn service và gateway | `docker compose ps` hiện đủ sáu container, tất cả `Up` |
| Bốn database tách biệt | Lệnh truy vấn chéo database trả về lỗi từ chối quyền |
| Luồng sáu bước chạy thông | Một lệnh `curl` đặt hàng trả về đơn `CONFIRMED` |
| Kịch bản từ chối chạy được | Bật điều kiện từ chối, đặt lại đơn, nhận `CANCELLED` và tiền đã hoàn |

**Mốc nộp 1:** ảnh `docker compose ps` và kết quả hai lệnh đặt hàng, một thành công một bị huỷ.

## Ngày 2 — Tự động hoá và lên máy chủ

| Việc | Kết quả phải có |
|---|---|
| Workflow CI | Mỗi lần đẩy mã lên nhánh chính, CI chạy và báo xanh |
| Đẩy image lên registry | Bốn image trên `ghcr.io`, tag là bảy ký tự đầu của commit |
| Khởi tạo máy chủ | Ubuntu 24.04, người dùng quản trị riêng, đăng nhập bằng khoá, đã tắt đăng nhập mật khẩu |
| Triển khai lần đầu | Hệ thống chạy trên máy chủ bằng image kéo từ registry, không build trên máy chủ |

**Mốc nộp 2:** ảnh trang Actions báo xanh, ảnh danh sách image trên registry, và kết quả `curl` vào địa chỉ IP công khai.

## Ngày 3 — Che chắn và quan sát

| Việc | Kết quả phải có |
|---|---|
| Nginx reverse proxy | Chỉ cổng 80 và 443 mở ra ngoài; các cổng service đóng |
| Tên miền và HTTPS | Truy cập được bằng `https://` với chứng chỉ hợp lệ, không cảnh báo |
| Prometheus | Trang Targets hiện đủ bốn service ở trạng thái `UP` |
| Grafana | Dashboard riêng của nhóm, tối thiểu sáu biểu đồ |

**Mốc nộp 3:** liên kết HTTPS công khai, ảnh trang Targets, ảnh dashboard.

## Ngày 4 — Log tập trung và điều tra

| Việc | Kết quả phải có |
|---|---|
| Log JSON chuẩn ECS | Mỗi dòng log có `service.name`, `log.level`, `trace.id` |
| Mã truy vết xuyên service | Một request để lại log ở cả bốn service với cùng một `trace.id` |
| EFK | Kibana có data view, lọc được theo `trace.id` |
| Báo cáo sự cố | Dựng sự cố thật, điều tra theo sáu bước, viết báo cáo |

**Mốc nộp 4:** toàn bộ sản phẩm ở mục 6.

---

# 6. Danh mục sản phẩm phải nộp

## 6.1 · Kho mã nguồn

Một repository GitHub, mời tài khoản giảng viên với quyền đọc. Cấu trúc bắt buộc xem Phụ lục A.

Lịch sử commit phải **trải đều bốn ngày**. Một repository chỉ có một hoặc hai commit dồn vào ngày cuối sẽ bị trừ 15 điểm, kể cả khi sản phẩm chạy đúng.

## 6.2 · Địa chỉ công khai

Một liên kết `https://` còn sống tại thời điểm chấm, trỏ tới gateway của nhóm.

## 6.3 · Sơ đồ kiến trúc

Một hình vẽ thể hiện: năm thành phần ứng dụng, database, Nginx, cụm giám sát, cụm log, và **hai đường mạng khác nhau** — đường từ tiến trình Docker vào collector log, và đường giữa các container trong mạng nội bộ. Vẽ bằng công cụ nào cũng được, nhưng phải nhìn ra chiều đi của dữ liệu.

## 6.4 · Dashboard giám sát

Tối thiểu sáu biểu đồ, mỗi biểu đồ kèm một câu giải thích biểu đồ đó trả lời câu hỏi vận hành nào. Bắt buộc có ít nhất:

- Một biểu đồ dùng số đo loại đếm luỹ kế
- Một biểu đồ dùng số đo loại đo tức thời
- Một biểu đồ về độ trễ dựa trên số đo phân phối
- Một biểu đồ về tài nguyên máy chủ

## 6.5 · Bằng chứng truy vết

Ba ảnh chụp từ Kibana:

1. Kết quả lọc theo mức nghiêm trọng, thấy dòng cảnh báo của sự cố
2. Một document mở rộng, thấy rõ các trường `service.name`, `trace.id`, `error.type`
3. Kết quả lọc theo `trace.id`, thấy đủ chuỗi log của bốn service, sắp xếp từ cũ đến mới

## 6.6 · Báo cáo sự cố

Một trang, viết theo đúng sáu mục sau:

| Mục | Nội dung |
|---|---|
| Hiện tượng | Người dùng nhìn thấy gì |
| Mã truy vết | Giá trị `trace.id` dùng để điều tra |
| Dòng thời gian | Bảng các mốc, đơn vị mili giây, ghi rõ service nào ghi dòng nào |
| Nguyên nhân gốc | Dòng log đầu tiên bất thường, kèm lý do |
| Hậu quả kéo theo | Những dòng log sinh ra sau đó và quan hệ nhân quả |
| Kết luận | Phân loại sự cố: nghiệp vụ có kiểm soát hay hỏng hóc hạ tầng |

Báo cáo phải chỉ ra được khoảng cách thời gian giữa nguyên nhân gốc và dòng lỗi gây chú ý nhất. Báo cáo kết luận sai nguyên nhân — chỉ vào service ném ngoại lệ thay vì service từ chối — mất một nửa số điểm của mục này.

## 6.7 · Video demo

Từ bảy đến mười phút, quay màn hình, có tiếng. Thứ tự bắt buộc:

1. Mở địa chỉ HTTPS, đặt một đơn thành công
2. Bật điều kiện từ chối, đặt một đơn bị huỷ
3. Mở Grafana, chỉ ra biểu đồ phản ứng với lưu lượng vừa tạo
4. Mở Kibana, lọc theo `trace.id` của đơn vừa bị huỷ, đọc ra nguyên nhân
5. Sửa một dòng chữ bất kỳ trong mã nguồn, đẩy lên, cho xem CI chạy

Bước 5 là bắt buộc: nó chứng minh pipeline còn sống chứ không phải chạy một lần rồi thôi.

## 6.8 · Tệp README

Phải có: cách dựng trên máy cá nhân bằng một lệnh, danh sách biến môi trường, địa chỉ công khai, và bảng phân công công việc ghi rõ từng thành viên làm hạng mục nào.

---

# 7. Thang điểm

| Hạng mục | Điểm | Căn cứ chấm |
|---|---|---|
| Đóng gói và Compose | 10 | Dựng lại từ repo sạch bằng một lệnh, chạy được |
| Kiến trúc microservice | 15 | Bốn database tách biệt, một cổng vào, luồng sáu bước thông |
| Pipeline CI | 15 | Có bước kiểm thử, chạy xanh, tag image theo commit |
| Triển khai máy chủ | 10 | Image kéo từ registry, SSH đã khoá, không build trên máy chủ |
| Nginx và HTTPS | 10 | Chứng chỉ hợp lệ, cổng service không lộ ra ngoài |
| Giám sát | 15 | Bốn target `UP`, sáu biểu đồ có giải thích |
| Log tập trung và truy vết | 15 | Chuỗi log bốn service cùng một mã, báo cáo sự cố đúng nguyên nhân |
| Báo cáo, video, README | 10 | Đủ thành phần, trình bày rõ |
| **Tổng** | **100** | |

**Điểm cộng, tối đa 10:** cảnh báo tự động khi tỉ lệ lỗi vượt ngưỡng; chính sách tự xoá index log cũ; kiểm tra sức khoẻ và tự khởi động lại service hỏng; sao lưu database theo lịch; triển khai không gián đoạn.

---

# 8. Điều kiện cần

Ba điều kiện dưới đây không có điểm riêng, nhưng thiếu một trong ba thì đồ án **không được chấm**:

1. Địa chỉ HTTPS công khai còn sống tại thời điểm chấm
2. Lọc được một `trace.id` ra đủ log của tối thiểu ba service khác nhau
3. Mỗi thành viên trong nhóm có commit mang tên mình trong lịch sử

---

# 9. Yêu cầu hạ tầng và cách xoay xở khi máy yếu

## 9.1 · Cấu hình tối thiểu

| Nơi chạy | Cấu hình tối thiểu | Ghi chú |
|---|---|---|
| Máy cá nhân | 8 GB RAM, cấp cho Docker tối thiểu 6 GB | Dưới mức này không chạy đồng thời cả ứng dụng, giám sát và log |
| Máy chủ công khai | 2 vCPU, 4 GB RAM, 30 GB đĩa | Dưới 4 GB thì Elasticsearch bị hệ điều hành hạ sát |

## 9.2 · Ba cách tiết kiệm bộ nhớ, được phép dùng

Không phải nhóm nào cũng có máy mạnh. Ba cách sau được chấp nhận và không bị trừ điểm, miễn là demo đầy đủ:

**Hạ bộ nhớ của Elasticsearch.** Đặt `ES_JAVA_OPTS: "-Xms512m -Xmx512m"` trong file Compose của cụm log. Hệ thống chạy chậm hơn nhưng đủ cho khối lượng của đồ án.

**Giới hạn bộ nhớ của Kibana.** Thêm biến `NODE_OPTIONS: "--max-old-space-size=768"` vào service Kibana.

**Chạy luân phiên hai cụm.** Cụm giám sát và cụm log không bắt buộc chạy cùng lúc. Có thể tắt cụm log khi làm phần Grafana và ngược lại. Riêng lúc quay video demo thì cả hai phải cùng sống.

## 9.3 · Dấu hiệu máy hết bộ nhớ

Container hiện trạng thái `Restarting (137)`, hoặc lệnh kiểm tra trả về `oom=true`. Khi đó phải xử lý theo mục 9.2 trước khi làm tiếp, vì mọi lỗi phía sau đều là hệ quả.

```bash
docker inspect <ten-container> --format 'status={{.State.Status}} exit={{.State.ExitCode}} oom={{.State.OOMKilled}} restarts={{.RestartCount}}'
```

---

# 10. Quy định

## 10.1 · Được phép tái sử dụng

Sinh viên **được phép** tham khảo và tái sử dụng các mẫu cấu hình đã dùng trong các buổi lab: cấu trúc file Compose, cấu trúc workflow, cấu hình Nginx, cấu hình Prometheus, cấu hình collector log. Đây là những mẫu chuẩn, viết lại từ đầu không mang lại giá trị học tập.

Sinh viên **không được phép** nộp lại nguyên dự án của buổi lab với tên gọi khác. Mã nghiệp vụ, tên service, tên database, tên bảng và nội dung log phải thuộc về lĩnh vực đã được gán ở mục 4.

## 10.2 · Vấn đáp

Mỗi nhóm có mười phút vấn đáp. Giảng viên chọn ngẫu nhiên ba câu từ ngân hàng câu hỏi ở mục 11 và chỉ định **một thành viên bất kỳ** trả lời. Điểm vấn đáp áp dụng cho cả nhóm.

## 10.3 · Nhóm hai người

Nhóm hai người được bỏ hạng mục điểm cộng và được giảm số biểu đồ bắt buộc từ sáu xuống bốn. Các hạng mục còn lại giữ nguyên.

---

# 11. Ngân hàng câu hỏi vấn đáp

| # | Câu hỏi |
|---|---|
| 1 | Vì sao địa chỉ gửi log của logging driver phải là địa chỉ IP chứ không phải tên service, trong khi collector lại gọi kho log bằng tên? |
| 2 | Sửa khai báo logging trong file Compose rồi khởi động lại container có tác dụng không? Giải thích theo vòng đời container. |
| 3 | Cụm kho log báo màu vàng. Đó là lỗi hay không? Dựa vào đâu để kết luận? |
| 4 | Trong chuỗi log của sự cố, dòng nào là nguyên nhân gốc? Vì sao không phải dòng có ngoại lệ? |
| 5 | Vì sao phải xoá dữ liệu truy vết khỏi bộ nhớ của luồng sau khi xử lý xong request? |
| 6 | Image được gắn tag theo commit. Nêu một tình huống vận hành mà cách đặt tag này cứu được hệ thống. |
| 7 | Vì sao không build image trực tiếp trên máy chủ công khai? |
| 8 | Cổng của service có còn mở ra Internet sau khi đặt Nginx phía trước không? Chứng minh bằng một lệnh. |
| 9 | Phân biệt số đo loại đếm luỹ kế và loại đo tức thời. Mỗi loại cho một ví dụ trong hệ thống của nhóm. |
| 10 | Biểu đồ giám sát báo mọi thứ bình thường nhưng khách hàng vẫn mất tiền. Giải thích vì sao điều đó xảy ra được, và công cụ nào phát hiện ra. |

---

# Phụ lục A — Cấu trúc repository bắt buộc

```
minimart/
├─ .github/workflows/ci.yml
├─ services/
│  ├─ gateway/            Dockerfile + mã nguồn
│  ├─ catalog-service/
│  ├─ customer-service/
│  ├─ order-service/
│  └─ shipping-service/
├─ deploy/
│  ├─ docker-compose.yml          dựng trên máy cá nhân
│  ├─ docker-compose.prod.yml     dựng trên máy chủ, kéo image từ registry
│  ├─ logging.yml                 file chồng khai báo driver log
│  └─ nginx/
├─ observability/
│  ├─ monitoring/        cấu hình Prometheus và Grafana
│  └─ logging/           cấu hình cụm log và collector
├─ docs/
│  ├─ kien-truc.png
│  ├─ bao-cao-su-co.md
│  └─ anh-chup/
└─ README.md
```

---

# Phụ lục B — Bảng tự kiểm trước khi nộp

| # | Nội dung kiểm | Đạt |
|---|---|---|
| 1 | Nhân bản repo về thư mục trống, chạy một lệnh, hệ thống lên đủ container | |
| 2 | Truy vấn chéo database bị từ chối quyền | |
| 3 | Đặt đơn thành công trả về `CONFIRMED` | |
| 4 | Bật điều kiện từ chối, đặt đơn trả về `CANCELLED`, số dư ví trở lại như cũ | |
| 5 | Trang Actions của lần đẩy mã gần nhất báo xanh | |
| 6 | Registry có bốn image, tag trùng bảy ký tự đầu của commit mới nhất | |
| 7 | Mở `https://` không có cảnh báo chứng chỉ | |
| 8 | Quét cổng từ máy khác: chỉ thấy 80 và 443 | |
| 9 | Trang Targets của Prometheus: bốn service `UP` | |
| 10 | Dashboard mở được bằng liên kết, không cần đăng nhập quản trị | |
| 11 | Kibana lọc theo `trace.id` ra log của tối thiểu ba service | |
| 12 | Báo cáo sự cố chỉ đúng service gây ra, kèm khoảng cách thời gian | |
| 13 | README có bảng phân công từng thành viên | |
| 14 | Mỗi thành viên có commit mang tên mình | |
| 15 | Video demo đủ năm bước, có bước đẩy mã và xem CI chạy | |
