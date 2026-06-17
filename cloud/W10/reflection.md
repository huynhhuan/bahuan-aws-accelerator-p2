# Reflection - W10 Day A

## Những gì đã học

- Phân biệt Role và ClusterRole, RoleBinding và ClusterRoleBinding
- Tạo ServiceAccount và cấu hình phân quyền
- Debug và kiểm tra quyền bằng lệnh `kubectl auth can-i`
- Khái niệm Admission Policy trong Kubernetes
- Cú pháp Rego cơ bản của OPA (Open Policy Agent)
- Hoạt động của OPA Gatekeeper (ConstraintTemplate và Constraint)
- Chế độ thực thi chính sách Audit vs Enforce
- Kubernetes native ValidatingAdmissionPolicy (VAP) và so sánh với Gatekeeper

## Điều tâm đắc

- ValidatingAdmissionPolicy (K8s 1.30+) giúp cấu hình chính sách kiểm soát đầu vào trực tiếp bằng CEL rất nhanh và nhẹ mà không cần dựng thêm webhook server bên ngoài.
- `kubectl auth can-i --as` rất hữu dụng để giả lập và kiểm tra quyền của các User/ServiceAccount khác nhau mà không cần cấu hình kubeconfig phức tạp.

## Điều cần tìm hiểu thêm

- Viết các luật Rego nâng cao hơn cho OPA Gatekeeper
- Tích hợp thêm các bộ lọc trong ValidatingAdmissionPolicy

## Kế hoạch tiếp theo

- Tìm hiểu về External Secrets Operator (ESO)
- Tìm hiểu về quản lý bí mật trên Kubernetes

---

# Reflection - W10 Day B

## Những gì đã học

- Khái niệm và vòng đời quản lý Secrets trên Kubernetes
- So sánh External Secrets Operator (ESO) và Sealed Secrets
- Cấu hình SecretStore (kết nối AWS Secrets Manager qua IRSA) và ExternalSecret
- Xoay vòng secrets (Secrets Rotation) tự động dưới 60 giây không cần restart Pod
- So sánh cập nhật Secret qua Env Vars vs Volume Mounts
- Quét lỗ hổng bảo mật container image bằng Trivy trong CI pipeline
- Ký ảnh container bằng Cosign (Key-based và Keyless với Sigstore)
- Xác thực chữ ký ảnh bằng Kyverno Admission Webhook ClusterPolicy
- Xử lý ngoại lệ CVE qua ADR và cấu hình `.trivyignore` có thời hạn

## Điều tâm đắc

- Sử dụng ESO giúp đồng bộ Secrets trực tiếp từ cloud Secrets Manager, tăng tính an toàn và dễ dàng tự động hóa xoay vòng secrets (Secrets Rotation) mà không cần restart lại Pod/Container bằng cách dùng Volume Mount.

## Điều cần tìm hiểu thêm

- Triển khai Cosign Keyless thực tế sử dụng OIDC trên AWS EKS
- Các cấu hình rule Kyverno nâng cao để kiểm soát ảnh container

## Kế hoạch tiếp theo

- Chuẩn bị cho Day C: tích hợp hệ thống, ResourceQuotas, Chaos Engineering và SRE Playbooks

---

# Reflection - W10 Day C

## Những gì đã học

- Tích hợp toàn bộ hệ thống từ W8 đến W10 (GitOps, Observability, Canary, Secrets, Security Policies)
- Phân hoạch tài nguyên cụm sử dụng ResourceQuota (cho namespace) và LimitRange (cho container)
- Khái niệm Chaos Engineering và các công cụ trên Kubernetes (LitmusChaos, Chaos Mesh)
- Quy trình 6 bước ứng phó sự cố SRE (Incident Response Playbook)
- Thiết lập SRE Runbook mẫu khắc phục sự cố CrashLoopBackOff do lỗi ESO Secrets Sync
- Tối ưu hóa chi phí đám mây với AWS Cost Anomaly Detection và Budget Alerts
- Thiết lập Terraform IaC cho AWS Cost Anomaly Monitor & Subscription

## Điều tâm đắc

- ResourceQuota và LimitRange giúp tránh lỗi lãng phí tài nguyên và hiện tượng Noisy Neighbor giữa các ứng dụng trên cùng một cụm.
- Có sẵn SRE Runbook giúp khống chế và khắc phục sự cố hệ thống nhanh chóng và chính xác khi xảy ra lỗi đột xuất.

## Điều cần tìm hiểu thêm

- Thực hành Chaos Mesh trực tiếp để kiểm thử khả năng chịu lỗi của cụm
- Cấu hình budget phức tạp hơn trên AWS qua Terraform