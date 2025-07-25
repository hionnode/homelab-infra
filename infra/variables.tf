variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "S3 backend bucket"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB lock table"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "my-infra-project"
}