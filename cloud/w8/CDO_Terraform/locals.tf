locals {
  name_prefix = "${var.project_name}-${var.environment}"
  azs         = slice(data.aws_availability_zones.available.names, 0, var.availability_zone_count)

  public_subnets   = [for index in range(var.availability_zone_count) : cidrsubnet(var.vpc_cidr, 8, index)]
  private_subnets  = [for index in range(var.availability_zone_count) : cidrsubnet(var.vpc_cidr, 8, index + 10)]
  database_subnets = [for index in range(var.availability_zone_count) : cidrsubnet(var.vpc_cidr, 8, index + 20)]

  assets_bucket_name = coalesce(
    var.assets_bucket_name,
    "${local.name_prefix}-assets-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  )

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.owner == null ? {} : { Owner = var.owner },
    var.tags
  )

  web_user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail

    dnf update -y
    dnf install -y nginx awscli

    cat > /usr/share/nginx/html/index.html <<'HTML'
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>${local.name_prefix}</title>
        <style>
          body { margin: 0; font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: #f7fafc; color: #172033; }
          main { max-width: 760px; margin: 12vh auto; padding: 0 24px; }
          h1 { font-size: 40px; margin-bottom: 12px; }
          p { font-size: 18px; line-height: 1.6; }
          code { background: #e8edf3; padding: 2px 6px; border-radius: 4px; }
        </style>
      </head>
      <body>
        <main>
          <h1>${local.name_prefix}</h1>
          <p>Web server deployed by Terraform on Amazon EC2.</p>
          <p>Static assets bucket: <code>${local.assets_bucket_name}</code></p>
        </main>
      </body>
    </html>
    HTML

    systemctl enable nginx
    systemctl restart nginx
  EOT
}

