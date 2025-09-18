# Private artifacts bucket (audio + uploads)
resource "aws_s3_bucket" "artifacts" {
  bucket = var.artifacts_bucket_name
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# (Optional but good) default encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle: audio/*
resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    id     = "expire-audio"
    status = "Enabled"

    filter { prefix = "audio/" }

    expiration {
      days = var.audio_retention_days
    }
  }

  rule {
    id     = "expire-uploads"
    status = "Enabled"

    filter { prefix = "uploads/" }

    expiration {
      days = var.uploads_retention_days
    }
  }
}



# # --- S3 Website demo bucket (public for demo simplicity) ---
# resource "aws_s3_bucket" "website" {
#   bucket = var.website_bucket_name
# }

# resource "aws_s3_bucket_website_configuration" "website" {
#   bucket = aws_s3_bucket.website.id

#   index_document {
#     suffix = "index.html"
#   }

#   error_document {
#     key = "index.html"
#   }
# }

# # Public access disabled blocker must be OFF for static website endpoints.
# resource "aws_s3_bucket_public_access_block" "website" {
#   bucket                  = aws_s3_bucket.website.id
#   block_public_acls       = false
#   block_public_policy     = false
#   ignore_public_acls      = false
#   restrict_public_buckets = false
# }

# # Public read policy (demo)
# data "aws_iam_policy_document" "website_public" {
#   statement {
#     sid    = "PublicReadGetObject"
#     effect = "Allow"
#     principals { 
#         type = "AWS" 
#         identifiers = ["*"] 
#     }
#     actions   = ["s3:GetObject"]
#     resources = ["${aws_s3_bucket.website.arn}/*"]
#   }
# }

# resource "aws_s3_bucket_policy" "website_public" {
#   bucket = aws_s3_bucket.website.id
#   policy = data.aws_iam_policy_document.website_public.json
# }
