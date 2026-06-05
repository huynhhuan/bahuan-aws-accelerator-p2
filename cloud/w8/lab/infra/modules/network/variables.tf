variable "name" {
  description = "Name prefix for network resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the challenge VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones used for the public subnets."
  type        = list(string)
}

variable "common_tags" {
  description = "Tags applied to all resources."
  type        = map(string)
}
