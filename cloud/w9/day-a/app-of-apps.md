# App of Apps Pattern

## Vấn đề

Một hệ thống thường gồm nhiều thành phần:

- Frontend
- Backend
- Monitoring
- Logging
- Database

Nếu quản lý từng ứng dụng riêng lẻ sẽ khó mở rộng.

## Giải pháp

Tạo một Application cha.

Application cha quản lý nhiều Application con.

Root Application
├── Frontend
├── Backend
├── Monitoring
└── Logging

## Lợi ích

- Quản lý tập trung
- Dễ mở rộng
- Dễ bảo trì
- Dễ triển khai môi trường mới