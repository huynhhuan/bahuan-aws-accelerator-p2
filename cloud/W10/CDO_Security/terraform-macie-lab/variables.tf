variable "aws_region" {
  description = "AWS Region to deploy the lab resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "alert_email" {
  description = "The email address to receive Macie alerts from SNS"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket to create (must be globally unique)"
  type        = string
  default     = "macie-lab-data-terraform-run-1"
}
