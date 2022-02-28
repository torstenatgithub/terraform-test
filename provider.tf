## Specifies the Region your Terraform Provider will server
provider "aws" {
  region = "eu-west-1"
}
## Specifies the S3 Bucket and DynamoDB table used for the durable backend and state locking

terraform {
    backend "s3" {
      encrypt = true
      bucket = "tk-tf-state"
      # dynamodb_table = "terraform-state-lock-dynamo"
      key = "terraform-test/terraform.tfstate"
      region = "eu-west-1"
  }
}