# Author: Rob Satnarain
# Created: 2026-04-27
# Description: This file contains the main Terraform configuration for setting up the AWS infrastructure. It includes the provider configuration for AWS.
#. 
# Updated By     Update Date   Version   Description
# -----------------------------------------------------------------------------------------------
# Rob.           2026-04-27.    1.0.     Initial Create. This file defines the AWS provider, a variable for the S3 bucket name, and resources for creating an S3 bucket, configuring it for website hosting, setting a bucket policy to allow access from CloudFront, and creating a CloudFront distribution to serve the website content. The configuration ensures that the S3 bucket is properly set up for static website hosting and that CloudFront can access the content securely.

provider "aws" {
  region = "us-east-1"
}

variable "website_s3_bucket_rs" {
  type        = string
  description = "The name of the S3 bucket for the website"
}

# 1. S3 Bucket
resource "aws_s3_bucket" "website_bucket" {
  bucket = var.website_s3_bucket_rs

  tags = {
    Name        = "Portfolio Website"
    Environment = "Production"
  }
}

# 2. Block all public access (Best Practice: Keep S3 private)
resource "aws_s3_bucket_public_access_block" "website_bucket_privacy" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. CloudFront Origin Access Control (The missing resource)
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "s3-portfolio-oac"
  description                       = "OAC for Portfolio Website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 4. CloudFront Distribution
resource "aws_cloudfront_distribution" "website_distribution" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id                = "S3-Website"
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    # Note: No custom_origin_config needed for S3 OAC
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-Website"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
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
    Name        = "Portfolio Distribution"
    Environment = "Production"
  }
}

# 5. Bucket Policy (Updated to allow CloudFront OAC)
resource "aws_s3_bucket_policy" "allow_access_from_cloudfront" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website_distribution.arn
          }
        }
      }
    ]
  })
}