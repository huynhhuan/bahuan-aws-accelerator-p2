output "vpc_id" {
  description = "ID of the challenge VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by EC2 and ALB."
  value       = aws_subnet.public[*].id
}
