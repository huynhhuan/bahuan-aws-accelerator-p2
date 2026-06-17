# W10 - Day A: RBAC & Admission Policy

## Nội dung học

- Kubernetes RBAC (Role, ClusterRole, RoleBinding, ClusterRoleBinding, ServiceAccount)
- Lệnh `kubectl auth can-i` để kiểm tra phân quyền
- Admission Policy trong Kubernetes
- OPA Gatekeeper (ConstraintTemplate và Constraint, Rego basics, Audit vs Enforce)
- ValidatingAdmissionPolicy (K8s 1.30+, CEL expressions)

## Mục tiêu

Hiểu cách quản lý phân quyền đặc quyền tối thiểu (Least Privilege) trên cụm Kubernetes và cách thiết lập các chính sách kiểm soát đầu vào (Admission Controllers) để thắt chặt bảo mật.

## Kết quả

- Hiểu cách hoạt động và phân biệt Role/ClusterRole, RoleBinding/ClusterRoleBinding
- Sử dụng thành thạo `kubectl auth can-i` để debug phân quyền
- Hiểu kiến trúc OPA Gatekeeper và cách viết chính sách bằng Rego
- Hiểu cách hoạt động của ValidatingAdmissionPolicy gốc (native) và viết biểu thức CEL
- So sánh được OPA Gatekeeper và ValidatingAdmissionPolicy
