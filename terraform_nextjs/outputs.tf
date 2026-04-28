# Author: Rob Satnarain
# Created: 2026-04-27
# Description: This file contains the output values for the Terraform configuration. It defines two outputs: `bucket_website_endpoint`, which provides the endpoint URL for the S3 bucket hosting the website, and `cloudfront_url`, which gives the URL for the CloudFront distribution. These outputs allow users to easily access important information about the deployed infrastructure after running Terraform commands.
#
# Updated By     Update Date   Version   Description
# -----------------------------------------------------------------------------------------------
# Rob.           2026-04-27.    1.0.     Initial Create

output "bucket_website_endpoint" {
  value = aws_s3_bucket.website_bucket.website_endpoint
  description = "The endpoint URL for the S3 bucket hosting the website."
}

output "cloudfront_url" {
  value       = aws_cloudfront_distribution.website_distribution.domain_name
  description = "The public URL of the CloudFront distribution"
}