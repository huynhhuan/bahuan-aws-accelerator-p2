# Trace, Segment và Subsegment

## Trace

Là toàn bộ hành trình của một request.

Ví dụ:

User
↓
API Gateway
↓
Lambda
↓
RDS
↓
Response

Toàn bộ luồng trên được gọi là một Trace.

---

## Segment

Mỗi service đóng góp một Segment.

Ví dụ:

API Gateway Segment

Lambda Segment

RDS Segment

---

## Subsegment

Là một phần nhỏ bên trong Segment.

Ví dụ:

Lambda
 ├── SQL Query
 ├── HTTP Call
 └── S3 Upload

Mỗi thao tác trên có thể là một Subsegment.

---

## Ghi nhớ

Trace > Segment > Subsegment