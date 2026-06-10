# Loki

## Loki là gì?

Loki là hệ thống quản lý log của Grafana.

## Thành phần

Application
↓
Promtail
↓
Loki
↓
Grafana

## Đặc điểm

- Chi phí thấp
- Tối ưu cho Kubernetes
- Tích hợp tốt với Grafana

## Truy vấn log

Ví dụ:

{app="backend"}

Tìm log của backend service.

## Lợi ích

- Tập trung log
- Dễ tìm kiếm
- Hỗ trợ điều tra sự cố