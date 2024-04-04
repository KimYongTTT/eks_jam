data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["eks-jam-gitops"]
  }
}

module "eks-green" {
  source = "../modules/eks_cluster"

  cluster_name = "eks-jam-cluster-green"

  cluster_version = "1.29"

  vpc_id = data.aws_vpc.vpc.id
}

resource "aws_lb_target_group" "tg-green" {
  name = "tg-green-ui"
  target_type = "ip"
  port = 80
  protocol = "HTTP"
  vpc_id = data.aws_vpc.vpc.id
  
  depends_on = [module.eks-green]
  
  health_check {
    path = "/actuator/health/liveness"
  }
}