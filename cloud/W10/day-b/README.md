# W10 - Day B: Secrets Rotation & Supply Chain Security

## Nội dung học

- Quản lý Secrets trên Kubernetes và so sánh ESO vs Sealed Secrets
- Cấu hình SecretStore (IRSA) và ExternalSecret
- Cơ chế Secrets Rotation tự động dưới 60 giây không cần restart Pod
- Cập nhật Secret qua Env Vars vs Volume Mounts
- Quét lỗ hổng container image bằng Trivy trong CI pipeline
- Ký ảnh container bằng Cosign (Key-based và Keyless với Sigstore)
- Xác thực chữ ký ảnh bằng Kyverno Admission Webhook ClusterPolicy
- Xử lý ngoại lệ CVE qua ADR và `.trivyignore` có thời hạn

## Mục tiêu

Hiểu cách quản lý Secrets động bằng External Secrets Operator (ESO) và thiết lập bảo mật chuỗi cung ứng container từ quá trình build (Trivy), ký số (Cosign) cho đến xác thực khi deploy (Kyverno).

## Kết quả

- Phân biệt Pull-based (ESO) vs Push-based (Sealed Secrets)
- Cấu hình thành thạo ESO để kéo Secrets từ AWS Secrets Manager và xoay vòng tự động
- Tích hợp Trivy để chặn build trong CI pipeline khi có lỗ hổng HIGH/CRITICAL
- Ký ảnh container bằng Cosign và cấu hình Kyverno để chỉ cho phép deploy ảnh đã ký
- Biết cách thiết lập chính sách ngoại lệ đối với CVE
