# Amazon EventBridge

## EventBridge là gì?

EventBridge là Event Bus serverless của AWS.

Cho phép định tuyến sự kiện đến các dịch vụ khác nhau.

## Nguồn sự kiện

- EC2 State Change
- CloudTrail Event
- S3 Event
- Schedule (Cron)
- Custom Application Event

## Đích đến

- SNS
- Lambda
- SQS
- Step Functions
- ECS

## Luồng hoạt động

Event
↓
EventBridge Rule
↓
Target Service

## Ví dụ

EC2 Stop
↓
EventBridge
↓
SNS
↓
Gửi Email cho Admin