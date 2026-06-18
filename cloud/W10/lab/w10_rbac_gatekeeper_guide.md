# Hướng Dẫn Thực Hành W10: RBAC & Admission Policy (Gatekeeper)

Tài liệu này hướng dẫn bạn hoàn thành bài lab W10 về phân quyền (RBAC) và thực thi chính sách (Gatekeeper) theo chuẩn GitOps và Best Practice.

---

## Phần 1: Phân quyền RBAC (Lab 1.1)

**Mục tiêu:** Tạo 3 roles cho `alice`, `bob`, và `carol`. Mọi thao tác đều thực hiện qua file YAML và đồng bộ bằng ArgoCD.

### Bước 1.1: Tạo file cấu hình RBAC
Trong repo của bạn, tạo thư mục `rbac` và thêm 2 file sau:

**1. `rbac/roles.yaml` (Định nghĩa quyền):**
```yaml
# ==================================================
# Alice - Developer (namespace demo)
# CRUD workload trong namespace demo
# ==================================================
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-role
  namespace: demo
rules:
# Core resources
- apiGroups: [""]
  resources:
    - pods
    - services
    - endpoints
  verbs:
    - create
    - delete
    - get
    - list
    - watch
    - patch
    - update

# Deployments / ReplicaSets
- apiGroups: ["apps"]
  resources:
    - deployments
    - replicasets
  verbs:
    - create
    - delete
    - get
    - list
    - watch
    - patch
    - update

# Argo Rollouts
- apiGroups: ["argoproj.io"]
  resources:
    - rollouts
  verbs:
    - create
    - delete
    - get
    - list
    - watch
    - patch
    - update

---
# ==================================================
# Bob - SRE (cluster-wide)
# Xem + thao tác Pod toàn cụm
# ==================================================
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: sre-role
rules:
- apiGroups: [""]
  resources:
    - pods
  verbs:
    - get
    - list
    - watch
    - create
    - update
    - patch
    - delete

- apiGroups: [""]
  resources:
    - pods/log
  verbs:
    - get
    - list
    - watch

- apiGroups: [""]
  resources:
    - pods/exec
    - pods/portforward
  verbs:
    - create

---
# ==================================================
# Carol - Viewer (cluster-wide readonly)
# ==================================================
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: viewer-role
rules:
- apiGroups: [""]
  resources:
    - pods
    - services
    - endpoints
    - namespaces
  verbs:
    - get
    - list
    - watch

- apiGroups: ["apps"]
  resources:
    - deployments
    - replicasets
    - daemonsets
    - statefulsets
  verbs:
    - get
    - list
    - watch

- apiGroups: ["argoproj.io"]
  resources:
    - rollouts
  verbs:
    - get
    - list
    - watch
```

**2. `rbac/rolebindings.yaml` (Gắn quyền cho người dùng):**
```yaml
# Gắn Role cho Alice trong ns demo
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: alice-developer-binding
  namespace: demo
subjects:
- kind: User
  name: alice
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
---
# Gắn ClusterRole cho Bob
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: bob-sre-binding
subjects:
- kind: User
  name: bob
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: sre-role
  apiGroup: rbac.authorization.k8s.io
---
# Gắn ClusterRole cho Carol
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: carol-viewer-binding
subjects:
- kind: User
  name: carol
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: viewer-role
  apiGroup: rbac.authorization.k8s.io
```

### Bước 1.2: Tạo ArgoCD App cho RBAC
Tạo file `argocd/apps/app-rbac.yaml` để ArgoCD quản lý thư mục `rbac`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: rbac
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/<GITHUB_CỦA_BẠN>/bahuan-aws-accelerator-p2.git # Thay bằng URL repo của bạn
    path: rbac
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

> [!TIP]
> Lưu các file lại, Commit và Push lên GitHub. Sau đó vào ArgoCD kiểm tra xem app `rbac` đã được Sync chưa.

### Bước 1.3: Kiểm tra nghiệm thu (Test)
Chạy các lệnh sau trên terminal của bạn để xác nhận (Yêu cầu kết quả phải khớp):
```bash
kubectl auth can-i create deploy -n demo --as alice       # Kết quả: yes
kubectl auth can-i create deploy -n kube-system --as alice # Kết quả: no
kubectl auth can-i get pods -A --as bob                   # Kết quả: yes
kubectl auth can-i delete nodes --as carol                # Kết quả: no
```

---

## Phần 2: Admission Policy với Gatekeeper (Lab 1.2)

### Bước 2.1: Cài đặt Gatekeeper qua ArgoCD
Tạo file `argocd/apps/k8s-gatekeeper.yaml`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gatekeeper
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "-1" # Đảm bảo cài đặt sớm
spec:
  project: default
  source:
    repoURL: https://open-policy-agent.github.io/gatekeeper/charts
    chart: gatekeeper
    targetRevision: 3.16.0
  destination:
    server: https://kubernetes.default.svc
    namespace: gatekeeper-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```
*Commit và push để cài đặt Gatekeeper.*

### Bước 2.2: Cài đặt ConstraintTemplates (Thư viện mẫu)
Tạo thư mục `gatekeeper/templates` và `gatekeeper/constraints`.
Để tiết kiệm thời gian, chúng ta sẽ tải ConstraintTemplates chuẩn từ OPA Library. Tạo một file `gatekeeper/templates/k8s-templates.yaml` chứa các mẫu sau (hoặc chia nhỏ thành từng file):

```yaml
# Do file mẫu (Rego) rất dài, bạn có thể tham khảo từ thư viện chuẩn hoặc sử dụng trực tiếp các bản yaml mẫu.
# Thay vì tự copy code dài, bạn hãy lấy file K8sRequiredLimits, K8sBannedImageTags, K8sPSPHostNetworkingPorts, K8sPSPAllowedUsers.
```
*(Trong thực tế, do bạn đang làm trên repo local, hãy copy các template cần thiết từ [Gatekeeper Library](https://github.com/open-policy-agent/gatekeeper-library) vào thư mục `gatekeeper/templates`)*

### Bước 2.3: Viết 4 luật Constraint
Tạo file `gatekeeper/constraints/policies.yaml`:
```yaml
# 1. Cấm image tag :latest
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sBannedImageTags
metadata:
  name: block-latest-tag
spec:
  enforcementAction: warn # Best Practice: Luôn bật warn (Audit mode) trước khi deny thật
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    excludedNamespaces: ["kube-system", "gatekeeper-system", "argocd", "default"] # Best Practice: Áp dụng toàn cụm trừ các ns hệ thống
  parameters:
    tags: ["latest"]

---
# 2. Bắt buộc có resources.limits
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLimits
metadata:
  name: require-limits
spec:
  enforcementAction: warn
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    excludedNamespaces: ["kube-system", "gatekeeper-system", "argocd", "default"]

---
# 3. Cấm runAsUser: 0 (chạy root)
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sPSPAllowedUsers
metadata:
  name: block-root-user
spec:
  enforcementAction: warn
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    excludedNamespaces: ["kube-system", "gatekeeper-system", "argocd", "default"]
  parameters:
    runAsUser:
      rule: MustRunAsNonRoot

---
# 4. Cấm hostNetwork: true
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sPSPHostNetworkingPorts
metadata:
  name: block-host-network
spec:
  enforcementAction: warn
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    excludedNamespaces: ["kube-system", "gatekeeper-system", "argocd", "default"]
  parameters:
    hostNetwork: false
```

> [!WARNING]
> BẪY QUAN TRỌNG: Hãy đảm bảo rằng chính các ứng dụng của bạn (ví dụ file `rollout.yaml` của `app-api`) đã cấu hình đầy đủ `resources.limits`, image không dùng tag `:latest`, và `securityContext: runAsNonRoot: true` TRƯỚC KHI bật các constraint này. Nếu không ứng dụng của bạn sẽ bị sập.

---

## Phần 3: Custom Policy (Lab 1.3)

**Đề bài chọn:** Bắt buộc mọi Deployment/Pod phải có label `owner`.

Tạo file `gatekeeper/custom-policy.yaml`:
```yaml
# Constraint Template (Định nghĩa luật Rego)
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels

        violation[{"msg": msg, "details": {"missing_labels": missing}}] {
          provided := {label | input.review.object.metadata.labels[label]}
          required := {label | label := input.parameters.labels[_]}
          missing := required - provided
          count(missing) > 0
          msg := sprintf("Bạn phải cung cấp các labels sau: %v", [missing])
        }
---
# Constraint: Bắt buộc namespace demo phải có nhãn "owner"
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: require-owner-label
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
      - apiGroups: ["apps"]
        kinds: ["Deployment", "Rollout"]
    namespaces: ["demo"]
  parameters:
    labels: ["owner"]
```

### Bước 3.1: Đẩy cấu hình lên GitOps
Tạo tiếp file `argocd/apps/app-gatekeeper-policies.yaml` để kéo các cấu hình Constraint Templates và Constraints về cụm:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gatekeeper-policies
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "1" # Chạy sau khi Gatekeeper controller đã được cài đặt (wave -1)
spec:
  project: default
  source:
    repoURL: https://github.com/<GITHUB_CỦA_BẠN>/bahuan-aws-accelerator-p2.git
    path: gatekeeper
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: gatekeeper-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

> [!NOTE]
> **Quy trình chuẩn nghiệm thu (Best Practice):** 
> 1. Đẩy file lên với `enforcementAction: warn`.
> 2. Kiểm tra log của Gatekeeper hoặc describe constraint xem có app nào đang vi phạm không.
> 3. Nếu mọi thứ an toàn, sửa toàn bộ chữ `warn` thành `deny` để bật khiên bảo vệ thực sự (Chặn đứng các vi phạm).
> 4. Thử chạy một lệnh `kubectl run nginx --image=nginx:latest` (vi phạm tag :latest) và quan sát API Server từ chối lệnh của bạn!
