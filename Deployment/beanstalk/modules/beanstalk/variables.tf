variable "ebs_app_name" {}
variable "ebs_app_description" {}
variable "env" {}
variable "vpc_id" {}
variable "service_role_name" {}
variable "service_role_arn" {}
variable "instance_type" {}
variable "bucket_name" {}
variable "beanstalk_sg_id" {}
variable "application_version" {}
variable "ssl_certificate_arn" {}
variable "solution_stack_name" {}
variable "ssh_public_key_local_path" {}
variable "zone_id" {}
variable "zone_name" {}

variable private_subnet_ids {
  type = list(any)
}

variable public_subnet_ids {
  type = list(any)
}
variable "app_image" {}
variable "app_tag" {}
# variable "app_secret_id" {}
variable "db_host" {}
variable "db_port" {}
variable "db_name" {}
variable "db_user" {}
variable "db_password" {}
variable "alb_sg_id" {}