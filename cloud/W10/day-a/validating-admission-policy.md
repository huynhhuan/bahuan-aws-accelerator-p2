# ValidatingAdmissionPolicy (VAP): Chính sách Admission Native trong Kubernetes

## 1. Giới thiệu về ValidatingAdmissionPolicy

Từ Kubernetes phiên bản v1.30, **ValidatingAdmissionPolicy (VAP)** đã chính thức đạt trạng thái General Availability (GA). Đây là một tính năng kiểm soát truy cập tích hợp sẵn (native admission control) của Kubernetes API Server.

Trước khi có VAP, để triển khai bất kỳ chính sách kiểm tra tài nguyên động nào (ví dụ: đảm bảo các container không chạy dưới quyền root, bắt buộc phải có nhãn nhất định), quản trị viên bắt buộc phải sử dụng các công cụ bên thứ ba như OPA Gatekeeper hoặc Kyverno. Các công cụ này hoạt động bằng cách gọi các webhook bên ngoài (Validating Webhooks), làm phát sinh độ trễ mạng, tăng chi phí vận hành và tăng rủi ro lỗi hệ thống nếu webhook bị sập.

**ValidatingAdmissionPolicy** giải quyết triệt để vấn đề này bằng cách cho phép định nghĩa các chính sách kiểm tra trực tiếp trong Kubernetes thông qua tài nguyên khai báo và ngôn ngữ biểu thức **CEL (Common Expression Language)**.

---

## 2. Ngôn ngữ Biểu thức CEL (Common Expression Language)

### 2.1. CEL là gì?
**Common Expression Language (CEL)** là một ngôn ngữ biểu thức phi Turing (non-Turing-complete) được Google phát triển. Nó được thiết kế đặc biệt để an toàn, nhanh chóng và nhẹ, lý tưởng cho việc nhúng vào các ứng dụng cần tính toán nhanh các điều kiện luận lý mà không sợ rủi ro bị lặp vô hạn hay tiêu hao quá nhiều tài nguyên CPU.

### 2.2. Các biến ngữ cảnh trong Kubernetes CEL
Khi viết các quy tắc (validation rules) bằng CEL trong Kubernetes, bạn có quyền truy cập vào các biến đặc biệt cung cấp thông tin về tài nguyên đang được yêu cầu:
*   `object`: Tài nguyên mới đang được gửi lên để tạo hoặc cập nhật (dạng JSON/YAML).
*   `oldObject`: Tài nguyên cũ trước khi cập nhật (chỉ có khi thực hiện hành động UPDATE).
*   `request`: Chứa siêu dữ liệu về yêu cầu (ví dụ: `request.operation` có thể là `CREATE`, `UPDATE`, `DELETE`; `request.userInfo` chứa thông tin người dùng gửi yêu cầu).
*   `params`: Các thông số cấu hình bổ sung được truyền từ đối tượng binding.

### 2.3. Cú pháp CEL cơ bản và cách viết quy tắc
Biểu thức CEL trong trường `expression` của chính sách phải trả về một giá trị **Boolean** (`true` hoặc `false`):
*   Nếu biểu thức trả về `true`: Tài nguyên hợp lệ và được chấp nhận (PASS).
*   Nếu biểu thức trả về `false`: Tài nguyên vi phạm chính sách và yêu cầu bị từ chối (FAIL).

> [!IMPORTANT]
> **Khuyến nghị bảo mật và phòng tránh lỗi runtime với hàm `has()`:**
> Trong CEL, nếu bạn truy cập trực tiếp một trường không bắt buộc (optional field) nhưng trường đó không tồn tại trong tài nguyên được gửi lên (ví dụ: trường `replicas` bị bỏ trống để nhận giá trị mặc định là 1), biểu thức CEL sẽ gặp lỗi runtime (evaluation error) và dẫn đến từ chối yêu cầu (hoặc tùy thuộc vào cấu hình `failurePolicy`).
> Vì vậy, luôn khuyến nghị sử dụng hàm `has(tên_trường)` để kiểm tra sự tồn tại của trường trước khi đánh giá giá trị của nó.
> *Ví dụ:* `!has(object.spec.replicas) || (object.spec.replicas >= 1 && object.spec.replicas <= 5)` (nếu không khai báo `replicas` thì bỏ qua/PASS, nếu có khai báo thì giá trị phải nằm trong khoảng từ 1 đến 5).

*Ví dụ cú pháp CEL phổ biến:*
*   Kiểm tra sự tồn tại của trường: `has(object.metadata.labels)`
*   Kiểm tra giá trị cụ thể: `object.metadata.name.startsWith('prod-')`
*   Duyệt danh sách và kiểm tra điều kiện: `object.spec.containers.all(c, c.image.endsWith(':latest') == false)` (Tất cả container không được dùng tag latest)
*   Toán tử logic: `&&` (AND), `||` (OR), `!` (NOT).

---

## 3. Ví dụ cấu hình YAML Manifest

Kịch bản dưới đây định nghĩa một chính sách giới hạn số lượng replica của các tài nguyên `Deployment` chỉ được phép nằm trong khoảng từ 1 đến 5.

### 3.1. Khai báo ValidatingAdmissionPolicy (`policy.yaml`)
Tài nguyên này mô tả logic kiểm tra bằng CEL.

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: deployment-replica-limit
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups: ["apps"]
      apiVersions: ["v1"]
      operations: ["CREATE", "UPDATE"]
      resources: ["deployments"]
  validations:
    - expression: "!has(object.spec.replicas) || (object.spec.replicas >= 1 && object.spec.replicas <= 5)"
      message: "Số lượng replica của Deployment phải nằm trong khoảng từ 1 đến 5."
```

### 3.2. Khai báo ValidatingAdmissionPolicyBinding (`binding.yaml`)
Tài nguyên này kích hoạt chính sách ở trên và xác định phạm vi áp dụng. Trong ví dụ này, chúng ta áp dụng chính sách trên toàn bộ Cluster nhưng loại trừ các Namespace có nhãn `admission-policy=exempt`.

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: deployment-replica-limit-binding
spec:
  policyName: deployment-replica-limit
  validationActions: [Deny]
  matchResources:
    namespaceSelector:
      matchExpressions:
      - key: admission-policy
        operator: NotIn
        values: ["exempt"]
```

---

## 4. So sánh: OPA Gatekeeper vs Native ValidatingAdmissionPolicy (VAP)

Bảng so sánh dưới đây giúp các kỹ sư DevOps/SRE lựa chọn công cụ phù hợp với hạ tầng của mình:

| Tiêu chí | OPA Gatekeeper | Native ValidatingAdmissionPolicy (VAP) |
| :--- | :--- | :--- |
| **Kiến trúc (Architecture)** | Sử dụng Webhook Controller bên ngoài. API Server gọi webhook qua mạng HTTPS. | Tích hợp hoàn toàn bên trong Kubernetes API Server (Native Engine). |
| **Ngôn ngữ viết chính sách** | **Rego**: Ngôn ngữ truy vấn mạnh mẽ, hỗ trợ các cấu trúc logic phức tạp và xử lý dữ liệu lớn. | **CEL (Common Expression Language)**: Ngôn ngữ biểu thức nhẹ, nhanh và an toàn. |
| **Hiệu năng (Performance)** | Có độ trễ mạng do gọi Webhook. Có nguy cơ quá tải bộ nhớ/CPU của webhook pod. | Không có độ trễ mạng. Tốc độ thực thi cực nhanh nhờ được biên dịch trực tiếp trên API Server. |
| **Chi phí vận hành (CRD Overhead)** | Cao. Cần cài đặt Gatekeeper (Helm chart), giám sát các Pods, cấu hình chứng chỉ TLS cho webhook. | Thấp. Không cần cài đặt bất kỳ thành phần nào khác. Chỉ cần khai báo 2 tài nguyên native của K8s. |
| **Độ tin cậy (Reliability)** | Nếu webhook controller bị sập và cấu hình `failurePolicy: Fail`, toàn bộ cluster có thể bị chặn tạo tài nguyên. | Rất cao. Nằm trong nhân của API Server, không sợ lỗi kết nối mạng nội bộ hay chứng chỉ TLS hết hạn. |
| **Hỗ trợ truy vấn bên ngoài (External Data)** | Rất tốt. Có thể cache dữ liệu cluster hoặc gọi API bên ngoài để kiểm tra tính hợp lệ. | Không hỗ trợ. Chỉ có thể validate dựa trên nội dung của chính tài nguyên đang gửi lên (`object`, `oldObject`). |
| **Khả năng Mutate (Thay đổi tài nguyên)** | Hỗ trợ tốt thông qua các tài nguyên Mutator của Gatekeeper. | Không hỗ trợ (Chỉ dùng cho việc Validate). |
| **Độ chín muồi & Cộng đồng** | Lâu đời, kho chính sách mẫu (policy library) cực kỳ phong phú và đa dạng. | Mới đạt GA từ bản 1.30, thư viện chính sách mẫu đang tiếp tục phát triển. |

---

## 5. Kết luận hướng dẫn thực hành
*   Sử dụng **ValidatingAdmissionPolicy** cho các trường hợp kiểm tra tính hợp lệ cơ bản của tài nguyên (nhãn, giới hạn số lượng, cấu hình bảo mật container...) để tận dụng tối đa hiệu năng và độ ổn định của hệ thống.
*   Sử dụng **OPA Gatekeeper** (hoặc Kyverno) khi hệ thống yêu cầu các chính sách phức tạp cần so sánh chéo thông tin giữa các tài nguyên khác nhau (ví dụ: kiểm tra xem Ingress Host có bị trùng lặp trong Cluster hay không), cần gọi dữ liệu bên ngoài, hoặc cần tự động sửa đổi (Mutation) tài nguyên.
