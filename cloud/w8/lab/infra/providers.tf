provider "aws" {
  region = var.aws_region
}

provider "cloudinit" {}
provider "null" {}
provider "tls" {}
