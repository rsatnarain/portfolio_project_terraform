# Author: Rob Satnarain
# Created: 2026-04-27
# Description: This file contains the output values for the Terraform configuration. It defines two outputs: `bucket_website_endpoint`, which provides the endpoint URL for the S3 bucket hosting the website, and `cloudfront_url`, which gives the URL for the CloudFront distribution. These outputs allow users to easily access important information about the deployed infrastructure after running Terraform commands.
#
# Updated By     Update Date   Version   Description
# -----------------------------------------------------------------------------------------------
# Rob.           2026-04-27.    1.0.     Initial Create

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.website_distribution.domain_name
  description = "The URL to access the website via CloudFront"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.website_bucket.id
  description = "Name of the S3 bucket"
}