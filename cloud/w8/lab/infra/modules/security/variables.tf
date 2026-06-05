variable "name" {
  description = "Name prefix for security resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups are created."
  type        = string
}

variable "app_node_port" {
  description = "EC2 host port forwarded into minikube NodePort."
  type        = number
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH into EC2."
  type        = list(string)
}

variable "common_tags" {
  description = "Tags applied to all resources."
  type        = map(string)
}
