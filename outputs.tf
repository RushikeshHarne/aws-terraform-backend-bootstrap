output "s3_state_bucket_name" {
  description = "The bucket created for state storage"
  value       = module.state_backend.bucket_id
}

#output "ssm_parameter_name" {
#  description = "SSM Parameter path storing the bucket name"
#  value       = aws_ssm_parameter.state_bucket_name.name
#}
