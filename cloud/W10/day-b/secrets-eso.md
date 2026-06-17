# Quản lý Secrets Động trong Kubernetes với External Secrets Operator (ESO)

## 1. Vòng đời quản lý Secrets và Cơ chế hoạt động của ESO

### 1.1. Vòng đời quản lý Secrets (Secrets Management Lifecycle)
Trong các hệ thống Cloud Native hiện đại, quản lý thông tin nhạy cảm (secrets) như database credentials, API keys, certificates không chỉ đơn thuần là việc mã hóa mà là cả một vòng đời khép kín bao gồm các giai đoạn:
1.  **Khởi tạo (Creation):** Khai báo secrets trên một hệ thống lưu trữ an toàn, tập trung.
2.  **Lưu trữ (Storage):** Lưu trữ secrets dưới dạng mã hóa (encryption-at-rest) với các tiêu chuẩn bảo mật cao (ví dụ: FIPS 140-2).
3.  **Truy xuất (Retrieval):** Cấp quyền truy cập và phân phối secrets đến đúng ứng dụng/tiến trình cần sử dụng theo nguyên tắc đặc quyền tối thiểu (Least Privilege).
4.  **Xoay vòng (Rotation):** Thay đổi giá trị của secrets định kỳ hoặc ngay lập tức khi xảy ra sự cố rò rỉ (compromise) để hạn chế tối đa thiệt hại.
5.  **Thu hồi (Revocation) & Hủy bỏ (Destruction):** Vô hiệu hóa secrets cũ hoặc không còn sử dụng.

### 1.2. Cơ chế hoạt động của External Secrets Operator (ESO)
**External Secrets Operator (ESO)** là một Kubernetes Operator được thiết kế để đồng bộ hóa secrets từ các hệ thống quản lý khóa bên ngoài (như AWS Secrets Manager, HashiCorp Vault, Google Secret Manager, Azure Key Vault) vào trong Kubernetes dưới dạng các tài nguyên `Secret` native.

```
+------------------------+           +------------------------------+           +--------------------------+
|  AWS Secrets Manager   | <=======> |  External Secrets Operator   | <=======> |  Kubernetes Native Secret|
| (Lưu trữ tập trung, RM) |   API   |  (SecretStore, ExternalSec)  |  K8s API  |   (Dùng trực tiếp bởi Pod) |
+------------------------+           +------------------------------+           +--------------------------+
```

**Quy trình hoạt động chi tiết:**
1.  **Khai báo kết nối:** Người quản trị định nghĩa `SecretStore` hoặc `ClusterSecretStore` để cấu hình đường dẫn và phương thức xác thực tới External Provider (như AWS Secrets Manager).
2.  **Định nghĩa yêu cầu đồng bộ:** Người dùng tạo tài nguyên `ExternalSecret` để chỉ định cụ thể secret nào cần lấy từ provider và ánh xạ (mapping) vào tên Kubernetes Secret mong muốn.
3.  **Reconciliation Loop:** ESO Controller liên tục giám sát các tài nguyên `ExternalSecret`. Định kỳ (dựa vào `refreshInterval`), ESO thực hiện cuộc gọi API đến AWS Secrets Manager (sử dụng IAM role của ServiceAccount - IRSA) để kiểm tra xem giá trị của secret có thay đổi hay không.
4.  **Cập nhật Native Secret:** Nếu phát hiện thay đổi hoặc tạo mới, ESO sẽ tự động cập nhật hoặc tạo mới Kubernetes Secret native tương ứng. Ứng dụng chạy trong Pod sẽ trực tiếp tiêu thụ Kubernetes Secret này.

---

## 2. So sánh ESO vs Sealed Secrets (Khi nào chọn giải pháp nào)

Khi triển khai GitOps, việc quản lý Secrets là một thách thức lớn vì chúng ta không được phép đẩy secrets dạng clear-text lên Git. Hai giải pháp phổ biến nhất để giải quyết vấn đề này là **External Secrets Operator (ESO)** và **Bitnami Sealed Secrets**.

### 2.1. So sánh chi tiết

| Tiêu chí | External Secrets Operator (ESO) | Sealed Secrets |
| :--- | :--- | :--- |
| **Cơ chế chính** | **Pull-based:** Kéo secrets trực tiếp từ Cloud Provider API vào cụm K8s. | **Push-based:** Mã hóa secrets cục bộ bằng public key và lưu bản mã hóa trên Git. |
| **Nơi lưu trữ gốc** | Lưu trữ tập trung trên Cloud (AWS Secrets Manager, HashiCorp Vault...). | Mã nguồn Git (ở dạng khai báo CRD `SealedSecret` đã được mã hóa). |
| **Cơ chế xoay vòng** | **Tự động:** Hỗ trợ tự động cập nhật khi secret nguồn thay đổi nhờ tính năng rotation của Cloud Provider. | **Thủ công/Phức tạp:** Phải sinh lại secret, chạy công cụ mã hóa lại và push lên Git. |
| **Xác thực và Phân quyền** | Dựa trên IAM/OIDC (như AWS IRSA). Quản lý phân quyền chặt chẽ thông qua Cloud IAM. | Sử dụng cặp khóa Public/Private Key do Sealed Secrets controller quản lý trong cụm. |
| **Khả năng On-Premise / Multi-Cloud** | Yêu cầu kết nối internet/mạng đến Cloud API hoặc một instance Vault tập trung. | Hoàn toàn offline, không phụ thuộc vào bất kỳ nhà cung cấp Cloud nào. |

### 2.2. Khi nào nên chọn giải pháp nào?

*   **Chọn Sealed Secrets khi:**
    *   Hệ thống chạy hoàn toàn On-Premises (Private Cloud, bare-metal) không có sẵn dịch vụ quản lý khóa của các nhà cung cấp Cloud công cộng.
    *   Bạn mong muốn một quy trình GitOps thuần túy (Pure GitOps) - toàn bộ trạng thái của hệ thống bao gồm cả secret mã hóa đều nằm trọn vẹn trong Git repository.
    *   Dự án nhỏ, tần suất thay đổi hoặc xoay vòng secrets rất thấp, không có yêu cầu khắt khe về việc tự động xoay vòng khóa.

*   **Chọn External Secrets Operator (ESO) khi:**
    *   Hệ thống triển khai trên các nền tảng Cloud lớn (AWS, Azure, GCP) và doanh nghiệp yêu cầu sử dụng các dịch vụ quản lý khóa tập trung (KMS, Secrets Manager, Key Vault) để đảm bảo tính tuân thủ bảo mật (Compliance).
    *   Yêu cầu **Tự động Xoay vòng Secrets (Auto-Rotation)** là bắt buộc đối với các thông tin nhạy cảm như thông tin kết nối Database (ví dụ: tự động đổi mật khẩu sau mỗi 30 ngày).
    *   Các nhóm phát triển đã quen làm việc với giao diện UI/CLI của Cloud Provider để quản lý biến môi trường nhạy cảm, tránh việc phải cài đặt thêm công cụ mã hóa (`kubeseal`) ở local.

---

## 3. Định nghĩa các Custom Resource Definitions (CRDs) trong ESO

Để vận hành ESO, chúng ta cần làm quen với các tài nguyên tùy biến (CRD) sau:

### 3.1. SecretStore vs ClusterSecretStore
*   **SecretStore (Namespaced):**
    *   Là tài nguyên giới hạn trong phạm vi một Namespace cụ thể.
    *   Nó chỉ ra cách kết nối và xác thực tới External Provider để phục vụ cho các `ExternalSecret` nằm chung Namespace với nó.
    *   **Khi nào dùng:** Thích hợp khi phân tách môi trường nghiêm ngặt, mỗi đội dự án quản lý một Namespace và có một tài khoản/nhóm quyền truy cập Cloud Provider riêng biệt.
*   **ClusterSecretStore (Cluster-scoped):**
    *   Là tài nguyên cấp cụm (Cluster-wide), không thuộc về bất kỳ Namespace nào.
    *   Nó có thể được chia sẻ và sử dụng bởi các `ExternalSecret` ở mọi Namespace khác nhau trong cụm.
    *   **Khi nào dùng:** Thích hợp cho các secret dùng chung toàn cụm hoặc khi đội ngũ Platform quản lý tập trung việc kết nối AWS Secrets Manager cho toàn bộ hệ thống.

### 3.2. ExternalSecret
*   Là tài nguyên định nghĩa ánh xạ (mapping) giữa dữ liệu nguồn trên Cloud và tài nguyên Kubernetes Secret đích.
*   Nó xác định tần suất quét (`refreshInterval`), tham chiếu tới `SecretStore`/`ClusterSecretStore` nào, lấy khóa nào trong Secrets Manager, và đặt tên cho Kubernetes Secret đích sẽ được tạo ra.

---

## 4. Ví dụ YAML Manifest cấu hình thực tế

Dưới đây là ví dụ hoàn chỉnh cấu hình kết nối AWS Secrets Manager bằng phương thức xác thực IRSA (IAM Roles for Service Accounts).

### 4.1. Cấu hình SecretStore (`secret-store.yaml`)
Để triển khai manifest này, ServiceAccount `eso-service-account` trong namespace `production` phải được annotate với IAM Role ARN có quyền đọc AWS Secrets Manager (IRSA).

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secretsmanager-store
  namespace: production
spec:
  provider:
    aws:
      service: SecretsManager
      region: ap-southeast-1
      auth:
        jwt:
          # Sử dụng IRSA (ServiceAccount token được chiếu) để xác thực với AWS STS
          serviceAccountRef:
            name: eso-service-account
```

### 4.2. Cấu hình ExternalSecret (`external-secret.yaml`)
Khai báo đồng bộ một secret có tên `production/database/credentials` lưu trữ dưới dạng JSON trong AWS Secrets Manager thành Kubernetes Secret native có tên `db-secret`.

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-external-secret
  namespace: production
spec:
  # Tần suất tự động kiểm tra và xoay vòng secrets (60 giây)
  refreshInterval: 1m
  secretStoreRef:
    name: aws-secretsmanager-store
    kind: SecretStore
  target:
    name: db-secret
    creationPolicy: Owner
  data:
    - secretKey: username
      remoteRef:
        key: production/database/credentials
        property: username
    - secretKey: password
      remoteRef:
        key: production/database/credentials
        property: password
```

---

## 5. Cơ chế xoay vòng và cập nhật giá trị Secret cho Pod

Khi ESO cập nhật giá trị mới của Kubernetes Secret (ví dụ: sau khi xoay vòng mật khẩu trên AWS Secrets Manager), cách thức Pod của ứng dụng nhận giá trị mới này phụ thuộc hoàn toàn vào cách Secret được gắn kết (mount) vào Pod.

```
       +------------------------------------+
       |  ESO cập nhật Kubernetes Secret     |
       +------------------------------------+
                        |
         +--------------+--------------+
         |                             |
         v                             v
 [Environment Variables]         [Volume Mounts]
  - Chỉ nạp lúc khởi chạy.       - Kubelet tự đồng bộ file.
  - Pod KHÔNG nhận giá trị mới.   - File tự động cập nhật.
  - Cần restart Pod thủ công     - Cần ứng dụng có cơ chế
    hoặc dùng Tool (Reloader).     đọc lại file (file watcher).
```

### 5.1. Trường hợp sử dụng Biến môi trường (Environment Variables)
*   **Cách cấu hình:**
    ```yaml
    spec:
      containers:
      - name: web-app
        image: nginx:alpine
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
    ```
*   **Cơ chế cập nhật:** Biến môi trường chỉ được nạp vào không gian tiến trình của container **một lần duy nhất** khi Pod khởi chạy. Khi Kubernetes Secret `db-secret` thay đổi giá trị, tiến trình bên trong container vẫn giữ nguyên giá trị cũ.
*   **Giải pháp xử lý:** Để ứng dụng nhận giá trị mới, Pod bắt buộc phải được tái tạo (recreate/restart). Bạn có thể sử dụng các công cụ như **Reloader** (của Stakater) để tự động giám sát thay đổi của Secret và thực hiện lệnh rolling upgrade Deployment, hoặc thực hiện thủ công bằng lệnh:
    ```bash
    kubectl rollout restart deployment/web-app -n production
    ```

### 5.2. Trường hợp sử dụng Volume Mounts
*   **Cách cấu hình:**
    ```yaml
    spec:
      containers:
      - name: web-app
        image: nginx:alpine
        volumeMounts:
        - name: db-secret-volume
          mountPath: /etc/secrets
          readOnly: true
      volumes:
      - name: db-secret-volume
        secret:
          secretName: db-secret
    ```
*   **Cơ chế cập nhật:** Khi sử dụng Volume Mount, Kubelet chịu trách nhiệm đồng bộ hóa nội dung file. Khi Kubernetes Secret thay đổi, Kubelet sẽ phát hiện và cập nhật nội dung tập tin `/etc/secrets/password` bên trong container (chu kỳ cập nhật mặc định phụ thuộc vào tham số `syncFrequency` và cache TTL của kubelet, thường mất khoảng 60-90 giây).
*   **Giải pháp xử lý:** Tiến trình ứng dụng không bị khởi động lại, nhưng ứng dụng cần được lập trình để định kỳ đọc lại tập tin cấu hình hoặc triển khai cơ chế lắng nghe sự kiện thay đổi file (file watch API) để nạp lại cấu hình động (hot-reload). Nếu ứng dụng không hỗ trợ hot-reload, bạn vẫn cần restart Pod tương tự như trường hợp sử dụng biến môi trường.
