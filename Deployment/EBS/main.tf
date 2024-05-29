
module "vpc" {
  source                  = "./modules/vpc"
  tags                    = "ebs-lab"
  instance_tenancy        = "default"
  vpc_cidr                = "10.0.0.0/16"
  public_sn_count         = 2
  public_cidrs            = ["10.0.1.0/24", "10.0.2.0/24"]
  map_public_ip_on_launch = false
  rt_route_cidr_block     = "0.0.0.0/0"
  sg_name                 = "swapapp-sg"
  enable_dns_hostnames    = true
}

module "iam" {
  source                  = "./modules/iam"
  role_name               = "swapapp-role"
  assume_role_policy_file = "./modules/iam/json/iam_role_policy.json"
  assume_policy_file      = "./modules/iam/json/iam_policy.json"
  assume_ebs_ec2_file     = "./modules/iam/json/aws-elasticbeamstalk-ec2-role.json"
}

module "rds" {
  source                  = "./modules/rds"
  allocated_storage       = 10
  engine                  = "mysql"
  engine_version          = 5.7
  instance_class          = "db.t3.micro"
  username                = "root"
  password                = "password"
  db_name                 = "my_application"
  skip_final_snapshot     = true
  subnet_name             = module.vpc.sg_name
  subnet_ids              = module.vpc.subnet_ids
  vpc_security_group_id   = module.vpc.security_group_id
  vpc_id                  = module.vpc.vpc_id
  instance_private_ips    = module.beanstalk.instance_private_ips
  private_subnet_ids      = module.vpc.private_subnet_ids
  public_subnet_ids       = module.vpc.public_subnet_ids
  }

module "route53_zone" {
  source                  = "./modules/route53/zone"
  zone_name               = "swapapp.net"
  vpc_id                  = module.vpc.vpc_id
  zone_id                 = module.route53_zone.zone_id
}

module "route53_rds_record" {
  source                  = "./modules/route53/rds_record"
  zone_name               = module.route53_zone.zone_name
  rds_record_name         = join("-", ["rds", "dev"])
  rds_address             = module.rds.db_endpoint
  zone_id                 = module.route53_zone.zone_id
}

module "route53_registered_domains" {
  source                  = "./modules/route53/registered_domains"
  zone_name               = module.route53_zone.zone_name
  zone_id                 = module.route53_zone.zone_id
  zone_web_name_servers   = module.route53_zone.name_servers
}

module "acm" {
  source                  = "./modules/acm"
  domain_name             = module.route53_zone.zone_name
  zone_id                 = module.route53_zone.zone_id
}

module "beanstalk" {
  source                  = "./modules/beanstalk"
  ebs_app_name            = "swapapp-web"
  ebs_app_description     = "Python Web App Application using Django Framework" 
  solution_stack_name     = "64bit Amazon Linux 2023 v4.3.2 running Docker"
  env                     = "dev"
  service_role_name       = "aws-elasticbeanstalk-ec2-role"
  service_role_arn        = module.iam.role_arn
  vpc_id                  = module.vpc.vpc_id
  instance_type           = "t3.small"
  security_group_id       = module.vpc.security_group_id
  bucket_name             = join("-", [module.beanstalk.ebs_app_name, "bucket"])
  application_version     = "v1.94"
  instance_private_ips    = module.beanstalk.instance_private_ips
  cname_prefix            = module.beanstalk.ebs_app_name
  ebs_environment_url     = module.beanstalk.ebs_environment_url
  ssl_certificate_arn     = module.acm.ssl_certificate_arn
  subnet_availability_zones = module.vpc.subnet_availability_zones
  zone_id                 = module.route53_zone.zone_id
  zone_name               = module.route53_zone.zone_name
  private_subnet_ids      = module.vpc.private_subnet_ids
  public_subnet_ids       = module.vpc.public_subnet_ids
}