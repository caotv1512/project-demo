## CI/CD vs Github Action
# 1. Git flow:
1.1 Branch name:
- main/ master => Những nhánh default (hoặc 1 số dự án lấy làm nhánh production) => Nhánh này không được phép sai xót
- develop => Nhánh phát triển của team dev => Nhánh này có thể còn sai xót hoặc bug

=================================
### VD: có domain prodution(release) là : api.rikkei.eduvn 
- staging => api.staging.rikkei.eduvn
- uat => api.uat.rikkei.eduvn
- release => 1 số dự án thực thế sẽ dùng tên này thay cho main or master
- uat: Môi trường test cấp cuối cùng để đẩy lên release : team test đại diện phía khách hàng
- staging: = develop Pass test case đợt 1: => đẩy lên uat
- feature/#_Task_ID
- VD: feature/#MANKAI-3412
1.2 Role in repo
- Developer => Những ông phát triển sản phẩm (dev) có thể tạo nhánh mới và tạo MR(merge request)
- Mantainer => (Những ông kiểm duyệt các MR, và có quyền merger hoặc review code)
- Guest => Vào xem repo (không có quyền clone code về)

# 2. Tổng quan về Github Action & Kiến trúc runner

# 3. Cấu trúc workflow CI/CD cơ bản