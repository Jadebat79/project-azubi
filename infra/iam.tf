# Lambda execution role
data "aws_iam_policy_document" "assume_lambda" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.project}-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

# Inline least-privilege policy
data "aws_iam_policy_document" "lambda_inline" {
  statement {
    sid    = "Polly"
    effect = "Allow"
    actions = [
      "polly:SynthesizeSpeech",
      "polly:DescribeVoices"
    ]
    resources = ["*"] # DescribeVoices cannot be resource-scoped
  }

  statement {
    sid    = "S3Artifacts"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.artifacts.arn}/audio/*",
      "${aws_s3_bucket.artifacts.arn}/uploads/*"
    ]
  }

  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda_inline" {
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_inline.json
}
