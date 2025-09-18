# HTTP API (v2) with CORS
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project}-http"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["content-type"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_origins = var.allowed_origins
    max_age       = 3600
  }
}

# Lambda integration (proxy)
resource "aws_apigatewayv2_integration" "lambda_proxy" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = "2.0"
  integration_uri        = aws_lambda_function.tts.invoke_arn
}

# Routes
resource "aws_apigatewayv2_route" "get_voices" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /voices"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_proxy.id}"
}

resource "aws_apigatewayv2_route" "post_synthesize" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /synthesize"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_proxy.id}"
}

# Stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

# Permission so API Gateway can invoke the function
resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGWInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tts.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
