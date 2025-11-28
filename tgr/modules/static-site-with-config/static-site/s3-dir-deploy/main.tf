resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "random_id" "backup_vault_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name != null ? var.bucket_name : "${var.name_prefix}-bucket-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# AWS Backup protection for S3 bucket
resource "aws_backup_vault" "backup_vault" {
  name        = "${var.name_prefix}-backup-vault-${random_id.backup_vault_suffix.hex}"
  kms_key_arn = null # Use default AWS managed key
}

resource "aws_backup_plan" "backup_plan" {
  name = "${var.name_prefix}-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.backup_vault.name
    schedule          = "cron(0 2 * * ? *)" # Daily at 2 AM UTC

    lifecycle {
      delete_after = 30 # Keep backups for 30 days
    }
  }
}

resource "aws_backup_selection" "backup_selection" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "${var.name_prefix}-backup-selection"
  plan_id      = aws_backup_plan.backup_plan.id

  resources = [
    aws_s3_bucket.bucket.arn
  ]
}

# IAM role for AWS Backup
data "aws_iam_policy_document" "backup_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "backup_role_policy" {
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
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*"
    ]
  }
}

resource "aws_iam_role" "backup_role" {
  name               = "${var.name_prefix}-backup-role"
  assume_role_policy = data.aws_iam_policy_document.backup_assume_role.json
}

resource "aws_iam_role_policy" "backup_role_policy" {
  name   = "${var.name_prefix}-backup-policy"
  role   = aws_iam_role.backup_role.id
  policy = data.aws_iam_policy_document.backup_role_policy.json
}

# Get all files from the directory
locals {
  all_files = fileset(var.path, "**")
  # Filter out ignored files
  files_to_upload = [
    for file in local.all_files : file
    if !contains(var.ignore_files, file)
  ]

  # MIME type mapping for common file types
  mime_types = {
    "html"  = "text/html"
    "css"   = "text/css"
    "js"    = "application/javascript"
    "json"  = "application/json"
    "png"   = "image/png"
    "jpg"   = "image/jpeg"
    "jpeg"  = "image/jpeg"
    "gif"   = "image/gif"
    "svg"   = "image/svg+xml"
    "ico"   = "image/x-icon"
    "woff"  = "font/woff"
    "woff2" = "font/woff2"
    "ttf"   = "font/ttf"
    "eot"   = "application/vnd.ms-fontobject"
    "txt"   = "text/plain"
    "xml"   = "application/xml"
    "pdf"   = "application/pdf"
  }

  # Get file extension and determine MIME type
  file_mime_types = {
    for file in local.files_to_upload :
    file => try(
      local.mime_types[lower(reverse(split(".", reverse(split("/", file))[0]))[0])],
      "application/octet-stream"
    )
  }
}

resource "aws_s3_object" "files" {
  for_each = toset(local.files_to_upload)

  bucket       = aws_s3_bucket.bucket.id
  key          = each.value
  source       = "${var.path}/${each.value}"
  etag         = filemd5("${var.path}/${each.value}")
  content_type = local.file_mime_types[each.value]

  # Force destroy to allow updates
  force_destroy = true
}

