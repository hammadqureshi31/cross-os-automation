module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr            = var.vpc_cidr
  environment         = var.environment
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
}

module "security_group" {
  source = "../../modules/security_group"

  vpc_id      = module.vpc.vpc_id
  environment = "dev"
}

module "ec2" {
  source = "../../modules/ec2"

  ami_id             = var.ami_id
  instance_type      = var.instance_type
  subnet_id          = module.vpc.public_subnet_id
  security_group_ids = [module.security_group.security_group_id]
  key_name           = var.key_name
  instance_name      = "dev-ec2"
}