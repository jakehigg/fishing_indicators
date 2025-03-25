###############################################
#
# API Gateway Config
#
###############################################

# API Paths Shortcut
locals {
  api_paths = [
    "water_temperature",
    "tide",
    "weather"
  ]
}

resource "aws_api_gateway_account" "cw_integration" {
  provider            = aws.target
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
  depends_on = [
    aws_iam_role_policy_attachment.attach_cloudwatch_logging,
    aws_iam_role.cloudwatch
  ]
}

resource "aws_iam_role" "cloudwatch" {
  provider = aws.target
  name     = "api_gateway_${local.cleaned_app_name}-${local.cleaned_app_environment}_cloudwatch_global"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "apigateway.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_logging" {
  provider   = aws.target
  role       = aws_iam_role.cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_rest_api" "api_gw" {
  provider = aws.target
  name     = "${local.cleaned_app_name}-${local.cleaned_app_environment}"

  tags = {
    Application = var.app_name
    Environment = local.app_environment
    Terraform   = true
  }
}

resource "aws_api_gateway_method" "request_method" {
  provider      = aws.target
  rest_api_id   = aws_api_gateway_rest_api.api_gw.id
  resource_id   = aws_api_gateway_rest_api.api_gw.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "http_200" {
  provider    = aws.target
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  resource_id = aws_api_gateway_rest_api.api_gw.root_resource_id
  http_method = aws_api_gateway_method.request_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_stage" "api_gw_stage" {
  provider      = aws.target
  deployment_id = aws_api_gateway_deployment.api_gw_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api_gw.id
  stage_name    = "api"
  tags = {
    Application = var.app_name
    Environment = local.app_environment
    Terraform   = true
  }
}

resource "aws_api_gateway_method_settings" "api_gw_settings" {
  provider    = aws.target
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  stage_name  = aws_api_gateway_stage.api_gw_stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
  depends_on = [aws_api_gateway_account.cw_integration]
}

resource "aws_api_gateway_integration" "api_gw_root" {
  provider    = aws.target
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  resource_id = aws_api_gateway_method.request_method.resource_id
  http_method = aws_api_gateway_method.request_method.http_method

  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.backend_lambda_function.invoke_arn
  depends_on = [
    aws_lambda_function.backend_lambda_function
  ]
}

###############################################
#
# API Gateway Lambda Paths
#
###############################################

resource "aws_api_gateway_resource" "api_resources" {
  for_each    = toset(local.api_paths)
  provider    = aws.target
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  parent_id   = aws_api_gateway_rest_api.api_gw.root_resource_id
  path_part   = each.key
}

resource "aws_api_gateway_method" "api_methods" {
  for_each      = toset(local.api_paths)
  provider      = aws.target
  rest_api_id   = aws_api_gateway_rest_api.api_gw.id
  resource_id   = aws_api_gateway_resource.api_resources[each.key].id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "api_integrations" {
  for_each                = toset(local.api_paths)
  provider                = aws.target
  rest_api_id             = aws_api_gateway_rest_api.api_gw.id
  resource_id             = aws_api_gateway_resource.api_resources[each.key].id
  http_method             = aws_api_gateway_method.api_methods[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.backend_lambda_function.invoke_arn

  depends_on = [aws_lambda_function.backend_lambda_function]
}

resource "aws_api_gateway_method_response" "api_responses" {
  for_each    = toset(local.api_paths)
  provider    = aws.target
  rest_api_id = aws_api_gateway_rest_api.api_gw.id
  resource_id = aws_api_gateway_resource.api_resources[each.key].id
  http_method = aws_api_gateway_method.api_methods[each.key].http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# Deploy API changes
resource "aws_api_gateway_deployment" "api_gw_deployment" {
  provider    = aws.target
  rest_api_id = aws_api_gateway_rest_api.api_gw.id

  triggers = {
    redeployment = filesha1("apigateway.tf")
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.api_methods,
    aws_api_gateway_integration.api_integrations
  ]
}

