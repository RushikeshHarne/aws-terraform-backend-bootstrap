variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket for Terraform remote state"
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed"
}
