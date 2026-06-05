module "network" {
  source = "./modules/network"

  name               = local.name
  common_tags        = local.common_tags
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "security" {
  source = "./modules/security"

  name            = local.name
  vpc_id          = module.network.vpc_id
  app_node_port   = var.app_node_port
  ssh_cidr_blocks = var.ssh_cidr_blocks
  common_tags     = local.common_tags
}

module "ec2_minikube" {
  source = "./modules/ec2-minikube"

  name               = local.name
  ami_id             = data.aws_ami.ubuntu.id
  instance_type      = var.instance_type
  subnet_id          = module.network.public_subnet_ids[0]
  security_group_ids = [module.security.ec2_security_group_id]
  user_data          = data.cloudinit_config.minikube_bootstrap.rendered
  common_tags        = local.common_tags

  depends_on = [module.network]
}

module "alb" {
  source = "./modules/alb"

  name                  = local.name
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  target_instance_id    = module.ec2_minikube.instance_id
  target_port           = var.app_node_port
  common_tags           = local.common_tags
}
