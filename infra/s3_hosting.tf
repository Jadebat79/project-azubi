# # Private S3 bucket for website assets
# resource "aws_s3_bucket" "site" {
#   bucket = var.site_bucket_name
# }

# resource "aws_s3_bucket_ownership_controls" "site" {
#   bucket = aws_s3_bucket.site.id
#   rule { object_ownership = "BucketOwnerEnforced" }
# }

# resource "aws_s3_bucket_public_access_block" "site" {
#   bucket                  = aws_s3_bucket.site.id
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# # (optional) default encryption
# resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
#   bucket = aws_s3_bucket.site.id
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# # CloudFront OAC
# resource "aws_cloudfront_origin_access_control" "oac" {
#   name                              = "${var.site_bucket_name}-oac"
#   description                       = "SigV4 for S3 origin"
#   origin_access_control_origin_type = "s3"
#   signing_behavior                  = "always"
#   signing_protocol                  = "sigv4"
# }

# # CloudFront distribution
# resource "aws_cloudfront_distribution" "cdn" {
#   enabled             = true
#   price_class         = var.price_class
#   default_root_object = "index.html"

#   origin {
#     domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
#     origin_id                = "s3-${aws_s3_bucket.site.id}"
#     origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
#   }

#   default_cache_behavior {
#     target_origin_id       = "s3-${aws_s3_bucket.site.id}"
#     viewer_protocol_policy = "redirect-to-https"
#     allowed_methods        = ["GET", "HEAD", "OPTIONS"]
#     cached_methods         = ["GET", "HEAD"]
#     compress               = true

#     # AWS managed cache/origin-request policies
#     cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
#     origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" # CORS-S3Origin
#     response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03" # CORS-with-preflight
#   }

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   viewer_certificate {
#     cloudfront_default_certificate = true
#     minimum_protocol_version       = "TLSv1.2_2021"
#   }
# }

# # Allow CloudFront (with this distribution) to read from the bucket
# data "aws_iam_policy_document" "site_policy" {
#   statement {
#     sid     = "AllowCloudFrontRead"
#     effect  = "Allow"
#     principals { 
#         type = "Service"
#         identifiers = ["cloudfront.amazonaws.com"] 
#     }
#     actions = ["s3:GetObject"]
#     resources = ["${aws_s3_bucket.site.arn}/*"]
#     condition {
#       test     = "StringEquals"
#       variable = "AWS:SourceArn"
#       values   = [aws_cloudfront_distribution.cdn.arn]
#     }
#   }
# }

# resource "aws_s3_bucket_policy" "site_policy" {
#   bucket = aws_s3_bucket.site.id
#   policy = data.aws_iam_policy_document.site_policy.json
# }

# # (Optional) upload a demo index.html so the site shows something
# resource "aws_s3_object" "demo_index" {
#   bucket       = aws_s3_bucket.site.id
#   key          = "index.html"
#   content_type = "text/html"
#   content      = file("${path.module}/site/index.html")
# }

# output "cloudfront_domain" { value = aws_cloudfront_distribution.cdn.domain_name }
# output "site_bucket"       { value = aws_s3_bucket.site.id }
