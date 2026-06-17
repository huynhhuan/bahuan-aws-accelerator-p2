# Bảo Mật Chuỗi Cung Ứng Container và Xác Thực Chữ Ký Ảnh

## 1. Bảo mật chuỗi cung ứng container và Khung bảo mật SLSA

### 1.1. Khái niệm Chuỗi cung ứng phần mềm (Software Supply Chain Security)
Chuỗi cung ứng phần mềm container bao gồm tất cả các thành phần, công cụ và quy trình tham gia vào việc phát triển, đóng gói, phân phối và triển khai ứng dụng. Nó kéo dài từ mã nguồn của lập trình viên, các thư viện phụ thuộc (dependencies), công cụ build (CI), các container registry lưu trữ ảnh, cho đến khi ứng dụng chạy thực tế trên Kubernetes.

Tấn công chuỗi cung ứng có thể xảy ra ở bất kỳ mắt xích nào:
*   Mã nguồn bị chèn backdoor hoặc mã độc.
*   Công cụ CI/CD bị chiếm quyền điều khiển để build ra các sản phẩm lỗi/độc hại.
*   Ảnh container bị tráo đổi hoặc giả mạo ngay trên Container Registry.
*   Kẻ tấn công khai thác lỗ hổng bảo mật chưa được vá (CVE) trong các thư viện bên thứ ba.

### 1.2. Khung bảo mật SLSA (Supply-chain Levels for Software Artifacts)
**SLSA** là một bộ tiêu chuẩn bảo mật được phát triển bởi cộng đồng (dẫn dắt bởi Google) nhằm tăng cường tính toàn vẹn của các sản phẩm phần mềm (artifacts). SLSA định nghĩa các cấp độ bảo mật (từ Level 1 đến Level 3) dựa trên khả năng chống giả mạo của quy trình build và tính minh bạch của nguồn gốc phần mềm (**Provenance**).
*   **SLSA Level 1:** Yêu cầu quy trình build phải được tự động hóa hoàn toàn và sinh ra tài liệu Provenance mô tả cách sản phẩm được build.
*   **SLSA Level 2:** Yêu cầu quy trình build phải chạy trên nền tảng build chuyên dụng (hosted build service) và tài liệu Provenance phải được ký số bởi chính nền tảng build đó để chống giả mạo.
*   **SLSA Level 3:** Yêu cầu môi trường build phải hoàn toàn cô lập (isolated), ngăn chặn việc rò rỉ mã nguồn hoặc can thiệp từ bên ngoài trong suốt quá trình build, đảm bảo tính xác thực tối đa.

---

## 2. Quét lỗ hổng với Trivy trong quy trình CI/CD

Để ngăn chặn các ảnh container chứa lỗ hổng bảo mật nghiêm trọng được đẩy lên registry hoặc triển khai lên cụm Kubernetes, chúng ta tích hợp công cụ quét lỗ hổng **Trivy** vào pipeline CI/CD.

### 2.1. Cơ chế hoạt động của Trivy
Trivy quét qua hệ điều hành của container (OS packages như alpine, debian) và các gói phụ thuộc của ngôn ngữ lập trình (như npm, pip, go.mod) để đối chiếu với cơ sở dữ liệu lỗ hổng bảo mật quốc gia (NVD, GitHub Advisories).

Để kiểm soát chất lượng bảo mật trong CI/CD, chúng ta cấu hình Trivy hoạt động theo cơ chế **Fail-Build**:
*   Tham số `--exit-code 1`: Hướng dẫn Trivy trả về mã thoát (exit code) là `1` (thất bại) thay vì `0` (thành công) khi tìm thấy các lỗi thỏa mãn điều kiện lọc. Điều này trực tiếp làm dừng pipeline CI/CD.
*   Tham số `--severity HIGH,CRITICAL`: Chỉ tập trung chặn các lỗ hổng có mức độ nghiêm trọng cao (`HIGH`) và cực kỳ nghiêm trọng (`CRITICAL`), tránh làm phiền luồng CI/CD bởi các lỗi nhỏ (`LOW`, `MEDIUM`) chưa cần ưu tiên xử lý gấp.

### 2.2. Ví dụ cấu hình GitHub Actions Workflow
Dưới đây là một job mẫu trong GitHub Actions thực hiện build ảnh docker, quét bằng Trivy, và chỉ cho phép push ảnh lên registry nếu ảnh vượt qua bài quét bảo mật.

```yaml
name: Build and Secure Image

on:
  push:
    branches: [ "main" ]

jobs:
  build-and-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Build Docker Image
        run: |
          docker build -t myapp:latest .

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'myapp:latest'
          format: 'table'
          # Trả về lỗi 1 nếu phát hiện lỗ hổng HIGH hoặc CRITICAL
          exit-code: '1'
          ignore-unfixed: true
          vuln-type: 'os,library'
          severity: 'HIGH,CRITICAL'

      - name: Push Image to Registry (Chỉ chạy nếu bước quét Trivy thành công)
        run: |
          echo "Trivy passed! Pushing image to registry..."
          # docker push myapp:latest
```

---

## 3. Ký số ảnh container bằng Cosign

Sau khi ảnh container đã vượt qua bước quét lỗ hổng, chúng ta cần ký số ảnh đó để chứng minh nguồn gốc tin cậy và ngăn chặn việc tráo đổi ảnh. Công cụ tiêu chuẩn cho việc này là **Cosign** (thuộc dự án Sigstore).

```
   +-------------------+
   | Container Image   |
   +-------------------+
             |
             v
   [ Cosign Sign Tool ]  <--- (Private Key OR OIDC/Fulcio CA)
             |
             v
   +-------------------+
   | Signed Container  |
   | (Image + Signature|
   |   in Registry)    |
   +-------------------+
```

### 3.1. Ký số dựa trên khóa (Key-based Signing)
*   **Cách hoạt động:** Người dùng tạo ra một cặp khóa Public/Private Key cục bộ bằng lệnh `cosign generate-key-pair`.
*   **Quy trình ký:**
    1.  Khóa riêng tư (`cosign.key`) được lưu giữ bí mật (thường đưa vào GitHub Secrets hoặc HashiCorp Vault) và được bảo vệ bằng mật khẩu (passphrase).
    2.  Khi chạy pipeline build, Cosign dùng khóa riêng tư ký lên SHA-256 digest của ảnh container và đẩy chữ ký đó lên Container Registry dưới dạng một artifact song hành với ảnh.
    3.  Khóa công khai (`cosign.pub`) được phân phối công khai cho hệ thống Admission Control của Kubernetes để xác thực ảnh trước khi chạy.
*   **Nhược điểm:** Đòi hỏi quy trình quản lý khóa phức tạp. Nếu mất khóa riêng tư, bạn không thể ký ảnh mới; nếu lộ khóa riêng tư, kẻ tấn công có thể ký và phân phối mã độc dưới danh nghĩa của bạn.

### 3.2. Ký số không dùng khóa (Keyless Signing)
Keyless signing là cơ chế đột phá của Sigstore, giúp loại bỏ hoàn toàn việc lưu trữ và quản lý các khóa riêng tư dài hạn bằng cách sử dụng các chứng chỉ số tạm thời liên kết với danh tính người ký (Identity-based).

**Các thành phần cốt lõi:**
*   **OIDC (OpenID Connect) Provider:** Xác thực danh tính của thực thể ký (ví dụ: GitHub Actions cung cấp OIDC token xác nhận pipeline đang chạy thuộc về repo cụ thể).
*   **Fulcio (Certificate Authority - CA):** Cấp phát chứng chỉ X.509 tạm thời dựa trên danh tính được xác thực bởi OIDC.
*   **Rekor (Transparency Log):** Sổ cái lưu trữ mọi giao dịch ký số một cách công khai và không thể sửa đổi (append-only ledger).

**Quy trình hoạt động từng bước:**
```
+--------------+ 1. OIDC Token  +-------------+ 2. Issue Temp Cert  +------------+
|  CI Runner   | -------------> |  Fulcio CA  | ------------------> |  CI Runner |
| (Ký tạm thời)|                +-------------+                     |            |
+--------------+                                                    +------------+
       |                                                                   |
       | 3. Ghi chép giao dịch và lấy bằng chứng thời gian (SET)            |
       v                                                                   v
+--------------+                                                    +------------+
|  Rekor Log   | <------------------------------------------------- |  Sign Image|
+--------------+                                                    +------------+
```

1.  **Xác thực OIDC:** Khi bắt đầu ký, công cụ Cosign trên CI Runner yêu cầu một OIDC ID Token từ Identity Provider (ví dụ: GitHub OIDC). Token này chứa thông tin định danh của pipeline (như repository URL, workflow name).
2.  **Sinh cặp khóa tạm thời:** Cosign tự sinh một cặp khóa Public/Private Key tạm thời (ephemeral keys) chỉ tồn tại trong bộ nhớ RAM của CI Runner.
3.  **Yêu cầu chứng chỉ:** Cosign gửi khóa công khai tạm thời cùng OIDC ID Token tới Fulcio CA.
4.  **Cấp chứng chỉ tạm thời:** Fulcio xác thực OIDC Token, trích xuất danh tính (ví dụ: `https://github.com/my-org/my-repo/.github/workflows/ci.yml@refs/heads/main`) và tạo ra một chứng chỉ X.509 tạm thời liên kết với khóa công khai đó. Chứng chỉ này chỉ có hiệu lực trong **10 phút**.
5.  **Ký ảnh:** Cosign dùng khóa riêng tư tạm thời ký lên ảnh container.
6.  **Ghi sổ cái Rekor:** Chữ ký, chứng chỉ tạm thời và metadata của ảnh được gửi lên Rekor Transparency Log. Rekor ghi nhận giao dịch vào sổ cái công khai và trả về một bằng chứng ghi nhận được ký số gọi là **Signed Entry Timestamp (SET)**.
7.  **Hủy khóa:** Quá trình kết thúc, khóa riêng tư tạm thời trong bộ nhớ RAM của Runner bị hủy bỏ hoàn toàn.
8.  **Xác thực sau này:** Khi Kubernetes xác thực ảnh, nó không cần một khóa công khai cố định. Nó kiểm tra chữ ký dựa vào chứng chỉ tạm thời của Fulcio, đối chiếu bằng chứng SET trong Rekor để đảm bảo rằng tại thời điểm ký ghi nhận trên Rekor, chứng chỉ X.509 đó vẫn đang trong thời gian có hiệu lực hợp lệ.

---

## 4. Xác thực chữ ký tại Kubernetes Admission Control bằng Kyverno

Sau khi ảnh đã được ký, chúng ta cần cấu hình cụm Kubernetes để từ chối chạy bất kỳ ảnh nào không có chữ ký hợp lệ. Chúng ta thực hiện việc này thông qua **Kyverno Admission Controller**.

### 4.1. Cơ chế hoạt động
Kyverno hoạt động như một Mutating/Validating Admission Webhook. Khi người dùng gửi yêu cầu tạo Pod (hoặc Deployment, StatefulSet), API Server sẽ chuyển yêu cầu đó tới Kyverno trước khi lưu vào etcd. Kyverno sẽ:
1.  Phân tích ảnh container được khai báo trong Pod Spec.
2.  Tìm kiếm chữ ký tương ứng của ảnh đó trên Container Registry.
3.  Sử dụng khóa công khai cấu hình sẵn (hoặc truy vấn Rekor/Fulcio đối với Keyless) để kiểm tra chữ ký.
4.  Nếu chữ ký hợp lệ, cho phép deploy. Nếu không, từ chối yêu cầu và trả về lỗi cho người dùng.

### 4.2. Ví dụ Kyverno ClusterPolicy YAML
Dưới đây là một `ClusterPolicy` hoàn chỉnh cấu hình kiểm tra chữ ký ảnh container sử dụng **Key-based** (sử dụng khóa công khai khai báo trực tiếp).

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signatures
  annotations:
    policies.kyverno.io/title: Verify Image Signatures with Cosign
    policies.kyverno.io/subject: Pod, Deployment
spec:
  validationFailureAction: Enforce # Chặn triển khai trực tiếp nếu vi phạm
  background: false
  rules:
    - name: verify-cosign-signature
      match:
        any:
          - resources:
              kinds:
                - Pod
      verifyImages:
        - imageReferences:
            # Áp dụng chính sách cho các ảnh thuộc registry chỉ định
            - "ghcr.io/my-org/*"
            - "docker.io/my-org/*"
          attestations: []
          attestors:
            - entries:
                - keys:
                    publicKeys: |-
                      -----BEGIN PUBLIC KEY-----
                      MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEt/1WpHyUuV3YcUp3hA29zJj9i4Vf
                      4wQfL7p7yJq6n9mQZ89U1pQk0c4D9v1xYn+ZJqL3U4Q9/8K/5WpHyUuV3YcUp3hA
                      ==
                      -----END PUBLIC KEY-----
```

---

## 5. Chính sách ngoại lệ CVE (CVE Exception Policy)

Trong thực tế vận hành sản xuất (Production), việc áp dụng chính sách cứng nhắc "fail-build" hoặc "fail-deploy" đối với 100% các lỗ hổng HIGH/CRITICAL đôi khi gây tê liệt hệ thống phát triển do:
*   **Lỗ hổng chưa có bản vá (No Fix Available):** Nhà phát triển thư viện chưa tung ra phiên bản sửa lỗi, nhưng đội phát triển dự án bắt buộc phải deploy tính năng mới để kịp tiến độ kinh doanh.
*   **Lỗ hổng không thể khai thác (Not Exploitable/False Positive):** Lỗ hổng nằm trong một module của thư viện nhưng dự án hoàn toàn không import hoặc gọi tới module đó trong mã nguồn.

Để giải quyết mâu thuẫn này, doanh nghiệp cần thiết lập một quy trình xử lý ngoại lệ chặt chẽ, chuyên nghiệp và có kiểm soát.

### 5.1. Tài liệu quyết định kiến trúc (Architecture Decision Record - ADR)
Khi quyết định bỏ qua một lỗ hổng bảo mật để deploy ứng dụng, đội ngũ kỹ sư (SRE, Security Team, Tech Lead) phải cùng ký duyệt một tài liệu ADR lưu trữ trong Git. Nội dung ADR phải làm rõ:
*   **Mã lỗ hổng (CVE-ID):** Ví dụ `CVE-2026-12345`.
*   **Mức độ ảnh hưởng thực tế:** Phân tích xem lỗ hổng có thể bị khai thác trong môi trường của doanh nghiệp hay không (ví dụ: service chạy trong mạng nội bộ, không tiếp xúc internet nên rủi ro thấp).
*   **Biện pháp giảm thiểu tạm thời (Mitigation):** Thiết lập luật WAF để chặn payload tấn công, hoặc hạn chế quyền NetworkPolicy của Pod.
*   **Kế hoạch xử lý triệt để:** Thời hạn dự kiến sẽ nâng cấp hoặc thay thế thư viện.

### 5.2. Cấu hình Exception Policy có thời hạn
Để tránh việc các ngoại lệ bị lãng quên mãi mãi (gây tích tụ nợ bảo mật), chính sách ngoại lệ phải được khai báo bằng cấu hình máy có thể đọc và tự động hết hạn.

**Ví dụ sử dụng file cấu hình bỏ qua lỗ hổng của Trivy (`.trivyignore`):**
Trivy hỗ trợ bỏ qua lỗ hổng bằng cách khai báo danh sách lỗ hổng trong file `.trivyignore`. Chúng ta bắt buộc phải cấu hình kèm ghi chú phê duyệt và thời gian hết hạn (`expiring date`).

```
# .trivyignore
# Cấu trúc: [CVE-ID] # [Lý do] [Người phê duyệt] [Ngày hết hạn: YYYY-MM-DD]

# Bỏ qua CVE-2026-8888 do thư viện gốc chưa có bản vá. Sẽ đánh giá lại sau 30 ngày.
CVE-2026-8888 # No-fix-available approved-by:lead-sre expires:2026-07-15

# Lỗ hổng CVE-2026-9999 nằm trong module CLI của thư viện, ứng dụng chỉ dùng module API.
CVE-2026-9999 # Not-exploitable approved-by:sec-team expires:2026-08-30
```

**Quy trình kiểm soát tự động:**
*   Khi chạy quét Trivy, nếu ngày hiện tại vượt quá ngày ghi sau từ khóa `expires`, Trivy sẽ tự động kích hoạt lại cảnh báo cho CVE đó và làm fail-pipeline.
*   Điều này ép buộc đội phát triển phải định kỳ đánh giá lại trạng thái bảo mật của ứng dụng, cập nhật bản vá mới ngay khi nó được phát hành.
