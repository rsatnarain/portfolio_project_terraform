# Author: Rob Satnarain
# Created: 2026-04-27
# Description: This file contains the output values for the Terraform configuration. It defines two outputs: `bucket_website_endpoint`, which provides the endpoint URL for the S3 bucket hosting the website, and `cloudfront_url`, which gives the URL for the CloudFront distribution. These outputs allow users to easily access important information about the deployed infrastructure after running Terraform commands.
#
# Updated By     Update Date   Version   Description
# -----------------------------------------------------------------------------------------------
# Rob            2026-04-27.    1.0.     Initial Create
# Rob            2026-04-29.    1.1.     Fix: Added output for CloudFront distribution ID to facilitate cache invalidation and updated descriptions for clarity. This enhancement allows users to easily identify the CloudFront distribution associated with the S3 bucket, making it more convenient to manage and invalidate caches when necessary, ensuring that updates to the website are reflected promptly for end-users. Cache invalidation is crucial for maintaining the performance and freshness of the content served through CloudFront, especially after updates to the S3 bucket content. Handled using a CI/CD pipeline via GitHub Actions, the distribution ID is essential for targeting the correct distribution during cache invalidation processes.

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.website_distribution.domain_name
  description = "The URL to access the website via CloudFront"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.website_bucket.id
  description = "Name of the S3 bucket"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.website_distribution.id
  description = "The ID of the CloudFront distribution for cache invalidation"
}

output "cloudfront_invalidator_role_arn" {
  value       = aws_iam_role.cloudfront_invalidator_role.arn
  description = "ARN of the created IAM Role for CloudFront invalidation"
}