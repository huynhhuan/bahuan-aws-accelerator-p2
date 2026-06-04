# W8 Day 2 - K8s Self-study Notes

## Container

- Đóng gói app và dependency.
- Chạy từ image.
- Tạo môi trường chạy nhất quán.
- Phù hợp để đóng gói service nhỏ.
- Chưa đủ để tự quản lý:
  - restart;
  - scaling;
  - rollout;
  - service discovery;
  - traffic routing.

## Orchestration

- Quản lý vòng đời container.
- Chạy nhiều replica.
- Tự restart khi container lỗi.
- Phân phối workload lên node.
- Expose service bằng endpoint ổn định.
- Rollout version mới.
- Rollback khi release lỗi.
- Quản lý config/secret.
- Kiểm soát traffic giữa service.

## Kubernetes cluster

- Control plane:
  - quản lý trạng thái cluster;
  - xử lý API request;
  - điều phối scheduling;
  - chạy controller.
- Worker node:
  - chạy Pod;
  - chạy kubelet;
  - chạy container runtime.
- API server:
  - entrypoint chính của Kubernetes;
  - nhận request từ `kubectl`;
  - nhận request từ controller.
- Scheduler:
  - chọn node phù hợp cho Pod.
- kubelet:
  - chạy trên node;
  - đảm bảo Pod được chạy đúng.
- Controller:
  - theo dõi desired state;
  - reconcile actual state.

## Pod

- Đơn vị nhỏ nhất Kubernetes schedule.
- Chứa một hoặc nhiều container.
- Có IP riêng.
- Có lifecycle ngắn.
- Có thể bị xóa và tạo lại.
- IP không ổn định.
- Không nên hard-code Pod IP.
- Thường được quản lý qua Deployment.

## Deployment

- Quản lý replica của app.
- Tạo ReplicaSet.
- Đảm bảo số lượng Pod mong muốn.
- Tạo Pod mới khi Pod cũ chết.
- Hỗ trợ rollout.
- Hỗ trợ rollback.

## Service

- Endpoint ổn định để truy cập Pod.
- Route traffic tới Pod backend.
- Chọn Pod bằng label selector.
- Không chạy app.
- Không thay thế Deployment.
- Loại Service:
  - `ClusterIP`: truy cập nội bộ cluster;
  - `NodePort`: mở port trên node;
  - `LoadBalancer`: dùng cloud load balancer.
- Ghi nhớ:
  - Pod IP thay đổi;
  - Service endpoint ổn định hơn;
  - client nên truy cập qua Service.

## Probes

- `readinessProbe`:
  - kiểm tra app sẵn sàng nhận traffic;
  - fail thì Pod bị loại khỏi endpoint nhận traffic.
- `livenessProbe`:
  - kiểm tra container còn khỏe;
  - fail thì container có thể bị restart.
- `startupProbe`:
  - dùng cho app khởi động lâu;
  - tránh restart quá sớm trong giai đoạn start.

## ConfigMap

- Lưu cấu hình không nhạy cảm.
- Ví dụ:
  - app mode;
  - feature flag;
  - URL nội bộ;
  - cấu hình runtime.
- Cách dùng:
  - environment variables;
  - mounted files.

## Secret

- Lưu dữ liệu nhạy cảm hơn ConfigMap.
- Ví dụ:
  - password;
  - token;
  - API key.
- Không commit secret vào Git.
- Cần giới hạn quyền truy cập.
- Có thể dùng qua:
  - environment variables;
  - mounted files.

## NetworkPolicy

- Kiểm soát traffic giữa Pod/namespace.
- Giới hạn ingress traffic.
- Giới hạn egress traffic.
- Áp dụng theo label selector.
- Cần CNI hỗ trợ.
- Không phải cluster nào cũng enforce NetworkPolicy mặc định.