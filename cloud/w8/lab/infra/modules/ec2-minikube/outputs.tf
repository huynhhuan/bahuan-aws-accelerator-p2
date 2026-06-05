output "instance_id" {
  description = "ID of the EC2 instance running minikube."
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance running minikube."
  value       = aws_instance.this.public_ip
}

output "private_key_pem" {
  description = "Generated SSH private key, stored in Terraform state."
  value       = tls_private_key.generated.private_key_pem
  sensitive   = true
}
