# AWS X-Ray

## AWS X-Ray là gì?

AWS X-Ray là dịch vụ Distributed Tracing giúp theo dõi toàn bộ hành trình của một request khi đi qua nhiều thành phần trong hệ thống.

X-Ray giúp trả lời:

- Request chậm ở đâu?
- Service nào gây lỗi?
- Database có phải là nút thắt cổ chai không?

## Mục tiêu

Trong hệ thống microservices, log thường nằm rải rác ở nhiều service.

X-Ray gom toàn bộ hành trình request lại thành một trace duy nhất.

## Lợi ích

- Dễ debug
- Phát hiện bottleneck
- Quan sát toàn hệ thống
- Hỗ trợ tối ưu hiệu năng

# Service Map

## Service Map là gì?

Service Map là sơ đồ tự động do X-Ray tạo ra.

Hiển thị:

- Các service
- Kết nối giữa các service
- Độ trễ
- Lỗi

## Ví dụ

Browser
↓
API Gateway
↓
Auth Lambda
↓
Order Service
↓
DynamoDB
↓
SNS

## Lợi ích

- Khám phá kiến trúc thực tế
- Phát hiện điểm lỗi
- Phân tích luồng request

## Bottleneck

Nếu Order Service mất 280ms trong khi các thành phần khác chỉ vài chục ms thì Order Service là bottleneck.