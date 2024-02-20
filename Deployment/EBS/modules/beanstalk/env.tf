    resource "aws_elastic_beanstalk_environment" "ebslab_env" {
    name                = var.env
    application         = aws_elastic_beanstalk_application.ebslab_app.name
    solution_stack_name = "64bit Amazon Linux 2023 v4.2.1 running Docker"
    
    setting {
        namespace = "aws:ec2:vpc"
        name      = "VPCId"
        value     = var.vpc_id
    }

    setting {
        namespace = "aws:ec2:vpc"
        name      = "Subnets"
        value     = join(",", var.subnet_ids)
    }

    setting {
      namespace = "aws:elasticbeanstalk:environment"
      name      = "EnvironmentType"
      value     = "SingleInstance"
    }

    setting {
      namespace = "aws:elasticbeanstalk:environment"
      name      = "ServiceRole"
      value     = var.service_role_arn
    }

    setting {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "IamInstanceProfile"
      value     = "your-instance-profile-name"
    }

    setting {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = "KEY_NAME"
      value     = "your-key-pair-name"
    }
}