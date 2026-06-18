# Hướng Dẫn Từng Bước Lab W10 - Progressive Delivery & Analysis

Chào bạn, dưới đây là hướng dẫn chi tiết từng bước để làm bài lab W10. Mình đã gom lại thành các quy trình rõ ràng và **đặc biệt làm nổi bật những vị trí bạn bắt buộc phải sửa đổi** trước khi và trong khi chạy bài Lab.

---

> [!IMPORTANT]
> ## 🚨 NHỮNG CHỖ BẠN BẮT BUỘC PHẢI SỬA
>
> 1. **Cập nhật đường dẫn `repoURL` (Rất Quan Trọng)**
>    Hiện tại, tất cả các file cấu hình của ArgoCD trong bài đang trỏ đến một repository mẫu (`https://github.com/Vuong-Bach/temp.git`). Bạn **bắt buộc** phải tìm và thay thế chuỗi này thành URL Git Repository của bạn (ví dụ: `https://github.com/<USERNAME>/<REPO_NAME>.git`).
>    **Các file cần sửa `repoURL`:**
>    - [argocd/root.yaml](file:///d:/xbrain/Phase_2/cloud/W10/lab/argocd/root.yaml)
>    - [argocd/apps/app-alert.yaml](file:///d:/xbrain/Phase_2/cloud/W10/lab/argocd/apps/app-alert.yaml)
>    - [argocd/apps/app-analysis.yaml](file:///d:/xbrain/Phase_2/cloud/W10/lab/argocd/apps/app-analysis.yaml)
>    - [argocd/apps/app-api.yaml](file:///d:/xbrain/Phase_2/cloud/W10/lab/argocd/apps/app-api.yaml)
>    - [argocd/apps/app-common.yaml](file:///d:/xbrain/Phase_2/cloud/W10/lab/argocd/apps/app-common.yaml)
>    - *(Cả các file `k8s-prometheus.yaml` và `k8s-rollout.yaml` trong thư mục `argocd/apps/` nếu chúng có chứa `repoURL` mẫu).*
> 
> 2. **Cập nhật đường dẫn `path` (Quan Trọng không kém)**
>    Vì repository của bạn có cấu trúc thư mục chứa bài lab nằm sâu bên trong (cụ thể là `cloud/W10/lab/...`), các biến `path` trong cấu hình ArgoCD cũng phải được trỏ đúng đường dẫn tương đối từ gốc repo.
>    *(💡 Mình vừa giúp bạn chạy tool tự động cập nhật tất cả các đường dẫn `path` trong thư mục `argocd/` này thành `cloud/W10/lab/...` rồi, nên bạn không cần sửa lại nữa!)*
> 
> 3. **Cấu hình Email nhận Cảnh báo (Alerts)**
>    Để nhận email khi API gặp lỗi, bạn cần tạo file chứa thông tin Email và App Password.
>    - Bạn cần copy file mẫu thành file thật: 
>      `cp app-alert/email-secret.yaml.example app-alert/email-secret.yaml`
>    - Mở file `app-alert/email-secret.yaml` vừa tạo và **sửa**: điền địa chỉ Email của bạn và [Mật khẩu ứng dụng Gmail (App Password)](https://myaccount.google.com/apppasswords).
>
> 3. **Thay đổi thông số Lỗi (ERROR_RATE) khi Test GitOps**
>    Trong quá trình chạy kiểm thử (Bước 5), bạn sẽ phải sửa giá trị của biến `ERROR_RATE` bên trong file:
>    - [app-api/rollout.yaml](file:///d:/xbrain/Phase_2/cloud/W10/lab/app-api/rollout.yaml)

---

## 💻 CÁC BƯỚC THỰC HÀNH CHI TIẾT

### Bước 1: Chuẩn bị Code & Đẩy lên GitHub của bạn
Vì ArgoCD (GitOps) tự động theo dõi repository để triển khai, bạn cần đẩy code lên repo của chính mình.
1. Tạo một repository mới trên GitHub (VD: `w10-progressive-delivery`).
2. Sửa toàn bộ đường dẫn `repoURL` trong các file YAML trong thư mục `argocd/` (như đã nhắc ở phần trên) thành URL repo bạn vừa tạo.
3. Commit và Push code lên nhánh `main`:
   ```bash
   git init
   git add .
   git commit -m "Init repo and update repoURL"
   git branch -M main
   git remote add origin <URL_REPO_CỦA_BẠN>
   git push -u origin main
   ```

### Bước 2: Khởi tạo Cụm (Cluster) & Cài đặt ArgoCD
Mở terminal và chạy lần lượt các lệnh sau:
1. Tạo cluster Minikube:
   ```bash
   minikube start -p w10 --driver=docker
   kubectl config use-context w10
   ```
2. Cài đặt ArgoCD:
   ```bash
   kubectl create ns argocd
   kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```
3. Chờ cho ArgoCD khởi động hoàn tất:
   ```bash
   kubectl -n argocd rollout status deploy/argocd-server
   ```

### Bước 3: Đăng nhập giao diện ArgoCD
1. Chạy lệnh Port-forward (lệnh này sẽ treo trên terminal, hãy mở thêm một tab terminal khác để làm tiếp):
   ```bash
   kubectl -n argocd port-forward svc/argocd-server 8080:443
   ```
2. Ở tab terminal mới, chạy lệnh sau để lấy mật khẩu `admin` của ArgoCD (dành cho Windows PowerShell):
   ```powershell
   $pwd64 = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
   [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($pwd64))
   ```
3. Mở trình duyệt, truy cập `https://localhost:8080`, đăng nhập bằng username `admin` và mật khẩu vừa lấy.

### Bước 4: Khởi chạy GitOps & Alert Secret
1. Cài đặt Email Secret cho cảnh báo:
   ```bash
   # Nếu chưa tạo file, nhớ copy và sửa thông tin email trước:
   # cp app-alert/email-secret.yaml.example app-alert/email-secret.yaml
   
   kubectl create namespace monitoring
   kubectl apply -f app-alert/email-secret.yaml
   ```
2. Triển khai cấu hình "App of Apps":
   ```bash
   kubectl apply -f argocd/root.yaml
   ```
   > [!NOTE]
   > Hãy quay lại trình duyệt xem giao diện ArgoCD, bạn sẽ thấy các ứng dụng dần được tạo và quá trình đồng bộ (Sync) bắt đầu chạy qua từng đợt (Waves). Quá trình này có thể mất vài phút.

### Bước 5: Kiểm thử Hệ thống (Test Scenarios)
Trong GitOps, mỗi lần bạn muốn hệ thống thay đổi, bạn sửa code -> commit -> push. ArgoCD sẽ tự cập nhật.

Mở một terminal khác và theo dõi quá trình chạy bằng 2 lệnh này:
```bash
kubectl get rollout api -n demo -w
# Khi có tiến trình analysis chạy, xem chi tiết bằng:
# kubectl get analysisrun -n demo -w
```

Bạn hãy thực hành 3 kịch bản bằng cách thay đổi giá trị `ERROR_RATE` trong file `app-api/rollout.yaml` rồi push lên Github:

1. **Test Thành công (Tỷ lệ lỗi 0%)**
   - Sửa file `app-api/rollout.yaml`: Đổi `ERROR_RATE: "0"`.
   - Lưu file, commit và `git push`.
   - Kết quả: Tiến trình AnalysisRun báo `Successful`, Rollout tiến hành thành công lên 100%.

2. **Test Thất bại & Tự động Rollback (Tỷ lệ lỗi 15%)**
   - Sửa file `app-api/rollout.yaml`: Đổi `ERROR_RATE: "0.15"`.
   - Lưu file, commit và `git push`.
   - Kết quả: Success Rate < 90%. AnalysisRun báo `Failed`. Argo Rollout lập tức chặn lại và tự động trả hệ thống về (Rollback) bản cập nhật ổn định trước đó.

3. **Test Cảnh báo SLO Email (Tỷ lệ lỗi 10%)**
   - Sửa file `app-api/rollout.yaml`: Đổi `ERROR_RATE: "0.10"`.
   - Lưu file, commit và `git push`.
   - Kết quả: Mức lỗi 10% (Success Rate 90%) vừa đủ để qua được đợt kiểm tra Canary, nhưng nó vi phạm SLO (yêu cầu > 95%). Đợi 2-3 phút, bạn hãy vào hòm thư Email đã cài đặt để nhận email cảnh báo tự động gửi về.

### Bước 6: Dọn Dẹp (Cleanup)
Sau khi thực hành xong, bạn xóa môi trường đi để tránh tốn tài nguyên máy:
```bash
minikube stop -p w10
minikube delete -p w10
```
