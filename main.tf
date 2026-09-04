provider "aws" {
  region = var.aws_region
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# 1. Call Reusable Remote Backend Module

module "state_backend" {
  source      = "./Modules/remote_backend"
  bucket_name = "${var.state_bucket_name}-${var.environment}-${random_string.suffix.result}"
}

# 2. Store Bucket Name in SSM Parameter Store for Repository 2 to fetch automatically

#resource "aws_ssm_parameter" "state_bucket_name" {
#  name        = "/terraform/remote_state_bucket"
# type        = "String"
 # value       = module.state_backend.bucket_id
#  description = "S3 bucket name used for remote state storage"
#}
