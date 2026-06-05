output "alb_security_group_id" {
  description = "Security group ID attached to ALB."
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "Security group ID attached to EC2."
  value       = aws_security_group.ec2.id
}
