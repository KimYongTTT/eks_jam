provider "aws" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  name   = var.environment_name
  region = data.aws_region.current

  vpc_cidr       = var.vpc_cidr
  num_of_subnets = min(length(data.aws_availability_zones.available.names), 3)
  azs            = slice(data.aws_availability_zones.available.names, 0, local.num_of_subnets)

  argocd_secret_manager_name = var.argocd_secret_manager_name_suffix

  hosted_zone_name = var.hosted_zone_name

  tags = {
    Blueprint  = local.name
  }
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 6, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 6, k + 10)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

resource "aws_lb" "service-external-alb" {
  name               = "service-external-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [for subnet in module.vpc.public_subnets : subnet]
  security_groups = [aws_security_group.alb_sg_http.id]

  tags = local.tags
  
  depends_on = [module.vpc]
}

resource "aws_security_group" "alb_sg_http" {
  name        = "eks-jam-sg-external-alb"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "eks-jam-sg-external-alb"
  }
  
  depends_on = [module.vpc]
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.alb_sg_http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.alb_sg_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_codecommit_repository" "gitops" {
  repository_name = "eks-jam-gitops-repository"
  description     = "CodeCommit repository for GitOps"
}
