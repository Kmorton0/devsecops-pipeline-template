# Demo infrastructure used only to give the IaC scanner something to check.
# Nothing here is deployed by the pipeline.

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "demo" {
  description         = "Demo key for S3 bucket encryption"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowAccountAdministration"
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
      Action    = "kms:*"
      Resource  = "*"
    }]
  })
}

resource "aws_s3_bucket" "demo" {
  bucket = "example-devsecops-demo-bucket"

  # checkov:skip=CKV2_AWS_62:Event notifications are not needed for this demo bucket
  # checkov:skip=CKV_AWS_144:Cross-region replication is out of scope for a demo bucket
}



resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.demo.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "demo" {
  bucket        = aws_s3_bucket.demo.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "demo-access-logs/"
}

# Log destination bucket. Logging on the log bucket itself is skipped to avoid
# an infinite logging chain.
resource "aws_s3_bucket" "logs" {
  bucket = "example-devsecops-demo-logs"

  # checkov:skip=CKV_AWS_18:Log bucket does not log to itself
  # checkov:skip=CKV2_AWS_62:Event notifications are not needed for the log bucket
  # checkov:skip=CKV_AWS_144:Cross-region replication is out of scope for a demo log bucket
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.demo.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
