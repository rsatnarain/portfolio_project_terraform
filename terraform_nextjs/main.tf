# Author: Rob Satnarain
# Created: 2026-04-27
# Description: This file contains the main Terraform configuration for setting up the AWS infrastructure. It includes the provider configuration for AWS.
#. 
# Updated By     Update Date   Version   Description
# -----------------------------------------------------------------------------------------------
# Rob.           2026-04-27.    1.0.     Initial Create. This file defines the AWS provider, a variable for the S3 bucket name, and resources for creating an S3 bucket, configuring it for website hosting, setting a bucket policy to allow access from CloudFront, and creating a CloudFront distribution to serve the website content. The configuration ensures that the S3 bucket is properly set up for static website hosting and that CloudFront can access the content securely.
# Rob.           2026-04-27    1.1.     Added CloudFront Origin Access Control (OAC) resource and updated the S3 bucket policy to allow access from CloudFront using OAC, enhancing security by ensuring that only CloudFront can access the S3 bucket content.
# Rob.           2026-04-27    1.2.     Add a Custom Error Response to your aws_cloudfront_distribution resource in main.tf. This tells CloudFront to send all 404s back to index.html so Next.js can handle the routing.     
# Rob.           2026-04-29    1.3.     Fix: Update S3 bucket policy to restrict access to specific CloudFront distribution and add custom error responses for 404 and 403 errors to ensure proper handling of client-side routing in Next.js. This ensures that only the designated CloudFront distribution can access the S3 bucket content, enhancing security while maintaining functionality for the Next.js application.
# Rob            2026-04-29    1.4.     Add OIDC provider and IAM role for GitHub Actions to enable secure CI/CD deployment of the Next.js application to S3 and CloudFront. This allows for automated deployments from GitHub while ensuring that only authorized actions can modify the AWS infrastructure, enhancing security and streamlining the deployment process. The IAM role is configured with a trust policy that restricts access to a specific GitHub repository, and permissions are granted for S3 object management and CloudFront cache invalidation, facilitating efficient updates to the website content.

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

    custom_error_response {
        error_code            = 404
        response_code         = 200
        response_page_path    = "/index.html"
    }

    custom_error_response {
        error_code            = 403
        response_code         = 200
        response_page_path    = "/index.html"
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

# ==============================================================================
# OIDC Provider & CI/CD Role for GitHub Actions
# ==============================================================================

# 1. Create the GitHub OIDC Provider in AWS
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  # Standard GitHub OIDC thumbprints
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

# 2. IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions_role" {
  name = "GitHubActionsDeployRole"

  # Trust Policy: Only allows your specific GitHub repo to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # UPDATE THIS LINE: Scope to your exact repository and branch
            "token.actions.githubusercontent.com:sub" = "repo:rsatnarain/portfolio_project_terraform:*"
          }
        }
      }
    ]
  })
}

# 3. IAM Policy: Grants permissions to Sync S3 and Invalidate CloudFront
resource "aws_iam_role_policy" "github_actions_policy" {
  name = "GitHubActionsDeployPolicy"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3DeployPermissions"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        # Dynamically targets the bucket created in this workspace
        Resource = [
          aws_s3_bucket.website_bucket.arn,
          "${aws_s3_bucket.website_bucket.arn}/*"
        ]
      },
      {
        Sid    = "CloudFrontInvalidatePermissions"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        # Dynamically targets the distribution created in this workspace
        Resource = aws_cloudfront_distribution.website_distribution.arn
      }
    ]
  })
}