module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "= 17.20.0"

  # Manage aws-auth ConfigMap manually in kubernetes module because of dependencies to role bindings  
  manage_aws_auth = false

  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version
  subnets         = module.vpc.private_subnets

  vpc_id = module.vpc.vpc_id

  # Terraform calls the cluster API during deployment :-(
  # Public access must be disabled manually after deployment
  cluster_endpoint_public_access                 = true

  # Settings for a private API endpoint
  # Only IPs from the VPC can call the cluster API

  cluster_create_endpoint_private_access_sg_rule = true
  cluster_endpoint_private_access                = true
  
  cluster_endpoint_private_access_cidrs          = [
    var.vpc_cidr
  ]
  
  cluster_endpoint_private_access_sg             = [
    module.eks.cluster_primary_security_group_id,
    module.eks.cluster_security_group_id,
    module.eks.worker_security_group_id
  ]
  
  cluster_enabled_log_types = [ "api", "audit", "authenticator", "controllerManager", "scheduler" ]

  # Managed Node Group
  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50
  }
  
  node_groups = {
    workerpool = {
      iam_role_arn     = aws_iam_role.eks_node_group_role.arn
      desired_capacity = 1
      max_capacity     = 2
      min_capacity     = 1
      instance_types = ["t2.small"]

    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

# No Ergo KMS key in eu-west-i
# data "aws_kms_alias" "ergo" {
#   name = "ergo"
# }