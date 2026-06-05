variable "name" {
  description = "Name prefix for ALB resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the target group is created."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs attached to ALB."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID attached to ALB."
  type        = string
}

variable "target_instance_id" {
  description = "EC2 instance ID registered as the ALB target."
  type        = string
}

variable "target_port" {
  description = "EC2 host port forwarding traffic to minikube NodePort."
  type        = number
}

variable "common_tags" {
  description = "Tags applied to all resources."
  type        = map(string)
}
