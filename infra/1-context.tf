provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = local.default_tags
  }
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}