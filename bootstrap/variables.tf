variable "aws_region" {
  description = "aws region for the resources"
  type = string
  default = "ap-south-1"
}

variable "bucket_name" {
    description = "Globally unique name for the S3 bucket"
    type = string
}


variable "dynamodb_table_name"{
    description = "name for the dynamodb lock table"
    type = string
}