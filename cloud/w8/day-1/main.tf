provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_instance" "demo" {
  ami           = "ami-0543dbdaf4e114be7"
  instance_type = "t2.micro"

  tags = {
    Name = "terraform-demo"
  }
}