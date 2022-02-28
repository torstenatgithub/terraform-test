# Kubernetes provider
# https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster#optional-configure-terraform-kubernetes-provider
# To learn how to schedule deployments and services using the provider, go here: https://learn.hashicorp.com/terraform/kubernetes/deploy-nginx-kubernetes

# The Kubernetes provider is included in this file so the EKS module can complete successfully. Otherwise, it throws an error when creating `kubernetes_config_map.aws_auth`.
# You should **not** schedule deployments and services in this workspace. This keeps workspaces modular (one for provision EKS, another for scheduling Kubernetes resources) as per best practices.

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}

# Manage aws-auth ConfigMap manually because of dependencies to role bindings
# Prevents 'User "aws:engineer:xxx" cannot get resource "configmaps"' error while destroying the cluster
resource "kubernetes_config_map" "aws_auth_configmap" {
  metadata {
    name          = "aws-auth"
    namespace     = "kube-system"
  }
  data            = {
    mapRoles      = <<YAML
- rolearn: "arn:aws:iam::${local.aws_account_id}:role/${aws_iam_role.eks_node_group_role.name}"
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
- rolearn: "arn:aws:iam::${local.aws_account_id}:role/owner"
  username: "aws:owner:{{SessionName}}"
  groups:
    - "ecp:owner"
- rolearn: "arn:aws:iam::${local.aws_account_id}:role/engineer"
  username: "aws:engineer:{{SessionName}}"
  groups:
    - "ecp:engineer"
- rolearn: "arn:aws:iam::${local.aws_account_id}:role/reader"
  username: "aws:reader:{{SessionName}}"
  groups:
    - "ecp:reader"
- rolearn: "arn:aws:iam::${local.aws_account_id}:user/admin"
  username: "aws:owner:{{SessionName}}"
  groups:
    - "ecp:owner"
YAML
    mapUsers      = <<YAML
[]
YAML
    mapAccounts   = <<YAML
[]
YAML
  }

  depends_on      = [
    kubernetes_cluster_role_binding.ecp_owner_crb,
    kubernetes_cluster_role_binding.ecp_engineer_crb,
    kubernetes_cluster_role_binding.ecp_reader_crb    
  ]
}

# ClusterRoleBinding for Owners
resource "kubernetes_cluster_role_binding" "ecp_owner_crb" {
  metadata {
    name = "ecp:owner"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "Group"
    name      = "ecp:owner"
    api_group = "rbac.authorization.k8s.io"
  }
}

# ClusterRoleBinding for Engineers
resource "kubernetes_cluster_role_binding" "ecp_engineer_crb" {
  metadata {
    name = "ecp:engineer"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "Group"
    name      = "ecp:engineer"
    api_group = "rbac.authorization.k8s.io"
  }
}

# ClusterRoleBinding for Readers
resource "kubernetes_cluster_role_binding" "ecp_reader_crb" {
  metadata {
    name = "ecp:reader"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "view"
  }
  subject {
    kind      = "Group"
    name      = "ecp:reader"
    api_group = "rbac.authorization.k8s.io"
  }
}
