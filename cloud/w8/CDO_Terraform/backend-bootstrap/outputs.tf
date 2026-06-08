output "state_bucket_name" {
  description = "S3 bucket name for Terraform state."
  value       = module.state_bucket.s3_bucket_id
}

output "lock_table_name" {
  description = "DynamoDB lock table name."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "backend_config" {
  description = "Backend config for terraform init -backend-config=backend.hcl."
  value       = <<-EOT
    bucket         = "${module.state_bucket.s3_bucket_id}"
    key            = "${var.state_key}"
    region         = "${var.aws_region}"
    dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
    encrypt        = true
  EOT
}

