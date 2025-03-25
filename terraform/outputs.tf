output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.app_distribution.id
}

output "frontend_app_bucket" {
  value = aws_s3_bucket.app_bucket.id
}

output "role_arn" {
  value = local.target_account_role_arn
}

output "aws_region" {
  value = var.aws_region
}

output "backend_source_artifact" {
  value = "s3://${aws_lambda_function.backend_lambda_function.s3_bucket}/${aws_lambda_function.backend_lambda_function.s3_key}"
}

output "backend_source_bucket" {
  value = aws_lambda_function.backend_lambda_function.s3_bucket
}

output "backend_source_key" {
  value = aws_lambda_function.backend_lambda_function.s3_key
}

output "backend_lambda_function_name" {
  value = aws_lambda_function.backend_lambda_function.function_name
}

output "app_url" {
  value = "https://${aws_route53_record.frontend.fqdn}"
}