environment = "dev"
cluster_name = "gh-actions-runner"
kubernetes_version = "1.21"
vpc_cidr = "10.1.0.0/16"
vpc_private_subnets = [
  "10.1.1.0/24",
  "10.1.2.0/24",
  "10.1.3.0/24"
]
vpc_public_subnets = [
  "10.1.11.0/24",
  "10.1.12.0/24",
  "10.1.13.0/24"
]