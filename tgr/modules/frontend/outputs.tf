output "url" {
  description = "CloudFront distribution URL"
  value       = module.static_site.url
}

output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = module.static_site.bucket_id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.static_site.bucket_arn
}

output "distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = module.static_site.distribution_id
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = module.static_site.distribution_arn
}

output "distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.static_site.distribution_domain_name
}

