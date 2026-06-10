# OpenTelemetry (OTel)

## OpenTelemetry là gì?

OpenTelemetry là tiêu chuẩn mã nguồn mở dùng để thu thập:

- Metrics
- Logs
- Traces

## Kiến trúc

Application
↓
OTel SDK
↓
OTel Collector
↓
Prometheus / Grafana / Jaeger

## Thành phần

### SDK

Được tích hợp vào ứng dụng.

Thu thập dữ liệu quan sát.

### Collector

Trung tâm tiếp nhận và xử lý dữ liệu.

Collector có thể:

- Receive
- Process
- Export

## Lợi ích

- Chuẩn hóa dữ liệu telemetry
- Hỗ trợ đa nền tảng
- Vendor Neutral