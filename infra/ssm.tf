# Store API invoke URL in SSM so other stacks can read it.
resource "aws_ssm_parameter" "api_invoke_url" {
  name        = "/tts/api/invoke_url"
  description = "Base URL for the HTTP API"
  type        = "String"
  value       = aws_apigatewayv2_stage.default.invoke_url
  overwrite   = true
}