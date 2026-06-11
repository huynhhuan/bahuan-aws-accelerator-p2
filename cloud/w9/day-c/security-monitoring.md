# Security Monitoring Best Practices

## Enable CloudTrail ở tất cả Region

Kẻ tấn công có thể lợi dụng Region chưa được giám sát.

---

## Bật GuardDuty

Phát hiện:

- API bất thường
- Credential bị lộ
- Crypto Mining

---

## Giám sát IAM

Cảnh báo khi:

- Tạo User mới
- Tạo Access Key
- Root Login
- Thay đổi Policy

---

## Log Retention

Security Log:

Tối thiểu 1 năm.

Sau 90 ngày có thể chuyển sang Glacier để tiết kiệm chi phí.