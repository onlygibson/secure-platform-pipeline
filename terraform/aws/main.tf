terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Points at Floci (local AWS emulator), not real AWS.
# For real AWS: remove the endpoints block, the fake keys, and the skip_* lines.
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  s3_use_path_style           = true

  endpoints {
    s3  = "http://localhost:4566"
    iam = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# Bucket that stores the SBOMs produced by CI.
resource "aws_s3_bucket" "sboms" {
  bucket = "spp-sboms"
}

# Keep old versions: an SBOM can't be silently overwritten or deleted.
resource "aws_s3_bucket_versioning" "sboms" {
  bucket = aws_s3_bucket.sboms.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt everything at rest.
resource "aws_s3_bucket_server_side_encryption_configuration" "sboms" {
  bucket = aws_s3_bucket.sboms.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Never public, no matter what anyone sets later.
resource "aws_s3_bucket_public_access_block" "sboms" {
  bucket                  = aws_s3_bucket.sboms.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
