resource "random_id" "bucket_suffix" {
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
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "json" = "application/json"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "jpeg" = "image/jpeg"
    "gif"  = "image/gif"
    "svg"  = "image/svg+xml"
    "ico"  = "image/x-icon"
    "woff" = "font/woff"
    "woff2" = "font/woff2"
    "ttf"  = "font/ttf"
    "eot"  = "application/vnd.ms-fontobject"
    "txt"  = "text/plain"
    "xml"  = "application/xml"
    "pdf"  = "application/pdf"
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

