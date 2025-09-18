provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "tf-s3-demo-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-s3-demo-locks"

  }
}

# Fetch an existing role
data "aws_iam_role" "lambda_role" {
  name = "lambda-fancout-shared-role"
}

resource "aws_s3_bucket" "demo" {
  bucket        = "tf-s3-demo${random_id.suffix.hex}"
  force_destroy = true
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_ecr_repository" "plugfolio_repo" {
  name                 = "plugfolio-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  tags = {
    Name = "PlugfolioECRRepo"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "hello_lambda" {
  function_name    = "lambda_function"
  role             = var.lambda_role_arn
  handler          = "lambda_function.handler"
  runtime          = "python3.13"
  filename         = "${path.module}/../lambda/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/lambda_function.zip")
}
