variable "aws_account_id" {
  type    = string
  default = "12345678"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "dev_target_account_role_arn" {
  type        = string
  default     = "arn:aws:iam::12345678:role/service-role/MyDevTargetAccountRole"
  description = "The ARN of the deployment Role in the Dev account"
}

variable "prod_target_account_role_arn" {
  type        = string
  default     = "arn:aws:iam::12345678:role/service-role/MyDevTargetAccountRole"
  description = "The ARN of the deployment Role in the Prod account"
}

variable "aws_account_name" {
  type        = string
  default     = "my-account"
  description = "This is the name of the AWS account, which will be used as a prefix where needed for global resource names"
}

variable "app_name" {
  type        = string
  default     = "FishingIndicators"
  description = "This will also be used as the host record: https://{app_name}.{domain_name}"
}

variable "frontend_app_bucket_name" {
  type    = string
  default = "frontend"
}

variable "backend_source_bucket_name" {
  type        = string
  default     = "backend-source"
  description = "This is the name of the source bucket that will be added to the account_name prefix, and the environment suffix will be added as well"
}

variable "backend_lambda_package_name" {
  type    = string
  default = "hello.zip"
}

variable "frontend_csp" {
  type    = string
  default = "default-src 'self' user-script:; img-src 'self' data:; script-src 'self' blob:; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com/ https://api.tiles.mapbox.com/; connect-src 'self' https://api.mapbox.com/ https://events.mapbox.com/; object-src 'self'; font-src 'self' https://fonts.gstatic.com"

}

variable "domain_name" {
  type    = string
  default = "example.com"
}

variable "dev_acm_certificate_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:12345678:certificate/example"
}

variable "prod_acm_certificate_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:12345678:certificate/example"
}

variable "r53_zone_id" {
  type    = string
  default = "ASDF1234"
}

# variable "certificate_domain" {
#     type = string
# }



