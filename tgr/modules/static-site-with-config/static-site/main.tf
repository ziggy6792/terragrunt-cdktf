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

