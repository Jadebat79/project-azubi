output "api_invoke_url" {
  value       = aws_apigatewayv2_stage.default.invoke_url
  description = "HTTP API base URL"
}

output "artifacts_bucket" {
  value       = aws_s3_bucket.artifacts.bucket
  description = "Private bucket for audio/uploads"
}

output "lambda_arn" {
  value       = aws_lambda_function.tts.arn
  description = "Lambda ARN"
}


# output "website_bucket" {
#   value       = aws_s3_bucket.website.bucket
#   description = "S3 static website bucket (public for demo)"
# }

# output "website_endpoint" {
#   value       = aws_s3_bucket.website.website_endpoint
#   description = "S3 static website endpoint"
# }