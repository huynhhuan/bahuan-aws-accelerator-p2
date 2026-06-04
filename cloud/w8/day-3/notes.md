# W8 Day 3 - Terraform State, Modules, Best Practices

## Nội dung đã học

- Terraform không chỉ là file `.tf` để tạo resource.
- Terraform cần state để quản lý quan hệ giữa code và hạ tầng thật.
- Local state phù hợp khi học cá nhân, không phù hợp khi làm team.
- Remote state giúp team dùng chung một source of truth.
- State lock giúp tránh nhiều người apply cùng lúc.
- Module giúp chia Terraform theo trách nhiệm.
- ADR giúp ghi lại quyết định kỹ thuật và lý do chọn giải pháp.

## Terraform state

- State là thành phần cốt lõi của Terraform.
- State dùng để:
  - map resource trong code với resource thật trên cloud;
  - biết resource nào cần tạo mới;
  - biết resource nào cần sửa;
  - biết resource nào cần xóa;
  - lưu metadata và output;
  - so sánh desired state với actual state.
- Điểm cần nhớ:
  - không commit `terraform.tfstate` lên Git;
  - state có thể chứa thông tin nhạy cảm;
  - mất state có thể khiến Terraform không quản lý được resource đã tạo;
  - nhiều người dùng local state riêng dễ gây lệch hạ tầng.

## Remote state với S3 và DynamoDB lock

- Pattern phổ biến trên AWS:
  - S3 bucket lưu state;
  - DynamoDB table lock state.
- S3 remote state:
  - lưu state tập trung;
  - tránh phụ thuộc máy cá nhân;
  - giúp team dùng chung state.
- DynamoDB lock:
  - khóa state khi đang apply;
  - tránh hai lần apply ghi state cùng lúc;
  - giảm rủi ro race condition.
- Best practices:
  - bật versioning cho S3 bucket;
  - bật encryption;
  - giới hạn IAM permission;
  - không public bucket state;
  - dùng lock khi có nhiều người apply.

## Terraform modules

- Root module:
  - thư mục Terraform chính;
  - nơi chạy `terraform init`, `terraform plan`, `terraform apply`.
- Child module:
  - module được gọi bằng block `module`;
  - nhận input qua variables;
  - trả output qua outputs.
- Module nên tách theo trách nhiệm:

```text
network module  -> VPC, subnet, route table
security module -> security groups
compute module  -> EC2
alb module      -> ALB, target group, listener
```

- Nên tách module khi:
  - giảm lặp lại;
  - làm rõ trách nhiệm;
  - dễ tái sử dụng;
  - dễ review;
  - dễ maintain.
- Không nên tách module chỉ để project trông phức tạp.
- Module quá nhỏ làm project bị vụn.
- Module quá lớn làm project khó hiểu và khó tái sử dụng.

## Terraform best practices

- Chạy `terraform fmt`.
- Chạy `terraform validate`.
- Chạy `terraform plan` trước khi apply.
- Đọc kỹ plan trước khi approve.
- Dùng variables cho giá trị có thể thay đổi:
  - region;
  - instance type;
  - CIDR;
  - project name;
  - tags.
- Dùng outputs cho thông tin cần lấy sau khi apply.
- Gắn tag cho resource.
- Không commit:
  - state file;
  - private key;
  - secret;
  - file `.tfvars` chứa thông tin nhạy cảm.
- Tách môi trường bằng:
  - `tfvars`;
  - folder;
  - workspace nếu phù hợp.
