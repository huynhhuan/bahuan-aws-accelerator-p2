# Observability

## Observability là gì?

Observability là khả năng hiểu được trạng thái bên trong của hệ thống thông qua dữ liệu được thu thập từ bên ngoài.

Mục tiêu:

- Biết hệ thống có khỏe không
- Biết nguyên nhân gây lỗi
- Giảm thời gian xử lý sự cố

## 3 trụ cột của Observability

### Metrics

Dữ liệu dạng số.

Ví dụ:

- CPU Utilization
- Memory Usage
- Request Count
- Response Time

### Logs

Bản ghi sự kiện xảy ra trong hệ thống.

Ví dụ:

- User Login
- API Error
- Database Connection Failed

### Traces

Theo dõi đường đi của request.

Ví dụ:

User
↓
API Gateway
↓
Backend Service
↓
Database

## Lợi ích

- Giảm MTTR
- Dễ phân tích nguyên nhân gốc
- Nâng cao độ tin cậy hệ thống