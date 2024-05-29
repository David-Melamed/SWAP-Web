locals {
    app_name = "swapapp"
    env         = "dev"
    application_version = "1.943"
    db_name     = "my_application"
    db_username = "root"
    db_password = "password"
    rds_instance_class = "db.t3.micro"
    zone_name   = "swapapp.net"
}

module "vpc" {
  source                  = "./modules/vpc"
  tags                    = var.tags
  instance_tenancy        = var.instance_tenancy
  vpc_cidr                = var.vpc_cidr
  public_sn_count         = var.public_sn_count
  public_cidrs            = var.public_cidrs
  rt_route_cidr_block     = var.rt_route_cidr_block
  sg_name                 = "${local.app_name}-${local.env}-sg"
  enable_dns_hostnames    = var.enable_dns_hostnames
  map_public_ip_on_launch = var.map_public_ip_on_launch
}

module "iam" {
  source                  = "./modules/iam"
  assume_role_policy_file = "./modules/iam/json/iam_role_policy.json"
  assume_policy_file      = "./modules/iam/json/iam_policy.json"
  assume_ebs_ec2_file     = "./modules/iam/json/aws-elasticbeamstalk-ec2-role.json"
  role_name               = "${local.app_name}-${local.env}-role"
}

module "rds" {
  source                = "./modules/rds"
  allocated_storage     = var.allocated_storage
  engine                = var.engine
  engine_version        = var.engine_version
  instance_class        = local.rds_instance_class
  username              = local.db_username
  password              = local.db_password
  db_name               = local.db_name
  skip_final_snapshot   = var.skip_final_snapshot
  subnet_name           = module.vpc.sg_name
  subnet_ids            = module.vpc.subnet_ids
  vpc_security_group_id = module.vpc.security_group_id
  vpc_id                = module.vpc.vpc_id
  instance_private_ips  = module.beanstalk.instance_private_ips
  private_subnet_ids    = module.vpc.private_subnet_ids
  public_subnet_ids     = module.vpc.public_subnet_ids
}

module "route53_zone" {
  source    = "./modules/route53/zone"
  zone_name = local.zone_name
  vpc_id    = module.vpc.vpc_id
}

module "route53_rds_record" {
  source          = "./modules/route53/rds_record"
  rds_record_name = "rds-${local.env}"
  zone_name       = module.route53_zone.zone_name
  rds_address     = module.rds.db_endpoint
  zone_id         = module.route53_zone.zone_id
}

module "route53_registered_domains" {
  source                = "./modules/route53/registered_domains"
  zone_name             = module.route53_zone.zone_name
  zone_id               = module.route53_zone.zone_id
  zone_web_name_servers = module.route53_zone.name_servers
}

module "acm" {
  source      = "./modules/acm"
  domain_name = module.route53_zone.zone_name
  zone_id     = module.route53_zone.zone_id
}

module "beanstalk" {
  source                    = "./modules/beanstalk"
  ebs_app_name              = "${local.app_name}-${local.env}"
  ebs_app_description       = var.ebs_app_description
  solution_stack_name       = var.solution_stack_name
  env                       = local.env
  service_role_name         = var.service_role_name
  instance_type             = var.instance_type
  bucket_name               = "${local.app_name}-${local.env}-bucket"
  application_version       = local.application_version
  ssh_public_key_local_path = var.ssh_public_key_local_path
  service_role_arn          = module.iam.role_arn
  vpc_id                    = module.vpc.vpc_id
  ssl_certificate_arn       = module.acm.ssl_certificate_arn
  zone_id                   = module.route53_zone.zone_id
  zone_name                 = module.route53_zone.zone_name
  private_subnet_ids        = module.vpc.private_subnet_ids
  public_subnet_ids         = module.vpc.public_subnet_ids
  security_group_id         = module.vpc.security_group_id

}