variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region to deploy backend resources"
}

variable "state_bucket_name" {
  type        = string
  default     = "rush-my-tf-test-bucket-2026" # Ensure this is globally unique across AWS
  description = "Globally unique S3 bucket name for state storage"
}
