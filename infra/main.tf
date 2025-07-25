terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Example resource (replace with yours)
resource "aws_s3_bucket" "example" {
  bucket = "test-example"
  tags   = { Name = var.project_name }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket                  = aws_s3_bucket.example.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

terraform {
  backend "s3" {
    bucket         = ""
    key            = "my-infra-project/terraform.tfstate"
    region         = ""
    dynamodb_table = ""
    encrypt        = true
  }
}