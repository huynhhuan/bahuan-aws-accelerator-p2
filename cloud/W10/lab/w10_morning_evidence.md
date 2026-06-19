# Minh Chứng Thực Hành Lab: W10 Sáng - RBAC & OPA Gatekeeper

## 1. Phân Quyền Truy Cập (RBAC)
![alt text](images/image.png)

## 2. Nghiệm thu OPA Gatekeeper (5 bài test)
![alt text](images/image-1.png)

### 2.1. Thử deploy Pod dùng Image `:latest`
**Manifest test:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-latest-tag
  namespace: demo
  labels:
    owner: huan
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
  containers:
  - name: app
    image: nginx:latest
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"
```

**Minh chứng Terminal:**
![alt text](images/image-2.png)

---

### 2.2. Thử deploy Pod thiếu `resources.limits`
**Manifest test:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-no-limits
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
```

**Minh chứng Terminal:**
![alt text](images/image-3.png)

---

### 2.3. Thử deploy Pod chạy quyền Root (`runAsUser: 0`)
**Manifest test:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-root-user
  namespace: demo
  labels:
    owner: huan
spec:
  securityContext:
    runAsUser: 0
  containers:
  - name: app
    image: nginx:1.25.0
    resources:
      limits:
        memory: "128Mi"
        cpu: "500m"
```

**Minh chứng Terminal:**
![alt text](images/image-4.png)

---

### 2.4. Thử deploy Pod bật `hostNetwork: true`
**Manifest test:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-host-network
  namespace: demo
  labels:
    owner: huan
spec:
  hostNetwork: true
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

**Minh chứng Terminal:**
![alt text](images/image-5.png)

---

### 2.5. Thử deploy Pod Hợp lệ 100%
**Manifest test:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-valid-pod
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

**Minh chứng Terminal:**
![alt text](images/image-6.png)
