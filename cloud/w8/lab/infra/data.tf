data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "cloudinit_config" "minikube_bootstrap" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
      app_manifest = replace(templatefile("${path.module}/k8s/app.yaml.tftpl", {
        project_name = var.project_name
        node_port    = var.app_node_port
      }), "\n", "\n      ")
      cluster_name = local.name
      node_port    = var.app_node_port
    })
  }
}
