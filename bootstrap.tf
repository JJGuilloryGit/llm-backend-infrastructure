# Create DynamoDB table for state locking FIRST
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}


# Create S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "awsaibucket2"  # Your bucket name
  
  depends_on = [aws_dynamodb_table.terraform_state_lock]
  
  lifecycle {
    prevent_destroy = true
  }
}

# Enable versioning for state bucket
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
  
  depends_on = [aws_s3_bucket.terraform_state]
}

# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  
  depends_on = [aws_s3_bucket.terraform_state]
}

# Enable S3 bucket public access blocking
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  
  depends_on = [aws_s3_bucket.terraform_state]
}