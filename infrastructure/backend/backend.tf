provider "aws" {
  region  = "ca-central-1"
  profile = "terraform"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "liman-terraform-statefile-388374893922"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "limanEKS_terraform_locks" {
  name         = "liman-terraform-locks-388374893922"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "liman DynamoDB Terraform State Lock"
  }
}
