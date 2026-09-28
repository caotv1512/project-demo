# Nhánh gh-pages — Bảng trạng thái triển khai

Nhánh này **không chứa mã nguồn**. Nó chỉ chứa trang web hiển thị trạng thái
triển khai của 3 môi trường, phục vụ demo Session 07.

- `index.html` — trang bảng điều khiển, tự tải lại mỗi 15 giây
- `staging.json` · `uat.json` · `release.json` — do GitHub Actions ghi tự động

Workflow `04-deploy-3-moi-truong.yml` sẽ cập nhật đúng một file JSON
tương ứng với nhánh vừa được đẩy. **Không sửa tay các file JSON.**
