data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = ["eks-jam-gitops-private-*"]
  }
}

# Find the user currently in use by AWS
data "aws_caller_identity" "current" {}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# module "eks_blueprints_addons" {
#   source = "aws-ia/eks-blueprints-addons/aws"
#   version = "~> 1.0" 

#   cluster_name      = module.eks.cluster_name
#   cluster_endpoint  = module.eks.cluster_endpoint
#   cluster_version   = module.eks.cluster_version
#   oidc_provider_arn = module.eks.oidc_provider_arn

#   enable_aws_load_balancer_controller    = true
  
#   depends_on = [module.eks]
# }

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.16"

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true

  cluster_addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          ENABLE_POD_ENI                    = "true"
          ENABLE_PREFIX_DELEGATION          = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
        nodeAgent = {
          enablePolicyEventLogs = "true"
        }
        enableNetworkPolicy = "true"
      })
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = data.aws_subnets.private.ids

  create_cluster_security_group = false
  create_node_security_group    = false

  #TODO change to jam participant role 
  # manage_aws_auth_configmap = true
  # aws_auth_roles = [
  #   {
  #     rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/WSParticipantRole" # The ARN of the IAM role
  #     username = "admin"                                                                                      # The user name within Kubernetes to map to the IAM role
  #     groups   = ["system:masters"]                                                                              # A list of groups within Kubernetes to which the role is mapped; Checkout K8s Role and Rolebindings
  #   }
  # ]

  eks_managed_node_groups = {
    default = {
      instance_types       = ["m5.large"]
      force_update_version = true
      release_version      = var.ami_release_version

      min_size     = 3
      max_size     = 6
      desired_size = 3

      update_config = {
        max_unavailable_percentage = 50
      }

      labels = {
        workshop-default = "yes"
      }
    }
  }
}