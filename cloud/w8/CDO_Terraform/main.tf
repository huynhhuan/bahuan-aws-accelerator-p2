module "vpc" {
  source = "./modules/terraform-aws-vpc"

  name = local.name_prefix
  cidr = var.vpc_cidr
  azs  = local.azs

  public_subnets   = local.public_subnets
  private_subnets  = local.private_subnets
  database_subnets = local.database_subnets

  enable_dns_hostnames = true
  enable_dns_support   = true

  map_public_ip_on_launch = true

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  create_database_subnet_group       = true
  create_database_subnet_route_table = true

  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  public_subnet_tags = {
    Tier = "public"
  }

  private_subnet_tags = {
    Tier = "private"
  }

  database_subnet_tags = {
    Tier = "database"
  }

  tags = local.common_tags
}

module "assets_bucket" {
  source = "./modules/terraform-aws-s3-bucket"

  bucket        = local.assets_bucket_name
  force_destroy = var.assets_bucket_force_destroy

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  versioning = {
    status = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.common_tags
}

resource "aws_s3_object" "assets_manifest" {
  bucket                 = module.assets_bucket.s3_bucket_id
  key                    = "manifest.json"
  content_type           = "application/json"
  server_side_encryption = "AES256"

  content = jsonencode({
    project     = var.project_name
    environment = var.environment
    managed_by  = "Terraform"
  })
}

module "web_server" {
  source = "./modules/terraform-aws-ec2-instance"

  name = "${local.name_prefix}-web"

  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.web_instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  create_iam_instance_profile = true
  iam_role_description        = "Least-privilege role for ${local.name_prefix} web server"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AssetsBucketReadOnly         = aws_iam_policy.web_assets_read_only.arn
  }

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring = var.enable_ec2_detailed_monitoring

  root_block_device = {
    encrypted = true
    type      = "gp3"
    size      = var.web_root_volume_size
  }

  user_data                   = local.web_user_data
  user_data_replace_on_change = true

  tags = local.common_tags
}

module "mysql" {
  source = "./modules/terraform-aws-rds"

  identifier = "${local.name_prefix}-mysql"

  engine               = "mysql"
  engine_version       = var.mysql_engine_version
  family               = var.mysql_parameter_group_family
  major_engine_version = var.mysql_major_engine_version
  instance_class       = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_encrypted     = true
  storage_type          = "gp3"

  db_name  = var.db_name
  username = var.db_username
  port     = 3306

  manage_master_user_password = true

  create_db_subnet_group = true
  subnet_ids             = module.vpc.database_subnets

  multi_az               = var.db_multi_az
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.database.id]

  backup_retention_period = var.db_backup_retention_period
  backup_window           = var.db_backup_window
  maintenance_window      = var.db_maintenance_window

  auto_minor_version_upgrade = true
  deletion_protection        = var.db_deletion_protection
  skip_final_snapshot        = var.db_skip_final_snapshot

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  create_cloudwatch_log_group     = true

  performance_insights_enabled = var.db_performance_insights_enabled

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  tags = local.common_tags
}

