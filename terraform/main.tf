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
#new comment

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
