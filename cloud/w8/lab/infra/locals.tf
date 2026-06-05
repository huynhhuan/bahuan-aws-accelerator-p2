locals {
  name = var.project_name

  common_tags = {
    ManagedBy = "Terraform"
    Phase     = "W8"
    Project   = var.project_name
  }
}
