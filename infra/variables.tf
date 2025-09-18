variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "project" {
  type        = string
  description = "Project slug used for naming"
  default     = "tts"
}

variable "artifacts_bucket_name" {
  type        = string
  description = "Name for the private artifacts bucket (audio/uploads)"
  default     = "tts-artifacts-demo" # change to unique name in your account
}

variable "website_bucket_name" {
  type        = string
  description = "Bucket name for S3 static website demo"
  default     = "tts-site-demo" # change to unique name in your account
}

variable "allowed_origins" {
  type        = list(string)
  description = "CORS origins for the API"
  # add Amplify domain later, e.g., https://main.dxxxx.amplifyapp.com
  default = ["*"]
}

variable "audio_retention_days" {
  type    = number
  default = 7
}

variable "uploads_retention_days" {
  type    = number
  default = 30
}

# # Amplify hosting
# variable "app_name" {
#   type        = string
#   description = "Amplify App name"
#   default     = "tts-web"
# }

# variable "github_token" {
#   type      = string
#   sensitive = true
# }

# variable "repo" {
#   type = string
# } # e.g. "https://github.com/jade/tts-capstone"

# variable "branch" {
#   type    = string
#   default = "main"
# }

# variable "app_root" {
#   type    = string
#   default = "frontend/tts-web"
# } # path to your Vite app


# # S3-hosting

# variable "site_bucket_name" {
#   type        = string
#   description = "Bucket name for S3 static website hosting with CloudFront"
#   default     = "tts-cf-site-demo" # change to unique name in your account
# }
# variable "price_class" {
#   type        = string
#   description = "CloudFront price class"
#   default     = "PriceClass_100" # cheapest, US+EU+Asia
#   # other options: PriceClass_200 (adds South America, Oceania), PriceClass_All (all edge locations)
# }
