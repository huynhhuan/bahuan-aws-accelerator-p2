output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnets
}

output "database_subnet_ids" {
  description = "Database subnet IDs used by RDS."
  value       = module.vpc.database_subnets
}

output "web_instance_id" {
  description = "EC2 web server instance ID."
  value       = module.web_server.id
}

output "web_public_ip" {
  description = "Public IP address of the web server."
  value       = module.web_server.public_ip
}

output "web_url" {
  description = "HTTP URL for the web server."
  value       = "http://${module.web_server.public_dns}"
}

output "assets_bucket_name" {
  description = "S3 bucket name for static assets."
  value       = module.assets_bucket.s3_bucket_id
}

output "assets_manifest_key" {
  description = "Example static asset object key."
  value       = aws_s3_object.assets_manifest.key
}

output "mysql_endpoint" {
  description = "Private RDS MySQL endpoint."
  value       = module.mysql.db_instance_endpoint
}

output "mysql_master_secret_arn" {
  description = "Secrets Manager secret ARN for the RDS master user password."
  value       = module.mysql.db_instance_master_user_secret_arn
}

