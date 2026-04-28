# Author: Rob Satnarain
# Created: 2026-04-27
# Description: This file contains the main Terraform configuration for setting up the AWS infrastructure. It includes the provider configuration for AWS.
#. 
# Updated By     Update Date   Version   Description
# -----------------------------------------------------------------------------------------------
# Rob.           2026-04-27.    1.0.     Initial Create
# Rob.           2026-04-27.    1.1.     Added S3 bucket and CloudFront distribution resources for hosting the website. FIX: Use the regional domain name instead of website_endpoint for CloudFront origin configuration. Added origin access control for secure access to the S3 bucket. Updated outputs to reflect changes in the infrastructure setup.

provider "aws" {
  region = "us-east-1"
}

variable "website_s3_bucket_rs" {
  type        = string
  description = "The name of the S3 bucket for the website"
}

resource "aws_s3_bucket" "website_bucket" {
    bucket = var.website_s3_bucket_rs

  tags = {
    Name        = "Portfolio Website"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
      }
    ]
  })
  
}

resource "aws_cloudfront_distribution" "website_distribution" {
    origin {
        # FIX: Use the regional domain name instead of website_endpoint
        domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
        origin_id                = "S3-Website"
        origin_access_control_id = aws_cloudfront_origin_access_control.default.id

        custom_origin_config {
            http_port = 80
            https_port = 443
            origin_protocol_policy = "http-only"
            origin_ssl_protocols = ["TLSv1.2"]
        }
    }


    enabled = true
    default_root_object = "index.html"

    default_cache_behavior {
        allowed_methods  = ["GET", "HEAD"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = "S3-Website"

        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
        }
        
        viewer_protocol_policy = "redirect-to-https"
        min_ttl                = 0
        default_ttl            = 3600
        max_ttl                = 86400
    }

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    viewer_certificate {
        cloudfront_default_certificate = true
    }

    tags = {
        Name        = "Portfolio CloudFront Distribution"
        Environment = "Production"
    }
}