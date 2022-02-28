variable "cluster_name" {
  description = "The name for the EKS cluster without environment prefix"
  type        = string
  default     = "default-cluster"
}

variable "environment" {
  description = "The environment that this deployment belongs to"
  type        = string
  default     = "dev"
}

variable "kubernetes_version" {
  description = "The Kubernetes version of the cluster"
  type        = string
  default     = "1.21"
}

variable "vpc_cidr" {
  description = "The CIDR for the cluster VPC"
  type        = string
  default      = "192.168.0.0/16"
}

variable "vpc_private_subnets" {
  description = "The private subnet CIDRs"
  type        = list(string)
  default     = [ "192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24" ]
}

variable "vpc_public_subnets" {
  description = "The public subnet CIDRs"
  type        = list(string)
  default     = [ "192.168.11.0/24", "192.168.12.0/24", "192.168.13.0/24" ]
}

# variable "vpc_devops_cidr" {
#   description = "The CIDR for the DevOps VPC"
#   type        = string
#   default      = "192.169.0.0/16"
# }

# variable "vpc_devops_private_subnets" {
#   description = "The private subnet CIDRs"
#   type        = list(string)
#   default     = [ "192.169.1.0/24", "192.169.2.0/24", "192.169.3.0/24" ]
# }

# variable "vpc_devops_public_subnets" {
#   description = "The public subnet CIDRs"
#   type        = list(string)
#   default     = [ "192.169.11.0/24", "192.169.12.0/24", "192.169.13.0/24" ]
# }

# resource "random_string" "suffix" {
#   length  = 8
#   special = false
# }

locals {
  aws_account_id  = data.aws_caller_identity.current.account_id
  resource_prefix = "${var.environment}-${var.cluster_name}"
  vpc_name        = "${local.resource_prefix}-vpc"
#   vpc_devops_name = "${local.resource_prefix}-devops-vpc"
  cluster_name    = "${local.resource_prefix}-eks"

  # Recommendation for tag names: https://docs.aws.amazon.com/whitepapers/latest/tagging-best-practices/adopt-a-standardized-approach-for-tag-names.html
  default_tags = {
     "ergo:ecp:starter-pack"     = "managed-kubernetes-aws"
     "ergo:ecp:environment"      = var.environment
     "ergo:ecp:eks:cluster-name" = local.cluster_name
  }

  node_security_group_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = local.cluster_name
}