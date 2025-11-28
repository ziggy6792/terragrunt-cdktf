output "url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.distribution.domain_name}"
}

output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = module.s3_dir_deploy.bucket_id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3_dir_deploy.bucket_arn
}

output "distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.distribution.id
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.distribution.arn
}

output "distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.distribution.domain_name
}

output "failover_bucket_id" {
  description = "ID of the failover S3 bucket (if origin failover is enabled)"
  value       = var.enable_origin_failover ? module.s3_dir_deploy_failover[0].bucket_id : null
}

