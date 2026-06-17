# Chaos Engineering Trên Kubernetes & SRE Incident Response Runbooks

## 1. Chaos Engineering Trên Kubernetes

### 1.1. Chaos Engineering là gì?
**Chaos Engineering (Kỹ nghệ hỗn loạn)** là bộ môn kiểm thử tính bền bỉ và độ tin cậy của hệ thống bằng cách chủ động tiêm các lỗi thực tế (failures) có kiểm soát vào môi trường (môi trường Staging giống Production hoặc trực tiếp trên Production) nhằm phát hiện ra các điểm yếu tiềm ẩn trước khi chúng gây ra sự cố thực tế.

Trong môi trường phân tán như Kubernetes, các sự cố như mất kết nối mạng giữa các pod, node bị quá tải dẫn đến eviction, hoặc API Server bị nghẽn xảy ra thường xuyên. Chaos Engineering giúp xác minh xem hạ tầng tự khắc phục (self-healing) và kiến trúc ứng dụng của bạn có hoạt động đúng như thiết kế hay không.

### 1.2. Quy trình Thực hiện Chaos Test (4 Bước Cốt Lõi)

```
+----------------------------+
| 1. Xác định Trạng thái     | <--- Đo lường KPIs (Latency, Error Rate, Pod Status)
|    Ổn định (Steady State)  |
+--------------+-------------+
               |
               v
+----------------------------+
| 2. Thiết lập Giả thuyết   | <--- "Nếu Pod A chết, HPA/ReplicaSet sẽ tạo Pod mới
|    (Formulate Hypothesis)  |      và Ingress tự chuyển traffic, downtime = 0s"
+--------------+-------------+
               |
               v
+----------------------------+
| 3. Tiêm lỗi Có kiểm soát   | <--- Sử dụng Chaos Mesh/Litmus để: Pod Kill,
|    (Inject Failure/Chaos)  |      Network Latency, Packet Loss, CPU Stress...
+--------------+-------------+
               |
               v
+----------------------------+
| 4. Phân tích & Rollback   | <--- Phân tích dashboard Prometheus/Grafana.
|    (Analyze & Contain)     |      Tự động dừng/rollback để giới hạn Blast Radius.
+----------------------------+
```

1.  **Xác định Trạng thái Ổn định (Define Steady State):** Đo lường các chỉ số vận hành bình thường của hệ thống. Đây là thước đo chuẩn (baseline) để so sánh khi có sự cố. Các chỉ số bao gồm: Tỷ lệ lỗi HTTP (HTTP Error Rate < 0.1%), độ trễ phản hồi (p99 latency < 200ms), số lượng replica mong muốn.
2.  **Thiết lập Giả thuyết (Formulate Hypothesis):** Đưa ra phán đoán về hành vi của hệ thống khi có lỗi.
    *   *Ví dụ giả thuyết:* "Nếu một Pod trong cụm Microservice bị tắt đột ngột (Pod Kill), Kubernetes ReplicaSet sẽ tự động tạo lại Pod mới trong vòng 10 giây và Ingress Controller sẽ dừng chuyển traffic vào Pod cũ ngay lập tức, đảm bảo người dùng không nhận lỗi 5xx."
3.  **Tiêm lỗi (Inject Failure):** Thực thi các bài test lỗi cụ thể trên Kubernetes:
    *   **Pod Kill (Tiêu diệt Pod):** Mô phỏng lỗi tiến trình bị crash, rò rỉ bộ nhớ dẫn đến Out-of-Memory (OOM) bị kernel kill.
    *   **Pod Network Latency (Trễ mạng):** Gây trễ gói tin (ví dụ: thêm 200ms latency giữa Pod API và Database) để kiểm tra timeout, retry logic và cơ chế Circuit Breaker.
    *   **Packet Loss (Mất gói tin):** Gây mất mát gói tin trên card mạng của Pod để xem ứng dụng xử lý các kết nối chập chờn như thế nào.
    *   **CPU/Memory Stress:** Bơm tải CPU/Memory của container lên 100% để kiểm tra tính năng Horizontal Pod Autoscaler (HPA) và cơ chế eviction của Node.
4.  **Phân tích Ảnh hưởng & Giới hạn Vùng ảnh hưởng (Rollback & Contain Blast Radius):**
    *   Theo dõi sát sao hệ thống giám sát (Grafana/Prometheus). Nếu các chỉ số vượt quá ngưỡng nguy hiểm cho phép (ví dụ tỷ lệ lỗi tăng vọt > 5% trên toàn hệ thống), phải lập tức thu hồi lỗi (Rollback).
    *   **Giới hạn vùng ảnh hưởng (Blast Radius):** Luôn giới hạn bài test chaos trong một phạm vi nhỏ trước (ví dụ: chỉ tiêm lỗi lên 1 Pod duy nhất, chỉ áp dụng trong namespace `staging` hoặc cho các Pod có label cụ thể) trước khi mở rộng quy mô.

### 1.3. Các Công cụ Chaos Engineering Phổ biến
*   **Chaos Mesh:** Công cụ Cloud-native được CNCF bảo trợ, tích hợp sâu vào Kubernetes thông qua các Custom Resource Definitions (CRDs). Cho phép định nghĩa các tài nguyên như `PodChaos`, `NetworkChaos`, `DNSChaos`, `KernelChaos` bằng file YAML. Chaos Mesh cung cấp một Dashboard GUI trực quan để lên lịch và quản lý lỗi.
*   **LitmusChaos:** Framework Chaos Engineering mã nguồn mở hướng tới doanh nghiệp. Litmus sử dụng kiến trúc phân tán với các thành phần như ChaosAgent, ChaosEngine và ChaosExperiment. Nó rất mạnh mẽ trong việc xây dựng các kịch bản chaos phức tạp (Chaos Workflows) và tích hợp trực tiếp vào pipelines CI/CD.

---

## 2. Quy trình 6 Bước Ứng Phó Sự Cố SRE (Incident Response - IR)

Khi xảy ra sự cố trong môi trường sản xuất (Production), đội ngũ SRE tuân thủ quy trình ứng phó 6 bước chuẩn để giảm thiểu tối đa thời gian gián đoạn dịch vụ (MTTR - Mean Time To Resolution):

```
 Detect (Phát hiện)
        │
        ▼
  Triage (Phân loại & Đánh giá)
        │
        ▼
Contain (Khống chế & Cách ly)  <--- Quan trọng nhất trong 5 phút đầu!
        │
        ▼
Eradicate (Triệt tiêu nguyên nhân)
        │
        ▼
 Recover (Khôi phục dịch vụ)
        │
        ▼
Post-mortem (Học hỏi & Rút kinh nghiệm)
```

### 2.1. Detect (Phát hiện)
*   **Mô tả:** Hệ thống giám sát (Prometheus/Alertmanager, Grafana Alert) phát hiện các bất thường (ví dụ: Pod CrashLoopBackOff liên tục, API Gateway trả về nhiều lỗi 502, latency tăng đột biến) và gửi cảnh báo về các kênh trực ban (Slack, PagerDuty, SMS).
*   **Kubernetes Context:** Alertmanager kích hoạt cảnh báo `KubePodCrashLooping` hoặc `KubeContainerWaiting` đối với các service trọng yếu.

### 2.2. Triage (Phân loại & Đánh giá)
*   **Mô tả:** Xác định mức độ ảnh hưởng thực tế (Severity) của sự cố (ví dụ: P1 - Hệ thống dừng hoạt động hoàn toàn, P2 - Ảnh hưởng một số tính năng chính, P3 - Lỗi nhỏ). Chỉ định **Incident Commander (IC)** để điều phối việc xử lý và mở kênh họp khẩn (Slack incident channel / Google Meet).
*   **Kubernetes Context:** Xác định xem lỗi xảy ra trên diện rộng (toàn bộ Node bị NotReady, cạn kiệt tài nguyên IP của VPC CNI) hay chỉ xảy ra cục bộ ở một vài Pod của một Microservice.

### 2.3. Contain (Khống chế & Cách ly)
*   **Mô tả:** Đây là bước quan trọng nhất nhằm **hạn chế vùng ảnh hưởng (Blast Radius)**. Mục tiêu là cô lập lỗi để hệ thống không bị sập dây chuyền và đảm bảo các phần khác của hệ thống vẫn phục vụ người dùng bình thường.
*   **Kubernetes Context:**
    *   *Cách ly Pod lỗi:* Thay đổi nhãn (Labels) của Pod đang bị lỗi để loại bỏ nó ra khỏi Endpoint của Service/Ingress, ngăn không cho traffic đi vào Pod này.
    *   *Cách ly Bảo mật:* Nếu phát hiện Pod bị xâm nhập, áp dụng `NetworkPolicy` để chặn toàn bộ kết nối ra/vào Pod đó, hoặc cô lập Node (Cordon node) để ngăn Pod mới deploy lên Node bị lỗi.
    *   *Điều hướng Traffic:* Điều chỉnh trọng số Ingress (Ingress Canary) để chuyển hướng 100% traffic của người dùng sang cụm Pod/Cluster dự phòng ổn định.

### 2.4. Eradicate (Triệt tiêu nguyên nhân)
*   **Mô tả:** Tìm ra nguyên nhân gốc rễ (Root Cause) của lỗi và tiến hành loại bỏ nó hoàn toàn khỏi hệ thống.
*   **Kubernetes Context:** Rollback phiên bản ứng dụng lỗi về bản stable gần nhất bằng ArgoCD/Helm; Cập nhật cấu hình ConfigMap/Secret bị thiếu; Tăng hạn mức giới hạn CPU/Memory nếu Pod bị OOMKilled; Sửa đổi IAM Role Policy bị thiếu quyền.

### 2.5. Recover (Khôi phục)
*   **Mô tả:** Đưa dịch vụ hoạt động bình thường trở lại và bàn giao quyền kiểm soát cho hệ thống tự động.
*   **Kubernetes Context:** Scale-up lại các Pod, đưa Pod vào lại Service Selector, hủy bỏ chế độ cô lập mạng. Theo dõi các biểu đồ metrics (Grafana) trong ít nhất 15-30 phút để đảm bảo các chỉ số hoàn toàn ổn định và lỗi không tái diễn.

### 2.6. Post-mortem (Học hỏi & Rút kinh nghiệm)
*   **Mô tả:** Tổ chức buổi họp rút kinh nghiệm không đổ lỗi (**Blameless Post-mortem**). Viết tài liệu ghi nhận: Dòng thời gian sự cố (Timeline), Nguyên nhân gốc rễ (Root Cause), Hành động khắc phục ngắn hạn và dài hạn (Action Items) kèm theo người chịu trách nhiệm và deadline cụ thể để tránh sự cố lặp lại.

---

## 3. Biểu mẫu SRE Runbook Thực tế

### Kịch bản Sự cố: Pod CrashLoopBackOff do lỗi đồng bộ Secrets qua External Secrets Operator (ESO)

---

### A. THÔNG TIN CẢNH BÁO (ALERT DETAILS)
*   **Tên Cảnh báo (Alert Name):** `KubePodCrashLooping` / `ESOSecretSyncFailed`
*   **Mức độ (Severity):** Critical (P1/P2 tùy thuộc vào độ quan trọng của microservice)
*   **Mô tả:** Pod liên tục khởi động lại và rơi vào trạng thái `CrashLoopBackOff` do không đọc được cấu hình Secrets cần thiết để khởi chạy ứng dụng (ví dụ: Database Password, API Keys). Nguyên nhân nghi ngờ do External Secrets Operator (ESO) thất bại khi đồng bộ dữ liệu từ AWS Secrets Manager.

---

### B. LỆNH XÁC MINH SỰ CỐ (VERIFICATION COMMANDS)

Thực hiện tuần tự các lệnh sau để xác định chính xác nguyên nhân lỗi:

1.  **Kiểm tra các Pod đang gặp lỗi:**
    ```bash
    kubectl get pods -n production | grep -E "CrashLoopBackOff|Error"
    ```
2.  **Xem logs của Pod bị crash ở lần chạy trước đó:**
    ```bash
    kubectl logs <pod-name> -n production --previous
    ```
    *Dấu hiệu nhận biết:* Logs hiển thị thông báo lỗi như: `Fatal: Database connection string is empty` hoặc `Missing API_KEY environment variable`.
3.  **Kiểm tra xem Kubernetes Secret nội bộ có tồn tại không:**
    ```bash
    kubectl get secret -n production | grep <target-secret-name>
    ```
    *Nếu Secret không tồn tại hoặc dữ liệu bên trong trống, chuyển sang kiểm tra ESO.*
4.  **Kiểm tra trạng thái tài nguyên ExternalSecret của ESO:**
    ```bash
    kubectl get externalsecret -n production
    ```
    *Kiểm tra cột STATUS. Nếu hiển thị trạng thái `SyncFailed` hoặc `SecretSyncedError`, thực hiện mô tả chi tiết:*
    ```bash
    kubectl describe externalsecret <externalsecret-name> -n production
    ```
    *Đọc kỹ phần `Events` ở cuối đầu ra để xem thông báo lỗi kết nối từ AWS Secrets Manager.*
5.  **Kiểm tra Logs của External Secrets Operator Controller:**
    ```bash
    kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets --tail=200
    ```
    *Dấu hiệu lỗi:* Lỗi `AccessDeniedException` hoặc `Forbidden` khi gọi API của AWS Secrets Manager, hoặc lỗi hết hạn kết nối (Timeout).

---

### C. KHỐNG CHẾ TẠM THỜI (IMMEDIATE CONTAINMENT)

Để tránh lỗi lây lan hoặc gây quá tải hệ thống logs/APIServer do Pod khởi động lại liên tục:
1.  **Scale down deployment bị lỗi về 0:**
    ```bash
    kubectl scale deployment/<deployment-name> -n production --replicas=0
    ```
    *Hành động này giúp giảm tải hệ thống và khóa trạng thái lỗi để tiến hành sửa đổi.*
2.  **Nếu ứng dụng dùng Argo Rollouts và đang trong quá trình Canary:**
    ```bash
    kubectl argo rollouts undo <rollout-name> -n production
    ```
    *Hủy quá trình rollout, đưa traffic hoàn toàn về phiên bản stable cũ.*

---

### D. CÁC BƯỚC KHẮC PHỤC (REMEDIATION STEPS)

#### Trường hợp 1: Lỗi Phân quyền IAM (IRSA - IAM Roles for Service Accounts)
Nếu mô tả ExternalSecret báo lỗi `AccessDenied` từ AWS:
1.  **Kiểm tra xem ServiceAccount của ESO có được gán IAM Role đúng không:**
    ```bash
    kubectl get serviceaccount external-secrets -n external-secrets -o yaml
    ```
    Xác minh annotation `eks.amazonaws.com/role-arn` xem có chính xác hay không.
2.  **Kiểm tra sự tồn tại và phân quyền của Secret trên AWS:**
    Chạy lệnh CLI bằng quyền AWS Admin để xác minh xem Secret ID có tồn tại và IAM Role của ESO có quyền đọc không:
    ```bash
    aws secretsmanager describe-secret --secret-id <aws-secret-id-or-name> --region <aws-region>
    ```
3.  **Cập nhật IAM Policy:** Nếu thiếu quyền `secretsmanager:GetSecretValue`, hãy cập nhật IAM Policy gắn với IAM Role tương ứng.

#### Trường hợp 2: Lỗi Sai tên Secret hoặc Sai Key trong AWS Secrets Manager
Nếu mô tả ExternalSecret báo lỗi `ResourceNotFoundException`:
1.  **So sánh cấu hình:** Đối chiếu khóa trong `spec.data` của `ExternalSecret` với các key thực tế được định nghĩa trên AWS Secrets Manager.
2.  **Sửa đổi manifest:** Chỉnh sửa file manifest `ExternalSecret` hoặc cập nhật đúng key trên AWS Console.
3.  **Ép buộc đồng bộ thủ công (Force Manual Sync):**
    Thêm annotation thay đổi thời gian để kích hoạt ESO đồng bộ ngay lập tức mà không cần đợi hết chu kỳ `refreshInterval`:
    ```bash
    kubectl annotate externalsecret <externalsecret-name> -n production force-sync=$(date +%s) --overwrite
    ```

#### Trường hợp 3: Khôi phục và Chạy lại Ứng dụng
1.  **Xác minh Secret nội bộ đã được tạo thành công:**
    ```bash
    kubectl get secret <target-secret-name> -n production -o jsonpath='{.data}'
    ```
2.  **Khôi phục số lượng replica của ứng dụng:**
    ```bash
    kubectl scale deployment/<deployment-name> -n production --replicas=3
    ```
3.  **Xác minh trạng thái Pod:**
    ```bash
    kubectl get pods -n production -w
    ```
    *Đảm bảo các Pod chuyển sang trạng thái `Running` và `Ready` ổn định.*

---

### E. PHÂN TÍCH NGUYÊN NHÂN GỐC RỄ (ROOT-CAUSE ANALYSIS)
Sau khi khắc phục sự cố, SRE cần phân tích sâu hơn:
*   **AWS Rate Limiting:** Có phải do tần suất gọi API từ ESO sang AWS Secrets Manager quá lớn dẫn đến bị Rate Limit? (Khắc phục: Tăng `refreshInterval` trong ExternalSecret lên 1h thay vì vài chục giây).
*   **Cơ chế xoay vòng Secret (Rotation):** Nếu Secret trên AWS Secrets Manager tự động xoay vòng (Rotate), tại sao Pod không tự nhận? Có phải ứng dụng không có cơ chế hot-reload secret? (Khắc phục: Cài đặt công cụ tự động reload Pod khi Secret thay đổi như *Reloader* của Stakater).
