# Things I already have in my AWS account. I only look them up here, I don't create them.

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

# My HTTPS certificate. CloudFront only accepts certificates from us-east-1.
data "aws_acm_certificate" "frontend" {
  domain      = coalesce(var.certificate_domain, var.domain_name)
  statuses    = ["ISSUED"]
  most_recent = true
}

# Ready-made CloudFront rules from AWS. I use them so I don't have to write my own.
data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}
