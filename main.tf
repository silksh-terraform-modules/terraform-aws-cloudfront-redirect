locals {
  origin_id = "${replace(var.target_domain_name, "/[./]/", "")}Redir" 
}

resource "aws_s3_bucket" "redirect" {
  bucket = var.source_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_policy" "redirect" {
  depends_on = [
    aws_s3_bucket_ownership_controls.redirect,
    aws_s3_bucket_public_access_block.redirect,
  ]
  bucket = aws_s3_bucket.redirect.bucket
  policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[{
        "Sid":"PublicReadForGetBucketObjects",
        "Effect":"Allow",
          "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::${var.source_bucket_name}/*"]
    }
  ]
}
EOF
}

resource "aws_s3_bucket_ownership_controls" "redirect" {
  bucket = aws_s3_bucket.redirect.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "redirect" {
  bucket = aws_s3_bucket.redirect.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  depends_on = [
    aws_s3_bucket_ownership_controls.redirect,
  ]
}

resource "aws_s3_bucket_acl" "redirect" {
  bucket = aws_s3_bucket.redirect.bucket
  acl = "public-read"

  depends_on = [
    aws_s3_bucket_ownership_controls.redirect,
    aws_s3_bucket_public_access_block.redirect,
  ]
}

resource "aws_s3_bucket_lifecycle_configuration" "redirect" {
  bucket = aws_s3_bucket.redirect.bucket
  rule {
    id = var.source_bucket_name
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_website_configuration" "redirect" {
  bucket = aws_s3_bucket.redirect.bucket
  
  redirect_all_requests_to {
    protocol = "https"
    host_name = "${var.target_domain_name}"
  }
}

resource "aws_cloudfront_distribution" "s3_distribution_redirect" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.redirect.website_endpoint
    origin_id   = local.origin_id
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.comment

  aliases = var.source_domain_name

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    # min_ttl                = var.min_ttl
    # default_ttl            = var.default_ttl
    # max_ttl                = var.max_ttl
    # compress               = var.compress
  }

  price_class = var.price_class

  restrictions {
    dynamic "geo_restriction" {
      for_each = var.geo_restriction ? [] : [1]
      content {
         restriction_type = "none"
      }
    }

    dynamic "geo_restriction" {
      for_each = var.geo_restriction ? [1] : []
      content {
         restriction_type = "whitelist"
         locations        = var.restriction_locations
      }
    }

  }

  viewer_certificate {
    acm_certificate_arn = var.acm_certificate_arn
    minimum_protocol_version = var.minimum_protocol_version
    ssl_support_method = "sni-only"
  }
  depends_on = [aws_s3_bucket.redirect]
}

resource "aws_route53_record" "web_record_redirect" {
  for_each = toset(var.source_domain_name)
  zone_id = var.zone_id # Replace with your zone ID
  name    = each.value 
  type    = "A"

  alias {
    name                   = replace(aws_cloudfront_distribution.s3_distribution_redirect.domain_name, "/[.]$/", "")
    zone_id                = aws_cloudfront_distribution.s3_distribution_redirect.hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [aws_cloudfront_distribution.s3_distribution_redirect]
}