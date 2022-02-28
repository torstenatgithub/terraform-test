
# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/3.7.0
# Terraform module which creates VPC resources on AWS
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 3.7.0"

  name = "${local.vpc_name}"
  azs  = data.aws_availability_zones.available.names

  # Cluster VPC recommendations: https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
  cidr            = var.vpc_cidr
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  # One NAT Gateway per availability zone
  # enable_nat_gateway     = true
  # single_nat_gateway     = false
  # one_nat_gateway_per_az = true

  # Single NAT Gateway - FOR TESTING ONLY!!!
  enable_nat_gateway     = true
  single_nat_gateway     = true

  # Enable DNS support
  # https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Additional tags for the subnets
  # https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
  # https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/3.7.0/submodules/vpc-endpoints
# Terraform module which creates VPC resources on AWS
module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = ">= 3.7.0"

  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [ module.vpc.default_security_group_id, module.eks.worker_security_group_id, module.eks.cluster_primary_security_group_id ]

# When using VPC endpoints in private subnets, you must create endpoints for com.amazonaws.region.ecr.api, com.amazonaws.region.ecr.dkr, and a gateway endpoint for Amazon S3.
# https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html  
  endpoints = {
    s3 = {
      service = "s3"
      service_type = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
    },
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
    },
    ssmmessages = {
      service             = "ssmmessages"
      private_dns_enabled = true
    },
    ec2messages = {
      service             = "ec2messages"
      private_dns_enabled = true
    },
    logs = {
      service             = "logs"
      private_dns_enabled = true
    }
  }
}

# module "vpc_devops" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = ">= 3.7.0"

#   name = "${local.vpc_devops_name}"
#   azs  = data.aws_availability_zones.available.names

#   cidr            = var.vpc_devops_cidr
#   private_subnets = var.vpc_devops_private_subnets
#   public_subnets  = var.vpc_devops_public_subnets

#   # One NAT Gateway per availability zone
#   # enable_nat_gateway     = true
#   # single_nat_gateway     = false
#   # one_nat_gateway_per_az = true

#   # Single NAT Gateway
#   enable_nat_gateway     = true
#   single_nat_gateway     = true

#   # Enable DNS support
#   # https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html
#   enable_dns_hostnames = true
#   enable_dns_support   = true
# }

# resource "aws_vpc_peering_connection" "devops" {
#   vpc_id        = module.vpc_devops.vpc_id
#   peer_vpc_id   = module.vpc.vpc_id
#   auto_accept   = true

#   tags = {
#     Name = "${local.vpc_devops_name}"
#   }
# }

# resource "aws_route" "devops_peering_requester_routes" {
#   count                     = length(module.vpc_devops.private_route_table_ids)
#   route_table_id            = element(module.vpc_devops.private_route_table_ids, count.index)
#   destination_cidr_block    = var.vpc_cidr
#   vpc_peering_connection_id = aws_vpc_peering_connection.devops.id
# }

# resource "aws_route" "devops_peering_peer_routes" {
#   count                     = length(module.vpc.private_route_table_ids)
#   route_table_id            = element(module.vpc.private_route_table_ids, count.index)
#   destination_cidr_block    = var.vpc_devops_cidr
#   vpc_peering_connection_id = aws_vpc_peering_connection.devops.id
# }
