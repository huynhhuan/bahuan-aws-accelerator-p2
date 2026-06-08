variable "aws_region" {
  description = "AWS region for the backend resources."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Short project slug used in backend resource names."
  type        = string
  default     = "webapp"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,23}$", var.project_name))
    error_message = "project_name must be 2-24 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,15}$", var.environment))
    error_message = "environment must be 2-16 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "owner" {
  description = "Optional owner tag value."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags applied to backend resources."
  type        = map(string)
  default     = {}
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state. Defaults to account/region-based name."
  type        = string
  default     = null
}

variable "state_bucket_force_destroy" {
  description = "Allow Terraform to delete all objects and versions in the state bucket during destroy. Enable only when cleaning up the lab."
  type        = bool
  default     = false
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking."
  type        = string
  default     = null
}

variable "state_key" {
  description = "S3 object key used by the main stack backend."
  type        = string
  default     = "final-project/dev/terraform.tfstate"
}
