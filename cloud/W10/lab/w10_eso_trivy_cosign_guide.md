# Hướng Dẫn Thực Hành W10 Buổi Chiều: ESO + Trivy + Cosign

Tài liệu này hướng dẫn chi tiết từng bước (Step-by-step) để hoàn thành **Lab 2** của tuần 10: Quản lý Secret an toàn với **ESO** và Bảo mật chuỗi cung ứng với **Trivy & Cosign**.

---

## Phần 1: External Secrets Operator (Lab 2.1)

**Mục tiêu:** Đồng bộ Secret từ AWS Secrets Manager về Kubernetes. Khi thay đổi Secret trên AWS, K8s Secret tự động cập nhật dưới 60s và **Pod không bị restart**.

### Bước 1.1: Cài đặt ESO Operator qua ArgoCD
Để quản lý ESO bằng GitOps, tạo file `argocd/apps/eso.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: external-secrets
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "-1" # Cài đặt Operator trước
spec:
  project: default
  source:
    repoURL: https://charts.external-secrets.io
    chart: external-secrets
    targetRevision: 0.9.4
  destination:
    server: https://kubernetes.default.svc
    namespace: external-secrets
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```
*Lưu ý: Commit và Push file này để ArgoCD cài đặt ESO trước khi làm các bước tiếp theo.*

### Bước 1.2: Cấp quyền AWS cho ESO (Tạo Secret thủ công)
> [!WARNING]
> BẪY BẢO MẬT: File chứa AWS Credentials tuyệt đối **KHÔNG ĐƯỢC COMMIT** lên GitHub. Chúng ta sẽ tạo thủ công trực tiếp bằng lệnh `kubectl`.

Chạy lệnh sau trên terminal của bạn (thay bằng key AWS thật của bạn):
```bash
kubectl create secret generic aws-secret \
  --namespace=demo \
  --from-literal=access-key-id='AKIA...' \
  --from-literal=secret-access-key='xxx...'
```

### Bước 1.3: Khai báo SecretStore và ExternalSecret
Tạo thư mục `eso/` và thêm 2 file sau:

**1. `eso/secret-store.yaml` (Kết nối tới AWS):**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secretsmanager
  namespace: demo
  annotations:
    argocd.argoproj.io/sync-wave: "1"
spec:
  provider:
    aws:
      service: SecretsManager
      region: ap-southeast-1 # Thay đổi nếu cần
      auth:
        secretRef:
          accessKeyIDSecretRef:
            name: aws-secret
            key: access-key-id
          secretAccessKeySecretRef:
            name: aws-secret
            key: secret-access-key
```

**2. `eso/external-secret.yaml` (Định nghĩa việc đồng bộ):**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-password-es
  namespace: demo
  annotations:
    argocd.argoproj.io/sync-wave: "2"
spec:
  refreshInterval: "30s" # Đồng bộ siêu tốc dưới 60s
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  target:
    name: db-password-k8s # Tên Secret thật sẽ được sinh ra trong K8s
    creationPolicy: Owner
  data:
    - secretKey: password # Key trong K8s Secret
      remoteRef:
        key: path/to/your/aws/secret # Đường dẫn/Tên Secret trên AWS
        property: password # Key tương ứng trên AWS JSON
```

### Bước 1.4: Cập nhật App để đọc Secret qua Volume
Để Secret thay đổi mà Pod không bị Restart, **bắt buộc** phải mount Secret dưới dạng Volume thay vì Environment Variable.
Mở file `app-api/rollout.yaml`, tìm đến phần `containers` và sửa lại:

```yaml
        volumeMounts:
        - name: db-secret-volume
          mountPath: /etc/secrets
          readOnly: true
      volumes:
      - name: db-secret-volume
        secret:
          secretName: db-password-k8s # Trỏ tới Secret do ESO sinh ra
```

### Bước 1.5: Đưa ESO Config lên GitOps
Tạo file `argocd/apps/eso-config.yaml` để kéo thư mục `eso/` về:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: eso-config
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "1"
spec:
  project: default
  source:
    repoURL: https://github.com/<GITHUB_CỦA_BẠN>/bahuan-aws-accelerator-p2.git
    path: eso
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: demo
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```
**Nghiệm thu Lab 2.1:** Commit toàn bộ và Push. Sau đó lên AWS đổi giá trị Secret. Đợi 30s, chạy `kubectl get secret db-password-k8s -n demo -o yaml` để xem giá trị mới. Chạy `kubectl get pod -n demo` để xác nhận Pod không bị restart (AGE không đổi).

---

## Phần 2: Trivy + Cosign (Lab 2.2)

**Mục tiêu:** Quét lỗ hổng (Trivy), Ký Image (Cosign) trên CI. Chặn không cho deploy các Image chưa được ký vào K8s (Admission Controller).

### Bước 2.1: Tạo cặp khóa Cosign
Chạy lệnh sau trên terminal để tạo Key Pair (Bấm Enter bỏ qua password nếu dùng cho mục đích Lab):
```bash
cosign generate-key-pair
```
Sẽ có 2 file sinh ra: `cosign.key` (Private) và `cosign.pub` (Public).
> [!IMPORTANT]
> 1. Copy nội dung file `cosign.key`, vào GitHub Repo -> **Settings -> Secrets and variables -> Actions**, tạo 1 secret tên là `COSIGN_PRIVATE_KEY` chứa nội dung này.
> 2. Đổi tên file `cosign.pub` và di chuyển nó vào thư mục `signing/cosign.pub` trong repo để commit lên Git.
> 3. XÓA NGAY file `cosign.key` ở dưới máy local. KHÔNG BAO GIỜ COMMIT PRIVATE KEY!

### Bước 2.2: Cập nhật Github Actions (CI)
Mở file `.github/workflows/build-push.yml`, thêm các bước Trivy và Cosign ngay sau bước Push Image:

```yaml
      - name: Quét lỗ hổng với Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'your-dockerhub-user/app-api:${{ github.sha }}'
          format: 'table'
          exit-code: '1' # Cố tình làm fail pipeline nếu có lỗi HIGH/CRITICAL
          ignore-unfixed: true
          vuln-type: 'os,library'
          severity: 'CRITICAL,HIGH'

      - name: Ký Image với Cosign
        # Chạy Cosign kể cả khi Trivy pass
        uses: sigstore/cosign-installer@v3.1.1
        
      - name: Thực hiện ký
        env:
          COSIGN_PRIVATE_KEY: ${{ secrets.COSIGN_PRIVATE_KEY }}
        run: |
          cosign sign --key env://COSIGN_PRIVATE_KEY -y your-dockerhub-user/app-api:${{ github.sha }}
```

### Bước 2.3: Cài đặt Sigstore Policy Controller
Tạo file `argocd/apps/policy-controller.yaml`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: policy-controller
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
spec:
  project: default
  source:
    repoURL: https://sigstore.github.io/helm-charts
    chart: policy-controller
    targetRevision: 0.6.0 # Phiên bản tham khảo
  destination:
    server: https://kubernetes.default.svc
    namespace: cosign-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Bước 2.4: Định nghĩa ClusterImagePolicy
Tạo thư mục `policies/` và thêm file `policies/cluster-image-policy.yaml`:
```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: require-cosign-signature
  annotations:
    argocd.argoproj.io/sync-wave: "1"
spec:
  images:
    - glob: "your-dockerhub-user/*" # Áp dụng cho toàn bộ image của bạn
  authorities:
    - key:
        data: |
          -----BEGIN PUBLIC KEY-----
          [DÁN NỘI DUNG FILE COSIGN.PUB CỦA BẠN VÀO ĐÂY]
          -----END PUBLIC KEY-----
```
*Lưu ý: Tạo thêm file `argocd/apps/policies.yaml` để kéo thư mục `policies/` này về tương tự như các bước trên.*

### Bước 2.5: Bật khiên bảo vệ cho Namespace
> [!TIP]
> Sigstore Policy Controller chỉ bắt đầu kiểm tra chữ ký ở những Namespace có gắn label `policy.sigstore.dev/include=true`.

Do namespace `demo` chúng ta tạo bằng tay (hoặc qua ArgoCD), bạn có thể gõ lệnh sau để bật khiên:
```bash
kubectl label namespace demo policy.sigstore.dev/include=true
```

**Nghiệm thu Lab 2.2:**
1. Thử sửa code push lên, chờ CI quét Trivy (nếu có lỗi HIGH sẽ đỏ ngòm).
2. Khi CI pass và Cosign ký xong, thử gõ lệnh sửa file `rollout.yaml` sang một cái image tào lao (ví dụ `nginx:latest` chưa ký), Policy Controller sẽ chặn đứng: `admission webhook ... denied the request: no matching signatures`.

---
Chúc bạn hoàn thành trọn vẹn buổi chiều Lab W10 cực kỳ thực chiến này!
