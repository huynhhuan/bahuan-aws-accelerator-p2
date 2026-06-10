# Prometheus

## Prometheus là gì?

Prometheus là hệ thống thu thập và lưu trữ Metrics.

## Cách hoạt động

Prometheus chủ động kéo dữ liệu.

Prometheus
↓
Scrape
↓
Application Metrics Endpoint

Ví dụ:

/metrics

## Dữ liệu thường thu thập

- CPU
- Memory
- Request Count
- Error Count
- Latency

## PromQL

Ngôn ngữ truy vấn của Prometheus.

Ví dụ:

rate(http_requests_total[5m])

Ý nghĩa:

Số request mỗi giây trong 5 phút gần nhất.