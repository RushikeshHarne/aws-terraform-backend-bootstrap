# S3 Bucket for State Storage

resource "aws_s3_bucket" "tf_state" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
}

# Enable Bucket Versioning (Protects state against corruptions/overwrites)

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-Side Encryption (AES256)

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_crypto" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
