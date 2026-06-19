# Minh Chứng Thực Hành Lab: W10 Chiều - Securing Supply Chain & Secrets

## 1. External Secrets Operator (ESO)

### 1.1. Trạng thái đồng bộ của ExternalSecret
![alt text](<Screenshot 2026-06-19 100908.png>)

### 1.2. Kubernetes Secret được tự động tạo ra
*Lệnh tham khảo:* `kubectl get secret db-password-k8s -n demo`
![alt text](<Screenshot 2026-06-19 101313.png>)

---

## 2. CI/CD: Quét Lỗ Hổng Tự Động (Trivy)
![alt text](<Screenshot 2026-06-19 105044.png>)

---

## 3. Supply Chain Security (Sigstore & Cosign)

### 3.1. Thử deploy Pod với Image CHƯA KÝ chữ ký điện tử

**Manifest test (test-unsigned.yaml):**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-unsigned-pod
  namespace: demo
  labels:
    owner: huan
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
  containers:
  - name: app
    image: nginx:1.25.0
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"
```

![alt text](<Screenshot 2026-06-19 101753.png>)

---

### 3.2. Thử deploy Pod với Image ĐÃ KÝ chữ ký điện tử (Hợp lệ)
**Manifest test (test-cosign.yaml):**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-cosign
  namespace: demo
  labels:
    owner: huan
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
  containers:
  - name: app
    image: ghcr.io/huynhhuan/w10-api:v0.0.1
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"
```

**Minh chứng Terminal:**
> **[DÁN ẢNH CHỤP MÀN HÌNH TẠI ĐÂY]**
