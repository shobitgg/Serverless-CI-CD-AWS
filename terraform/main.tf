provider "aws" {
  version = ">= 2.28"
  region  = var.region
}


data "aws_availability_zones" "available" {}



###################### Create VPC and SGs ##########################


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = "ecs-demo-vpc"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

}


resource "aws_security_group" "lb" {
  name        = "lb-security-group"
  description = "controls access to the ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "ecs_tasks" {
  name        = "ecs-tasks-security-group"
  description = "allow inbound access from the ALB only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = var.container_port
    to_port         = var.container_port
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


########################### Create ALB ##################################


module "alb" {
  source  = "terraform-aws-modules/alb/aws"

  name = "ecs-alb"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.lb.id]


  target_groups = [
    {
      name_prefix      = "ecs-"
      backend_protocol = "HTTP"
      backend_port     = var.container_port
      target_type      = "ip"
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "Dev"
  }
}



############################# Create ECS Cluster and Fargate Service ##################################


resource "aws_ecs_cluster" "ecs_cluster" {
  name = "default"
}


module "ecs_fargate" {
  source           = "git::https://github.com/tmknom/terraform-aws-ecs-fargate.git?ref=tags/2.0.0"
  name             = var.ecs_service_name
  container_name   = var.container_name
  container_port   = var.container_port
  cluster          = aws_ecs_cluster.ecs_cluster.arn
  subnets          = module.vpc.public_subnets
  target_group_arn = join("", module.alb.target_group_arns)
  vpc_id           = module.vpc.vpc_id

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = "schen13912/fargate-demo:v1.0"
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
    }
  ])

  desired_count                      = 2
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  deployment_controller_type         = "ECS"
  assign_public_ip                   = true
  health_check_grace_period_seconds  = 10
  platform_version                   = "LATEST"
  source_cidr_blocks                 = ["0.0.0.0/0"]
  cpu                                = 256
  memory                             = 512
  requires_compatibilities           = ["FARGATE"]
  iam_path                           = "/service_role/"
  description                        = "Fargate demo example"
  enabled                            = true

  tags = {
    Environment = "Dev"
  }
}


################################### Create ECR Repo and Code Pipeline ###################################


resource "aws_ecr_repository" "fargate-repo" {
  name = var.ecr_repo

  image_scanning_configuration {
    scan_on_push = true
  }
}

module "ecs_codepipeline" {
  source                = "git::https://github.com/cloudposse/terraform-aws-ecs-codepipeline.git?ref=master"
  name                  = var.app_name
  namespace             = var.namespace
  region                = var.region
  image_repo_name       = var.ecr_repo
  stage                 = var.stage
  github_oauth_token    = var.github_oath_token
  github_webhooks_token = var.github_webhooks_token
  webhook_enabled       = "true"
  repo_owner            = var.github_repo_owner
  repo_name             = var.github_repo_name
  branch                = "master"
  service_name          = module.ecs_fargate.ecs_service_name
  ecs_cluster_name      = aws_ecs_cluster.ecs_cluster.arn
  privileged_mode       = "true"
}




