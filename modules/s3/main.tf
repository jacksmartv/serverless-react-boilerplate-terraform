
resource "aws_s3_bucket" "log_bucket" {
  count  = var.enable_logging ? 1 : 0
  bucket = var.s3_log_bucket_name
  tags   = merge({ "Name" = "s3-logs-bucket" }, var.default_tags)
}
resource "aws_s3_bucket_acl" "log_bucket_acl" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_lc" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].id

  rule {
    id = "Delete after 1 day"
    abort_incomplete_multipart_upload {

      days_after_initiation = 1
    }
    status = "Enabled"
    expiration {
      days                         = 7
      expired_object_delete_marker = false
    }
    noncurrent_version_expiration {
      noncurrent_days = 2
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_enc" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name
  tags   = merge({ "Name" = "s3-bucket" }, var.default_tags)
}

resource "aws_s3_bucket_versioning" "main_vers" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "main_logging" {
  count         = var.enable_logging ? 1 : 0
  bucket        = aws_s3_bucket.main.id
  target_bucket = aws_s3_bucket.log_bucket[0].id
  target_prefix = "log_"
}

resource "aws_s3_bucket_acl" "main_bucket_acl" {
  bucket = aws_s3_bucket.main.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main_bucket_enc" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.main.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "AWSLogDeliveryWrite20150319",
    "Statement": [
        {
            "Sid": "AWSLogDeliveryWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "delivery.logs.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.log_bucket[0].id}/AWSLogs/${var.account_number}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Sid": "AWSLogDeliveryAclCheck",
            "Effect": "Allow",
            "Principal": {
                "Service":  [
                                "delivery.logs.amazonaws.com",
                                "logs.${var.region}.amazonaws.com"
                            ]
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.log_bucket[0].id}"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "logs.${var.region}.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.log_bucket[0].id}/CloudwatchLogs/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
  ]
}
  POLICY
}
