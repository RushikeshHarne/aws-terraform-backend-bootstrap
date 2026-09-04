output "bucket_id" {
  description = "The name/ID of the created S3 state bucket"
  value       = aws_s3_bucket.tf_state.id
}

output "bucket_arn" {
  description = "The ARN of the created S3 state bucket"
  value       = aws_s3_bucket.tf_state.arn
}
