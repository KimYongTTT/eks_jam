data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["eks-jam-gitops"]
  }
}

module "eks-blue" {
  source = "../modules/eks_cluster"

  cluster_name = "eks-jam-cluster-blue"

  cluster_version = "1.28"

  vpc_id = data.aws_vpc.vpc.id
}

resource "aws_lb_target_group" "tg-blue" {
  name = "tg-blue-ui"
  target_type = "ip"
  port = 80
  protocol = "TCP"
  vpc_id = data.aws_vpc.vpc.id
  
  depends_on = [module.eks-blue]
}