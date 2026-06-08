variable "aws_region" {
  description = "AWS region used for all resources."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Short project slug used in resource names."
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
  description = "Additional tags applied to all supported resources."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone_count" {
  description = "Number of Availability Zones to use."
  type        = number
  default     = 2

  validation {
    condition     = var.availability_zone_count >= 2 && var.availability_zone_count <= 3
    error_message = "availability_zone_count must be 2 or 3."
  }
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateway routes for private subnets."
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Whether to use one shared NAT Gateway instead of one per AZ when enable_nat_gateway is true."
  type        = bool
  default     = true
}

variable "http_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the web server on HTTP/80."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the web server on SSH/22. Leave empty and use SSM Session Manager."
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "Optional EC2 key pair name. Not required when using SSM Session Manager."
  type        = string
  default     = null
}

variable "web_instance_type" {
  description = "EC2 instance type for the web server."
  type        = string
  default     = "t3.micro"
}

variable "web_root_volume_size" {
  description = "Root EBS volume size in GiB for the web server."
  type        = number
  default     = 10
}

variable "enable_ec2_detailed_monitoring" {
  description = "Whether to enable detailed monitoring for the EC2 instance."
  type        = bool
  default     = false
}

variable "assets_bucket_name" {
  description = "Globally unique S3 bucket name for static assets. Defaults to a deterministic account/region-based name."
  type        = string
  default     = null
}

variable "assets_bucket_force_destroy" {
  description = "Whether Terraform can delete the assets bucket even when it contains objects."
  type        = bool
  default     = false
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "mysql_engine_version" {
  description = "MySQL engine version."
  type        = string
  default     = "8.0"
}

variable "mysql_major_engine_version" {
  description = "MySQL major engine version for the option group."
  type        = string
  default     = "8.0"
}

variable "mysql_parameter_group_family" {
  description = "MySQL parameter group family."
  type        = string
  default     = "mysql8.0"
}

variable "db_allocated_storage" {
  description = "Initial RDS storage size in GiB."
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum RDS autoscaled storage size in GiB."
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Initial MySQL database name."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "RDS master username. Password is managed by AWS Secrets Manager."
  type        = string
  default     = "appadmin"
}

variable "db_multi_az" {
  description = "Whether to enable Multi-AZ for RDS."
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Number of days to retain RDS backups."
  type        = number
  default     = 7
}

variable "db_backup_window" {
  description = "Daily RDS backup window in UTC."
  type        = string
  default     = "03:00-04:00"
}

variable "db_maintenance_window" {
  description = "Weekly RDS maintenance window in UTC."
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "db_deletion_protection" {
  description = "Whether deletion protection is enabled for RDS."
  type        = bool
  default     = true
}

variable "db_skip_final_snapshot" {
  description = "Whether to skip the final RDS snapshot during destroy."
  type        = bool
  default     = false
}

variable "db_performance_insights_enabled" {
  description = "Whether to enable RDS Performance Insights."
  type        = bool
  default     = false
}
