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

1.3 Một số câu lệnh git cơ bản:
- git clone repository_link => Kéo src từ git-server(github or gitlab ,....)
- git init: Khởi tạo (khai báo 1 local repository trên máy của chúng ta)
- git status : Kiểm tra trạng thái thay đổi của tất cả các file or folder trong src
- git add . : chấp thuận tất các các sự thay đổi của các file trong src => sẵn sàng commmit
- git add file_name: Chấp thuận duy nhất file_name thay đổi => ss commit 
- git push: Sau khi commit => Push code từ repo local to repo server
- git merge: Thưởng ít dùng => dùng để merger code giữa 2 nhánh khác nhau
- git pull origin branch_name: Lấy code mới nhất từ branch_name repo server về repo local
- git checkout + branch_name: => Chuyển đổi(di chuyển giữa các nhánh trong repo) sang nhánh branch_name
- git checkout -b new_branch_name : Tạo 1 nhánh mới có tên là new_branch_name
# 2. Tổng quan về Github Action & Kiến trúc runner

# 3. Cấu trúc workflow CI/CD cơ bản