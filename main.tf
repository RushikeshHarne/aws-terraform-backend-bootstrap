terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# 1. Call Reusable Remote Backend Module

module "state_backend" {
  source      = "./Modules/remote_backend"
  bucket_name = "${var.state_bucket_name}-${data.aws_caller_identity.current.account_id}"
}

# 2. Store Bucket Name in SSM Parameter Store for Repository 2 to fetch automatically

resource "aws_ssm_parameter" "state_bucket_name" {
  name        = "/terraform/remote_state_bucket"
  type        = "String"
  value       = module.state_backend.bucket_id
  overwrite   = true  # overwrites 
  description = "S3 bucket name used for remote state storage"

}
