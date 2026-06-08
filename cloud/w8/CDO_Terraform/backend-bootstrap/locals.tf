data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  state_bucket_name = coalesce(
    var.state_bucket_name,
    "${local.name_prefix}-tfstate-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  )

  lock_table_name = coalesce(
    var.lock_table_name,
    "${local.name_prefix}-terraform-locks"
  )

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Component   = "terraform-backend"
    },
    var.owner == null ? {} : { Owner = var.owner },
    var.tags
  )
}

