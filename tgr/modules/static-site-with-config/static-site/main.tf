module "s3_dir_deploy" {
  source = "./s3-dir-deploy"

  path         = var.path
  bucket_name  = var.bucket_name
  ignore_files = var.ignore_files
  name_prefix  = var.name_prefix
}

# Secondary S3 bucket for origin failover (CKV_AWS_310)
module "s3_dir_deploy_failover" {
  count  = var.enable_origin_failover ? 1 : 0
  source = "./s3-dir-deploy"

  path         = var.path
  bucket_name  = var.bucket_name != null ? "${var.bucket_name}-failover" : null
  ignore_files = var.ignore_files
  name_prefix  = "${var.name_prefix}-failover"
}

resource "random_id" "oac_suffix" {
  byte_length = 4
}

resource "random_id" "log_bucket_suffix" {
  byte_length = 4
}

resource "random_id" "logs_backup_vault_suffix" {
  byte_length = 4
}

# KMS key for logs backup vault encryption
resource "aws_kms_key" "logs_backup_vault_key" {
  description             = "KMS key for logs backup vault ${var.name_prefix}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.name_prefix}-logs-backup-vault-key"
  }
}

resource "aws_kms_alias" "logs_backup_vault_key" {
  name          = "alias/${var.name_prefix}-logs-backup-vault-key"
  target_key_id = aws_kms_key.logs_backup_vault_key.key_id
}

# S3 bucket for CloudFront access logs
resource "aws_s3_bucket" "logs" {
  bucket = "${var.name_prefix}-logs-${random_id.log_bucket_suffix.hex}"
}

# CloudFront requires ACLs to be enabled on logging buckets
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  depends_on = [aws_s3_bucket_ownership_controls.logs]

  bucket = aws_s3_bucket.logs.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# checkov:skip=CKV_AWS_53:CloudFront logging requires ACLs to be enabled
# checkov:skip=CKV_AWS_55:CloudFront logging requires ACLs to be enabled
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = false # CloudFront needs ACL access for logging
  block_public_policy     = true
  ignore_public_acls      = false # CloudFront needs ACL access for logging
  restrict_public_buckets = true
}

# IAM policy to allow CloudFront to write logs
data "aws_iam_policy_document" "logs_policy" {
  statement {
    sid       = "AllowCloudFrontToWriteLogs"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs_policy.json
  depends_on = [
    aws_s3_bucket_ownership_controls.logs,
    aws_s3_bucket_acl.logs,
    aws_s3_bucket_public_access_block.logs
  ]
}

# AWS Backup vault for logs bucket
resource "aws_backup_vault" "logs_backup_vault" {
  name        = "${var.name_prefix}-logs-backup-vault-${random_id.logs_backup_vault_suffix.hex}"
  kms_key_arn = aws_kms_key.logs_backup_vault_key.arn
}

# IAM role for logs backup
data "aws_iam_policy_document" "logs_backup_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "logs_backup_role_policy" {
  statement {
    sid    = "BackupPermissions"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*"
    ]
  }
}

resource "aws_iam_role" "logs_backup_role" {
  name               = "${var.name_prefix}-logs-backup-role"
  assume_role_policy = data.aws_iam_policy_document.logs_backup_assume_role.json
}

resource "aws_iam_role_policy" "logs_backup_role_policy" {
  name   = "${var.name_prefix}-logs-backup-policy"
  role   = aws_iam_role.logs_backup_role.id
  policy = data.aws_iam_policy_document.logs_backup_role_policy.json
}

# AWS Backup plan for logs bucket
resource "aws_backup_plan" "logs_backup_plan" {
  name = "${var.name_prefix}-logs-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.logs_backup_vault.name
    schedule          = "cron(0 2 * * ? *)" # Daily at 2 AM UTC

    lifecycle {
      delete_after = 30 # Keep backups for 30 days
    }
  }
}

resource "aws_backup_selection" "logs_backup_selection" {
  iam_role_arn = aws_iam_role.logs_backup_role.arn
  name         = "${var.name_prefix}-logs-backup-selection"
  plan_id      = aws_backup_plan.logs_backup_plan.id

  resources = [
    aws_s3_bucket.logs.arn
  ]
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.name_prefix}-oac-${random_id.oac_suffix.hex}"
  description                       = "OAC for accessing S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Secondary OAC for failover bucket
resource "aws_cloudfront_origin_access_control" "oac_failover" {
  count                             = var.enable_origin_failover ? 1 : 0
  name                              = "${var.name_prefix}-oac-failover-${random_id.oac_suffix.hex}"
  description                       = "OAC for accessing failover S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # Primary origin
  origin {
    domain_name              = module.s3_dir_deploy.bucket_regional_domain_name
    origin_id                = module.s3_dir_deploy.bucket_id
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  # Secondary origin for failover (CKV_AWS_310)
  dynamic "origin" {
    for_each = var.enable_origin_failover ? [1] : []
    content {
      domain_name              = module.s3_dir_deploy_failover[0].bucket_regional_domain_name
      origin_id                = "${module.s3_dir_deploy_failover[0].bucket_id}-failover"
      origin_access_control_id = aws_cloudfront_origin_access_control.oac_failover[0].id
    }
  }

  # Origin group for failover (CKV_AWS_310)
  dynamic "origin_group" {
    for_each = var.enable_origin_failover ? [1] : []
    content {
      origin_id = "${module.s3_dir_deploy.bucket_id}-group"

      failover_criteria {
        status_codes = [500, 502, 503, 504]
      }

      member {
        origin_id = module.s3_dir_deploy.bucket_id
      }

      member {
        origin_id = "${module.s3_dir_deploy_failover[0].bucket_id}-failover"
      }
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = var.enable_origin_failover ? "${module.s3_dir_deploy.bucket_id}-group" : module.s3_dir_deploy.bucket_id
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  logging_config {
    bucket          = aws_s3_bucket.logs.bucket_regional_domain_name
    include_cookies = false
    prefix          = "cloudfront-logs"
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_type != "none" ? var.geo_restriction_locations : []
    }
  }

  # checkov:skip=CKV_AWS_174:TLS version is set to TLSv1.2_2021 which meets the requirement
  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  web_acl_id = var.web_acl_id

  # # Custom error responses for SPA routing
  # # Return index.html for 404 and 403 errors so client-side routing works
  # custom_error_response {
  #   error_code            = 404
  #   response_code         = 200
  #   response_page_path    = "/index.html"
  #   error_caching_min_ttl = 300
  # }

  # custom_error_response {
  #   error_code            = 403
  #   response_code         = 200
  #   response_page_path    = "/index.html"
  #   error_caching_min_ttl = 300
  # }
}

data "aws_iam_policy_document" "oac_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_dir_deploy.bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = module.s3_dir_deploy.bucket_id
  policy = data.aws_iam_policy_document.oac_policy.json

  depends_on = [
    aws_cloudfront_distribution.distribution
  ]
}

# Bucket policy for failover bucket
data "aws_iam_policy_document" "oac_policy_failover" {
  count = var.enable_origin_failover ? 1 : 0

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_dir_deploy_failover[0].bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy_failover" {
  count  = var.enable_origin_failover ? 1 : 0
  bucket = module.s3_dir_deploy_failover[0].bucket_id
  policy = data.aws_iam_policy_document.oac_policy_failover[0].json

  depends_on = [
    aws_cloudfront_distribution.distribution
  ]
}

