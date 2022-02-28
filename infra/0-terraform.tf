terraform {
  required_version = ">= 1.0.5"

  backend "s3" {
    region = "eu-west-1"
    encrypt = true
    bucket = "tk-tf-state"
  # dynamodb_table = "terraform-state-lock-dynamo"
    key = "terraform-test/terraform.tfstate"
  }

  required_providers {
    # Official Hashicorp Provider Plugin
    # https://registry.terraform.io/providers/hashicorp/aws/latest
    # Lifecycle management of AWS resources
    # Version >= 3.38.0 is required for using default_tags
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.57.0"
    }

    # Official Hashicorp Provider Plugin
    # https://registry.terraform.io/providers/hashicorp/random/latest
    # Supports the use of randomness within Terraform configurations. Logical Provider - no API calls
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }

    # Official Hashicorp Provider Plugin
    # https://registry.terraform.io/providers/hashicorp/local/latest
    # Used to manage local resources, such as creating files
    local = {
      source  = "hashicorp/local"
      version = ">= 2.1.0"
    }

    # Official Hashicorp Kubernetes Plugin
    # https://registry.terraform.io/providers/hashicorp/kubernetes/latest
    # Management of all Kubernetes resources, including Deployments, Services, Custom Resources (CRs and CRDs), Policies, Quotas and more.
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.4.1"
    }
  }
}