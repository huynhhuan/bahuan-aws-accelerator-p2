# W9 Lab README - GitOps, Observability, Canary

## 1. Tổng Quan

W9 gồm 2 phần chính:

- Buổi sáng: GitOps với ArgoCD.
- Buổi chiều: Observability với Prometheus/Grafana và progressive delivery với Argo Rollouts.

Mục tiêu cuối cùng của W9 là chứng minh được pipeline:

```text
Git -> ArgoCD -> Kubernetes -> Prometheus đo lường -> Rollouts canary -> tự abort khi bản lỗi
```

Repo/lab hiện dùng các thành phần chính:

```text
cloud/w9/lab/gitops/
├── argocd/
│   ├── root.yaml
│   └── apps/
│       ├── web.yaml
│       ├── kube-prometheus-stack.yaml
│       ├── argo-rollouts.yaml
│       └── api.yaml
├── k8s/
│   ├── namespace.yaml
│   └── web.yaml
├── k8s-api/
│   ├── alertmanagerconfig.yaml
│   ├── api.yaml
│   ├── servicemonitor.yaml
│   ├── analysis-template.yaml
│   └── prometheusrule.yaml
└── app/
    ├── app.py
    └── Dockerfile
```

## 2. Evidence GitOps

### 2.1. Cluster và ArgoCD hoạt động

![alt text](images/image-12.png)

### 2.2. App-of-apps hoạt động

![alt text](images/image-13.png)

### 2.3. Web app được sync từ Git

![alt text](images/image-14.png)

### 2.4. Self-heal

Chạy scale tay:

```powershell
kubectl -n demo scale deploy/web --replicas=9
```

![alt text](images/image-15.png)
![alt text](images/image-16.png)

### 2.5. Rollback bằng Git

Chạy:

```powershell
git log --oneline -5
git revert HEAD --no-edit
git push
kubectl -n argocd get app web
```

Cần chụp:

- Commit revert trên GitHub hoặc terminal `git log`.
- ArgoCD app sync về revision mới.
- Resource trong cluster quay về trạng thái trước đó.

## 3. Evidence CI/CD - Validate và Branch Protection

### 3.1. Workflow validate

![alt text](images/image-17.png)

### 3.2. PR manifest sai bị chặn

![alt text](images/image-18.png)

## 4. Evidence - Observability

### 4.3. API có metric

Chạy:

```powershell
kubectl -n argocd get app api
kubectl -n demo get rollout,svc,pod
kubectl -n demo get servicemonitor
```

![alt text](images/image-19.png)

### 4.4. Prometheus scrape API thành công

Mở Prometheus:

```powershell
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```

Vào:

```text
http://localhost:9090/targets
```

- Target của `api` ở trạng thái `UP`.
![alt text](images/image-10.png)
- Query metric có dữ liệu:

```promql
flask_http_request_total{namespace="demo"}
```
![alt text](images/image-11.png)

## 5. Evidence Canary Với Argo Rollouts

### 5.1. Canary tốt tự promote

Điều kiện:

```yaml
ERROR_RATE: "0"
VERSION: "v-good"
```

Theo dõi:

```powershell
kubectl argo rollouts get rollout api -n demo --watch
```

![alt text](images/image-8.png)
![alt text](images/image-9.png)

### 5.2. Canary lỗi tự abort

Điều kiện:

```yaml
ERROR_RATE: "0.6"
VERSION: "v-bad"
```

Theo dõi:

```powershell
kubectl argo rollouts get rollout api -n demo --watch
kubectl -n demo describe rollout api
kubectl -n demo get analysisrun
```

![alt text](images/image-3.png)
![alt text](images/image-5.png)
![alt text](images/image-4.png)
![alt text](images/image-6.png)
![alt text](images/image-7.png)

## 6. Evidence SLO và Alert

### 6.1. PrometheusRule đã load

![alt text](images/image-2.png)

### 6.2. Alert chuyển Pending/Firing và Alertmanager gửi email

![alt text](images/image.png)
![alt text](images/image-1.png)

## 7. Evidence Rollback Cuối Bài

Rollback đúng GitOps:

```powershell
git revert HEAD --no-edit
git push
```

![alt text](images/image20.png)
![alt text](images/image21.png)