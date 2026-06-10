# Rollback

## Rollback là gì?

Rollback là quá trình đưa hệ thống trở về phiên bản ổn định trước đó khi phát hiện lỗi.

## Cách 1: Git Revert

Tạo commit mới để hoàn tác commit lỗi.

Ưu điểm:

- Có lịch sử Git đầy đủ
- Đúng chuẩn GitOps

## Cách 2: Kubectl Rollout Undo

Khôi phục Deployment về phiên bản trước.

Ưu điểm:

- Nhanh

Nhược điểm:

- Không cập nhật Git

## Khuyến nghị

Trong GitOps nên ưu tiên Git Revert vì Git luôn là nguồn sự thật duy nhất.