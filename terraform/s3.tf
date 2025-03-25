###############################################
#
# S3 Config
#
###############################################

resource "aws_s3_bucket" "app_bucket" {
  provider = aws.target
  bucket   = local.frontend_app_bucket
  tags = {
    Application = var.app_name
    Environment = local.app_environment
    Terraform   = true
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket" "backend_source_bucket" {
  provider = aws.target
  bucket   = local.backend_source_bucket
  tags = {
    Application = var.app_name
    Environment = local.app_environment
    Terraform   = true
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  provider = aws.target
  bucket   = aws_s3_bucket.backend_source_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "default" {
  provider = aws.target
  bucket   = aws_s3_bucket.app_bucket.id
  policy   = data.aws_iam_policy_document.cloudfront_oac_access.json
}

data "aws_iam_policy_document" "cloudfront_oac_access" {
  provider = aws.target
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      aws_s3_bucket.app_bucket.arn,
      "${aws_s3_bucket.app_bucket.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.app_distribution.arn]
    }
  }
}