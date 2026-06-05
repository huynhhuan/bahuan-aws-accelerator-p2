output "alb_url" {
  description = "Open this URL in a browser for challenge evidence."
  value       = module.alb.url
  depends_on  = [null_resource.wait_for_app]
}

output "alb_healthcheck_url" {
  description = "Health endpoint used by the ALB target group."
  value       = module.alb.healthcheck_url
  depends_on  = [null_resource.wait_for_app]
}

output "instance_public_ip" {
  description = "Public IP of the single EC2 instance running Docker + minikube."
  value       = module.ec2_minikube.public_ip
}

output "private_key_pem" {
  description = "Generated SSH private key, stored in Terraform state. Use only for debugging."
  value       = module.ec2_minikube.private_key_pem
  sensitive   = true
}
