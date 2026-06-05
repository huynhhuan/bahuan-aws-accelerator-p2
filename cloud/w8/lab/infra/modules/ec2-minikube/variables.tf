variable "name" {
  description = "Name prefix for EC2 resources."
  type        = string
}

variable "ami_id" {
  description = "AMI ID used for the minikube EC2 instance."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID where EC2 is launched."
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs attached to EC2."
  type        = list(string)
}

variable "user_data" {
  description = "Rendered cloud-init user-data."
  type        = string
}

variable "common_tags" {
  description = "Tags applied to all resources."
  type        = map(string)
}
