resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      billing_mode,
      read_capacity,
      write_capacity,
    ]
  }

  tags = {
    Name        = "terraform-state-lock"
    Environment = "production"
  }
}

