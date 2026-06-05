output "dns_name" {
  description = "DNS name of the public ALB."
  value       = aws_lb.this.dns_name
}

output "url" {
  description = "HTTP URL of the public ALB."
  value       = "http://${aws_lb.this.dns_name}"
}

output "healthcheck_url" {
  description = "HTTP health check URL of the public ALB."
  value       = "http://${aws_lb.this.dns_name}/healthz"
}
