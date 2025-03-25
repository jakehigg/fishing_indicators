###############################################
#
# Route53 Config
#
###############################################
resource "aws_route53_record" "frontend" {
  provider = aws.root
  zone_id  = var.r53_zone_id
  name     = local.frontend_fqdn
  type     = "CNAME"
  ttl      = 300
  records  = [aws_cloudfront_distribution.app_distribution.domain_name]
}
