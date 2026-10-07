##############################################################################
# My front end: S3 + CloudFront + a DNS record
#
# CloudFront is the one front door to my site. It gets my pages from S3, and it
# passes anything under /api/ to my API (see appbackend.tf).
##############################################################################

locals {
  frontend_fqdn = "${var.subdomain}.${var.domain_name}"
  # Bucket names must be unique in all of AWS, so I add my account id to the name
  bucket_name = "${var.project_name}-frontend-${data.aws_caller_identity.current.account_id}"
  s3_origin   = "s3-frontend"
  api_origin  = "api-gateway"
}

# --- The S3 bucket that holds my site files. It is private. -------------------

resource "aws_s3_bucket" "frontend" {
  bucket = local.bucket_name
  # This lets "terraform destroy" delete the bucket even when it has files in
  # it. That is safe here because all my files are also in Git.
  force_destroy = true

  tags = {
    Name = local.bucket_name
  }
}

resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- CloudFront ----------------------------------------------------------------

# This is how I keep the bucket private. CloudFront signs every request it
# sends to S3, and S3 only answers CloudFront. Nobody can open the bucket directly.
resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${var.project_name}-oac"
  description                       = "OAC for ${local.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [local.frontend_fqdn]
  # The cheapest option: CloudFront servers in North America and Europe only
  price_class = "PriceClass_100"

  # Source 1: my site files in S3
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = local.s3_origin
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  # Source 2: my API (API Gateway, which runs my Lambda)
  origin {
    domain_name = replace(aws_apigatewayv2_api.api.api_endpoint, "https://", "")
    origin_id   = local.api_origin

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = local.s3_origin
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.optimized.id
    # Adds my browser safety headers to every page (see below)
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
  }

  # Anything under /api/ goes to my API and is never saved as a copy, so
  # visitors always get a fresh answer.
  # I left out custom error pages on purpose. They would hide my API's real
  # error answers behind my home page.
  ordered_cache_behavior {
    path_pattern             = "/api/*"
    target_origin_id         = local.api_origin
    viewer_protocol_policy   = "https-only"
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    compress                 = true
    cache_policy_id          = data.aws_cloudfront_cache_policy.disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.frontend.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name = local.frontend_fqdn
  }
}

# --- Browser safety headers ----------------------------------------------------

# These are instructions CloudFront sends to the visitor's browser with every
# page. My site looks the same, but the browser gets stricter about it:
#   - always use HTTPS for my site (for one year)
#   - trust the file type I send, don't guess
#   - never show my site inside another site's frame (stops fake overlays)
#   - when someone clicks a link out, only tell the other site my domain
#   - no plugins, and no tricks that change where my links point
resource "aws_cloudfront_response_headers_policy" "security" {
  name    = "${var.project_name}-security-headers"
  comment = "Browser safety headers for my CV site"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = false
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    content_security_policy {
      content_security_policy = "frame-ancestors 'none'; object-src 'none'; base-uri 'self'"
      override                = true
    }
  }
}

# --- The bucket rule: only my CloudFront is allowed to read the files ---------

data "aws_iam_policy_document" "frontend" {
  statement {
    sid       = "AllowCloudFrontServicePrincipalReadOnly"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.frontend.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend.json

  depends_on = [aws_s3_bucket_public_access_block.frontend]
}

# --- DNS: point cv.eliadablah.com at CloudFront (IPv4 and IPv6) ---------------

resource "aws_route53_record" "frontend" {
  for_each = toset(["A", "AAAA"])

  zone_id = data.aws_route53_zone.selected.zone_id
  name    = local.frontend_fqdn
  type    = each.key

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}
