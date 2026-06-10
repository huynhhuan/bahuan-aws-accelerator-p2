# Sync Waves

## Mục đích

Kiểm soát thứ tự triển khai tài nguyên Kubernetes.

Ví dụ:

1. Namespace
2. ConfigMap
3. Secret
4. Deployment
5. Service
6. Ingress

## Tại sao cần?

Nếu Deployment được tạo trước ConfigMap hoặc Secret thì Pod có thể khởi động thất bại.

Sync Waves giúp đảm bảo tài nguyên được triển khai đúng thứ tự.

## Lợi ích

- Giảm lỗi khi deploy
- Kiểm soát dependency giữa các tài nguyên
- Hỗ trợ triển khai phức tạp