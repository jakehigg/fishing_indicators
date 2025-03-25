resource "aws_iam_role" "lambda_iam_role" {
  provider = aws.target
  name     = "lambda-${local.cleaned_app_name}-${local.cleaned_app_environment}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Application = var.app_name
    Environment = local.app_environment
    Terraform   = true
  }
}

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole" {
  provider   = aws.target
  role       = aws_iam_role.lambda_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_permission" "allow_api_gateway" {
  provider      = aws.target
  function_name = "${local.cleaned_app_name}-${local.cleaned_app_environment}"
  statement_id  = "AllowExecutionFrom"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api_gw.execution_arn}/*"

  depends_on = [
    aws_api_gateway_rest_api.api_gw,
    aws_lambda_function.backend_lambda_function
  ]
}
resource "aws_lambda_function" "backend_lambda_function" {
  provider      = aws.target
  s3_bucket     = aws_s3_bucket.backend_source_bucket.id
  s3_key        = "backend.zip"
  function_name = "${local.cleaned_app_name}-${local.cleaned_app_environment}"
  role          = aws_iam_role.lambda_iam_role.arn
  handler       = "lambda_app.lambda_handler"
  # source_code_hash = data.archive_file.zip_file.output_base64sha256
  runtime = "python3.12"
  snap_start {
    apply_on = "PublishedVersions"
  }
  layers = [
    "arn:aws:lambda:${var.aws_region}:336392948345:layer:AWSSDKPandas-Python312:16"
  ]

  tags = {
    Application = var.app_name
    Environment = local.app_environment
    Terraform   = true
  }
}