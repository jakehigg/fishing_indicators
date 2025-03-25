###############################################
#
# Cloudfront Config
#
###############################################

resource "aws_cloudfront_origin_access_control" "distribution_oac" {
  provider                          = aws.target
  name                              = local.cloudfront_oac_name
  description                       = "Allows access from Cloudfront to S3 to Bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
resource "aws_cloudfront_response_headers_policy" "frontend_security_headers_policy" {
  provider = aws.target
  name     = "${local.cleaned_app_name}_frontend_${local.cleaned_app_environment}_policy"
  cors_config {
    access_control_allow_credentials = true
    access_control_allow_headers {
      items = ["Content-Type", "Authorization"] # Allow all headers
    }
    access_control_allow_methods {
      items = ["GET", "POST", "OPTIONS"]
    }
    access_control_allow_origins {
      items = ["${local.frontend_fqdn}"]
    }
    # access_control_expose_headers {
    #   items = ["*"]  # Allow all response headers to be exposed
    # }
    origin_override = true
  }
  security_headers_config {
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "same-origin"
      override        = true
    }
    strict_transport_security {
      access_control_max_age_sec = "63072000"
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    content_security_policy {
      content_security_policy = trimspace(chomp(var.frontend_csp))
      override                = true
    }
  }
}

resource "aws_cloudfront_distribution" "app_distribution" {
  provider            = aws.target
  enabled             = true
  default_root_object = "index.html"
  aliases             = [local.frontend_fqdn]

  default_cache_behavior {
    allowed_methods        = ["HEAD", "GET", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.app_bucket.bucket
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    min_ttl     = 0
    default_ttl = 5 * 60
    max_ttl     = 60 * 60

    response_headers_policy_id = aws_cloudfront_response_headers_policy.frontend_security_headers_policy.id

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.cleaned_app_name}-${local.cleaned_app_environment}-apigw"

    response_headers_policy_id = aws_cloudfront_response_headers_policy.frontend_security_headers_policy.id

    forwarded_values {
      query_string = true
      # headers      = ["Authorization"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern     = "/*"
    allowed_methods  = ["HEAD", "GET", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.app_bucket.bucket

    response_headers_policy_id = aws_cloudfront_response_headers_policy.frontend_security_headers_policy.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  origin {
    domain_name              = aws_s3_bucket.app_bucket.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.app_bucket.bucket
    origin_access_control_id = aws_cloudfront_origin_access_control.distribution_oac.id
  }

  origin {
    domain_name = "${aws_api_gateway_rest_api.api_gw.id}.execute-api.${var.aws_region}.amazonaws.com"
    origin_id   = "${local.cleaned_app_name}-${local.cleaned_app_environment}-apigw"
    # origin_path = "/${lower(var.tag_app_environment)}"
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # custom_error_response {
  #   error_code = "403"
  #   response_code = "200"
  #   response_page_path = "/index.html"
  # }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US"]
    }
  }

  viewer_certificate {
    # Huh? Another spoiler?
    acm_certificate_arn      = local.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  price_class = "PriceClass_100"
  tags = {
    Application = var.app_name
    Environment = local.app_environment
    Terraform   = true
  }
}