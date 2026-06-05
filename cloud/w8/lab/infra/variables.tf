variable "aws_region" {
  description = "AWS region used for the challenge."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Short lowercase name used for AWS resource names and tags."
  type        = string
  default     = "w8-minikube-tf"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,24}$", var.project_name))
    error_message = "project_name must be 3-25 chars, lowercase, and contain only letters, numbers, or hyphens."
  }
}

variable "instance_type" {
  description = "EC2 size for Docker + minikube. t3.medium gives minikube enough memory for a reliable lab run."
  type        = string
  default     = "t3.medium"
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH into EC2 for Terraform remote-exec verification."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_node_port" {
  description = "Kubernetes NodePort forwarded from minikube to the EC2 host, then targeted by ALB."
  type        = number
  default     = 30080

  validation {
    condition     = var.app_node_port >= 30000 && var.app_node_port <= 32767
    error_message = "app_node_port must be in the Kubernetes NodePort range 30000-32767."
  }
}
