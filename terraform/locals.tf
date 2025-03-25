locals {
  # Buckets
  backend_source_bucket = "${lower(var.aws_account_name)}-${lower(var.app_name)}-${var.backend_source_bucket_name}-${local.cleaned_app_environment}"
  frontend_app_bucket   = "${lower(var.aws_account_name)}-${lower(var.app_name)}-${var.frontend_app_bucket_name}-${local.cleaned_app_environment}"

  # CloudFront
  cloudfront_oac_name = "${local.cleaned_app_name}-${local.cleaned_app_environment}-oac"
  acm_certificate_arn = terraform.workspace == "prod" ? "${var.prod_acm_certificate_arn}" : "${var.dev_acm_certificate_arn}"

  # Clean/Env Variables
  frontend_fqdn           = terraform.workspace == "prod" ? "${lower(var.app_name)}.${var.domain_name}" : "${lower(var.app_name)}-dev.${var.domain_name}"
  target_account_role_arn = terraform.workspace == "prod" ? "${var.prod_target_account_role_arn}" : "${var.dev_target_account_role_arn}"
  cleaned_app_name        = replace(lower(var.app_name), " ", "-")
  cleaned_app_environment = replace(lower(local.app_environment), " ", "-")
  app_environment         = terraform.workspace == "prod" ? "Prod" : "Dev"
}