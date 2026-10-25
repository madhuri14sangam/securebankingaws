terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 6.0"
    }
  }
}
provider "aws" {
    region = "us-east-2"
}
variable "state_bucket_name" {
  type = string
}
resource "aws_s3_bucket" "tfstate" {
  bucket = var.state_bucket_name
  tags = {
    Project = "secure-banking"
    Purpose = "terraform-state"
  }
}
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_kms_key" "tfstate" {
  description = "Secure Banking Terraform state encryption"
  enable_key_rotation = true
  deletion_window_in_days = 30
}
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
        kms_master_key_id = aws_kms_key.tfstate.arn
    }
    bucket_key_enabled = true
  }
}
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket" "tfstate_logs" {
  bucket = "${var.state_bucket_name}-access-logs"
}