# Kubernetes Role-Based Access Control (RBAC)

## 1. Khái niệm cốt lõi trong Kubernetes RBAC

Cơ chế RBAC của Kubernetes cho phép phân quyền truy cập vào API Server dựa trên vai trò của người dùng hoặc ứng dụng trong hệ thống. Hệ thống RBAC bao gồm các thực thể chính sau:

### 1.1. Role vs ClusterRole
*   **Role (Namespaced Resource):**
    *   Được định nghĩa trong phạm vi một Namespace cụ thể.
    *   Chỉ áp dụng để phân quyền cho các tài nguyên nằm trong Namespace đó (ví dụ: Pods, Services, Deployments).
    *   **Khi nào dùng:** Khi bạn chỉ muốn phân quyền cho một ứng dụng hoặc nhóm phát triển làm việc trong một phân vùng logic duy nhất.
*   **ClusterRole (Cluster-scoped Resource):**
    *   Được định nghĩa trên phạm vi toàn bộ Cluster (không bị giới hạn bởi Namespace).
    *   Có thể được sử dụng để phân quyền cho các tài nguyên không thuộc Namespace (như Nodes, PersistentVolumes, Namespaces) hoặc phân quyền cho các tài nguyên Namespaced trên tất cả các Namespace hiện có hoặc tương lai.
    *   Cũng có thể dùng để định nghĩa các quyền chung rồi liên kết vào Namespace cụ thể bằng RoleBinding để tiết kiệm công sức khai báo.
    *   **Khi nào dùng:** Khi cần phân quyền truy cập tài nguyên hệ thống (Cluster-level) hoặc quản trị viên hệ thống.

### 1.2. RoleBinding vs ClusterRoleBinding
*   **RoleBinding (Namespaced Resource):**
    *   Liên kết một `Role` hoặc `ClusterRole` với một danh sách các đối tượng (`Subject` bao gồm Users, Groups, ServiceAccounts) trong phạm vi một Namespace cụ thể.
    *   Nếu liên kết một `ClusterRole` thông qua `RoleBinding`, các quyền trong `ClusterRole` đó sẽ chỉ có hiệu lực bên trong Namespace của `RoleBinding`.
*   **ClusterRoleBinding (Cluster-scoped Resource):**
    *   Liên kết một `ClusterRole` với danh sách các đối tượng (`Subject`) trên toàn bộ Cluster.
    *   Quyền hạn được cấp thông qua `ClusterRoleBinding` sẽ có hiệu lực đối với mọi tài nguyên ở cấp Cluster và trên tất cả các Namespace.

### 1.3. ServiceAccounts
*   Trong Kubernetes, định danh (Identity) được chia làm hai loại:
    1.  **User Accounts:** Dành cho con người (quản trị viên, lập trình viên) được xác thực qua các cơ chế bên ngoài (OIDC, X.509 Client Certificates...). Kubernetes không trực tiếp lưu trữ tài nguyên User.
    2.  **ServiceAccounts (Namespaced Resource):** Dành cho ứng dụng hoặc các tiến trình chạy bên trong Pod để giao tiếp an toàn với Kubernetes API Server.
*   Mỗi Pod khi chạy có thể được gán một `ServiceAccount`. Nếu không được chỉ định, Pod sẽ mặc định sử dụng ServiceAccount `default` của Namespace đó.

---

## 2. Các nguyên tắc bảo mật tốt nhất (Security Best Practices)

### 2.1. Nguyên tắc đặc quyền tối thiểu (Least Privilege)
*   Chỉ cấp những quyền tối thiểu cần thiết cho ứng dụng để hoàn thành công việc của nó.
*   **Tránh sử dụng dấu hoa thị (`*`)** trong phần `resources` hoặc `verbs` của Role trừ khi thực sự cần thiết. Ví dụ, thay vị cấp quyền `*` trên `pods`, chỉ cấp `get, list, watch`.
*   Hạn chế tối đa việc phân quyền cho ServiceAccount mặc định (`default`) của Namespace. Hãy tạo ServiceAccount riêng biệt cho từng ứng dụng.

### 2.2. ServiceAccount Token Volume Projection (Token Gắn kết An toàn)
*   Từ Kubernetes 1.22+, cơ chế `ServiceAccountIssuerDiscovery` đã được mặc định bật. Thay vì lưu token vĩnh viễn trong Secret và tự động gắn vào Pod, Kubernetes khuyến khích sử dụng **Token Volume Projection**.
*   Token này có thời gian hết hạn (expirationSeconds), tự động xoay vòng (auto-rotated) và liên kết chặt chẽ với vòng đời của Pod.
*   Cấu hình mẫu trong Pod Spec:
    ```yaml
    spec:
      containers:
      - name: my-app
        image: my-app-image:v1
        volumeMounts:
        - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
          name: kube-api-access
          readOnly: true
      volumes:
      - name: kube-api-access
        projected:
          defaultMode: 420
          sources:
          - serviceAccountToken:
              expirationSeconds: 3600
              path: token
          - configMap:
              items:
              - key: ca.crt
                path: ca.crt
              name: kube-root-ca.crt
          - downwardAPI:
              items:
              - fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.namespace
                path: namespace
    ```

### 2.3. Hạn chế tự động Mount Token (`automountServiceAccountToken: false`)
*   Nếu một ứng dụng chạy trong Pod không cần giao tiếp trực tiếp với Kubernetes API Server, hãy tắt tính năng tự động mount token bằng cách đặt `automountServiceAccountToken: false` trong cấu hình của `ServiceAccount` hoặc `Pod`.

### 2.4. Khớp quyền hạn không chạy quyền Root (runAsNonRoot Mapping)
*   Để tăng cường bảo mật, luôn chạy container với tài khoản phi-root (non-root) và hạn chế ServiceAccount được liên kết với các chính sách có đặc quyền cao như `hostPath` mount, `privileged: true`.

---

## 3. Ví dụ cấu hình YAML Manifest

Dưới đây là các manifest mẫu hoàn chỉnh để thiết lập ServiceAccount, Role, và RoleBinding nhằm phân quyền cho một ứng dụng đọc thông tin Pod trong Namespace `production`.

### 3.1. Khai báo ServiceAccount (`serviceaccount.yaml`)
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: production
automountServiceAccountToken: true
```

### 3.2. Khai báo Role (`role.yaml`)
Role này có tên `pod-reader`, cho phép đọc dữ liệu Pod (verbs: `get`, `watch`, `list`) trong namespace nơi nó được triển khai.
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: production
rules:
- apiGroups: [""] # "" đại diện cho core API group
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

### 3.3. Khai báo RoleBinding (`rolebinding.yaml`)
Liên kết Role `pod-reader` với ServiceAccount `app-sa` trong namespace `production`.
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: production
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

---

## 4. Hướng dẫn sử dụng `kubectl auth can-i` để kiểm tra phân quyền

Lệnh `kubectl auth can-i` là một công cụ mạnh mẽ dành cho DevOps/SRE để kiểm tra quyền hạn của mình hoặc giả lập (impersonate) quyền hạn của một User, Group hoặc ServiceAccount khác mà không cần thay đổi cấu hình kubeconfig.

### 4.1. Kiểm tra quyền của tài khoản hiện tại
*   Kiểm tra xem bạn có thể tạo Pod trong namespace hiện tại hay không:
    ```bash
    kubectl auth can-i create pods
    ```
    *Phản hồi mẫu:* `yes` hoặc `no`

*   Kiểm tra xem bạn có thể liệt kê tất cả các Deployment trên toàn bộ Cluster hay không:
    ```bash
    kubectl auth can-i list deployments --all-namespaces
    ```

### 4.2. Giả lập ServiceAccount để kiểm tra quyền (`--as`)
Để kiểm tra xem một `ServiceAccount` cụ thể có các quyền chính xác hay không, bạn sử dụng định dạng `--as=system:serviceaccount:<namespace>:<serviceaccount-name>`.

*   Kiểm tra xem ServiceAccount `app-sa` trong namespace `production` có thể đọc Pods trong cùng namespace đó hay không:
    ```bash
    kubectl auth can-i list pods --namespace=production --as=system:serviceaccount:production:app-sa
    ```
    *Phản hồi mong đợi:* `yes` (vì đã được gán thông qua RoleBinding ở trên)

*   Kiểm tra xem ServiceAccount `app-sa` có thể tạo Deployments trong namespace `production` hay không:
    ```bash
    kubectl auth can-i create deployments --namespace=production --as=system:serviceaccount:production:app-sa
    ```
    *Phản hồi mong đợi:* `no` (vì Role `pod-reader` chỉ cho phép `get`, `list`, `watch` trên tài nguyên `pods`)

*   Kiểm tra xem ServiceAccount `app-sa` có thể đọc Pods ở namespace khác (ví dụ: `default`) hay không:
    ```bash
    kubectl auth can-i list pods --namespace=default --as=system:serviceaccount:production:app-sa
    ```
    *Phản hồi mong đợi:* `no` (vì RoleBinding chỉ ràng buộc trong namespace `production`)

### 4.3. Giả lập User hoặc Group khác
*   Kiểm tra xem một user tên là `alice` có quyền xóa namespace hay không:
    ```bash
    kubectl auth can-i delete namespaces --as=alice
    ```

*   Kiểm tra xem một group tên là `developers` có quyền chỉnh sửa Service hay không:
    ```bash
    kubectl auth can-i update services --as-group=developers
    ```

Sử dụng thành thạo `kubectl auth can-i` giúp đảm bảo các chính sách RBAC được thiết lập đúng đắn và an toàn trước khi vận hành thực tế.
