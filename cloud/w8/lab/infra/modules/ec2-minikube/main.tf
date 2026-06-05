resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated" {
  key_name   = "${var.name}-key"
  public_key = tls_private_key.generated.public_key_openssh

  tags = merge(var.common_tags, {
    Name = "${var.name}-key"
  })
}

resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated.key_name
  vpc_security_group_ids      = var.security_group_ids

  user_data                   = var.user_data
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    delete_on_termination = true
    volume_size           = 20
    volume_type           = "gp3"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name}-ec2-minikube"
  })
}
