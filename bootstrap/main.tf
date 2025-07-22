terraform {
  # required_version = ">= 1.5"
  required_providers {
    aws ={
        source = "hashicord/aws"
        version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "terraform_backend" {
  bucket = var.bucket_name

  tags = {
    Name = "Terraform Backend Bucket"
    Environment = "Infrastructure"
  }
}

resource "aws_s3_bucket_versioning" "terraform_backend_versioning" {
  bucket = aws_s3_bucket.terraform_backend.id

  versioning_configuration{
    status = "Enabled"
  }
}


resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_backend_encryption"{
  bucket = aws_s3_bucket.terraform_backend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_backend_block_public" {
  bucket = aws_s3_bucket.terraform_backend.id

  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# DynamoDB table for state Locking

resource "aws_dynamodb_table" "terraform_lock" {
  name = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute{
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform Lock Table"
    Environment = "Infrastructure"
  }
}


# Placeholder for Remote Backend (configured dynamically later)
terraform {
  backend "s3" {
    bucket         = ""  # Passed via -backend-config
    key            = "terraform.tfstate"  # State file path in S3
    region         = ""
    dynamodb_table = ""
    encrypt        = true  # Encrypt state in transit and at rest
  }
}
