# GitOps

## GitOps là gì?

GitOps là phương pháp quản lý hạ tầng và ứng dụng bằng Git.

Git Repository đóng vai trò là nguồn sự thật duy nhất (Single Source of Truth).

Thay vì SSH vào server hoặc cluster để triển khai thủ công, mọi thay đổi đều được thực hiện thông qua:

- Commit
- Pull Request
- Merge

Sau khi mã nguồn thay đổi, công cụ GitOps sẽ tự động đồng bộ trạng thái từ Git xuống môi trường thực tế.

## Quy trình GitOps

Developer
↓
Git Commit
↓
Pull Request
↓
Merge
↓
Git Repository
↓
ArgoCD / Flux
↓
Kubernetes Cluster

## Lợi ích

- Có lịch sử thay đổi rõ ràng
- Dễ audit
- Dễ rollback
- Hạn chế thao tác thủ công
- Giảm lỗi do con người

## Công cụ phổ biến

- ArgoCD
- FluxCD