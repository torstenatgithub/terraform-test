module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "18.5.1"

  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version
  subnet_ids      = module.vpc.private_subnets

  vpc_id = module.vpc.vpc_id

  # Terraform calls the cluster API during deployment :-(
  # Public access must be disabled manually after deployment
  cluster_endpoint_public_access                 = true

  # Settings for a private API endpoint
  # Only IPs from the VPC can call the cluster API
  cluster_endpoint_private_access                = true
  
  cluster_enabled_log_types = [ "api", "audit", "authenticator", "controllerManager", "scheduler" ]

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  enable_irsa = true

  node_security_group_additional_rules = local.node_security_group_rules

  # EKS managed node group
  eks_managed_node_group_defaults = {
    instance_types  = ["t2.small", "t3.small"]
    disk_size       = 50
    create_iam_role = false
    iam_role_arn    = aws_iam_role.eks_node_group_role.arn
  }

  eks_managed_node_groups = {
      workerpool = {
        # create_launch_template = false
        # launch_template_name   = ""
        name             = "worker-pool"
        ami_type         = "AL2_x86_64"
        iam_role_arn     = aws_iam_role.eks_node_group_role.arn
        desired_capacity = 1
        max_capacity     = 2
        min_capacity     = 1
        instance_types = ["t2.small"]

        block_device_mappings  = {
        "xvda" = {
          device_name = "/dev/xvda"
          ebs = {
            delete_on_termination = true
            encrypted = false
            volume_type = "gp3"
            volume_size = 50
            # kms_key_id = data.aws_kms_key.ergo_key.arn
            virtual_name = "ephemeral0"
          }
        }
      }
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