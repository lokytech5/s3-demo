terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
  }

  # Keep backend block empty; pass values via -backend-config in CI and locally
  backend "s3" {}
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project = "tf-s3-ecr-demo"
      Env     = var.env
      Owner   = var.owner
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"

}

variable "env" {
  type    = string
  default = "dev"

}

variable "owner" {
  type    = string
  default = "your-handle"

}

# ---- S3 bucket (demo target) ----
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "demo" {
  bucket        = "tf-s3-demo-${random_id.suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_encryption" "demo" {
  bucket = aws_s3_bucket.demo.id
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "demo" {
  bucket                  = aws_s3_bucket.demo.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---- ECR repo (demo target) ----
resource "aws_ecr_repository" "plugfolio_repo" {
  name                 = "plugfolio-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration { encryption_type = "AES256" }
  tags = { Name = "PlugfolioECRRepo" }
}

# Expire old tags to keep bills tiny for demos
resource "aws_ecr_lifecycle_policy" "plugfolio_repo" {
  repository = aws_ecr_repository.plugfolio_repo.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1,
      description  = "Keep last 10 images",
      selection = {
        tagStatus   = "any",
        countType   = "imageCountMoreThan",
        countNumber = 10
      },
      action = { type = "expire" }
    }]
  })
}

output "demo_bucket_name" { value = aws_s3_bucket.demo.bucket }
output "ecr_repo_url" { value = aws_ecr_repository.plugfolio_repo.repository_url }
