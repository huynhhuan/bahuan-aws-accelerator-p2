resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Allow HTTP from the Internet to the ALB."
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound to EC2 NodePort"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name}-alb-sg"
  })
}

resource "aws_security_group" "ec2" {
  name        = "${var.name}-ec2-sg"
  description = "Allow ALB to reach the minikube NodePort forwarder on EC2."
  vpc_id      = var.vpc_id

  ingress {
    description     = "NodePort from ALB only"
    from_port       = var.app_node_port
    to_port         = var.app_node_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "SSH for Terraform remote-exec verification"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  egress {
    description = "Outbound for package and image downloads"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name}-ec2-sg"
  })
}
