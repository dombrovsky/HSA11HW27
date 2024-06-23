provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "worm_bucket_e1" {
  bucket = "worm-bucket-e1"

  object_lock_enabled = true

  versioning {
    enabled = true
  }

  logging {
    target_bucket = aws_s3_bucket.logs_bucket.bucket
    target_prefix = "log/"
  }

  lifecycle {
    ignore_changes = [object_lock_configuration] # Prevent Terraform from changing object lock settings
  }
}

resource "aws_s3_bucket_object_lock_configuration" "worm_bucket_e1_lock" {
  bucket = aws_s3_bucket.worm_bucket_e1.bucket

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 365
    }
  }
}

resource "aws_s3_bucket" "logs_bucket" {
  bucket = "worm-access-logs-bucket"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_policy" "logs_bucket_policy" {
  bucket = aws_s3_bucket.logs_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "${data.aws_caller_identity.current.account_id}"
          }
          ArnLike = {
            "aws:SourceArn" = "${aws_s3_bucket.worm_bucket_e1.arn}"
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
