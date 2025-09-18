# Package your lambda source (backend/lambda with app.py at root)
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/build/lambda.zip"
}

resource "aws_lambda_function" "tts" {
  function_name = "${var.project}-svc"
  role          = aws_iam_role.lambda_role.arn
  filename      = data.archive_file.lambda_zip.output_path
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  memory_size   = 512
  timeout       = 30
  publish       = true

  environment {
    variables = {
      AUDIO_BUCKET   = aws_s3_bucket.artifacts.bucket
      AUDIO_PREFIX   = "audio/"
      UPLOADS_BUCKET = aws_s3_bucket.artifacts.bucket
      UPLOADS_PREFIX = "uploads/"
      AUDIO_FORMAT   = "mp3"
      DEFAULT_VOICE  = "Joanna"
    }
  }

  depends_on = [aws_iam_role_policy.lambda_inline]
}
