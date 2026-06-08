resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web"
  description = "Web server security group"
  vpc_id      = module.vpc.vpc_id

  revoke_rules_on_delete = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web"
  })
}

resource "aws_vpc_security_group_ingress_rule" "web_http" {
  for_each = toset(var.http_ingress_cidr_blocks)

  security_group_id = aws_security_group.web.id
  description       = "HTTP from approved CIDR ${each.value}"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "web_ssh" {
  for_each = toset(var.ssh_ingress_cidr_blocks)

  security_group_id = aws_security_group.web.id
  description       = "SSH from approved CIDR ${each.value}"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "web_all_ipv4" {
  security_group_id = aws_security_group.web.id
  description       = "Outbound IPv4 for package updates, SSM, and S3 access"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "database" {
  name        = "${local.name_prefix}-mysql"
  description = "MySQL security group"
  vpc_id      = module.vpc.vpc_id

  revoke_rules_on_delete = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-mysql"
  })
}

resource "aws_vpc_security_group_ingress_rule" "database_mysql_from_web" {
  security_group_id            = aws_security_group.database.id
  description                  = "MySQL from web server security group"
  referenced_security_group_id = aws_security_group.web.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
}

