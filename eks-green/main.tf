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