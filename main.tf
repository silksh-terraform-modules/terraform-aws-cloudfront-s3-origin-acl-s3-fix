resource "aws_s3_bucket" "b" {
  bucket = var.source_bucket
  force_destroy = true
}

resource "aws_s3_bucket_policy" "b" {
  bucket = aws_s3_bucket.b.bucket
  policy = <<EOF
{
  "Version":"2012-10-17",
  "Statement":[{
        "Sid":"PublicReadForGetBucketObjects",
        "Effect":"Allow",
          "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::${var.source_bucket}/*"]
    }
  ]
}
EOF
}

resource "aws_s3_bucket_acl" "b" {
  bucket = aws_s3_bucket.b.bucket
  acl = "public-read"
}

resource "aws_s3_bucket_lifecycle_configuration" "b" {
  bucket = aws_s3_bucket.b.bucket
  rule {
    id = var.source_bucket
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_website_configuration" "b" {
  bucket = aws_s3_bucket.b.bucket
  index_document {
    suffix = var.index_document
  }
  error_document {
    key = var.error_document
  }
  routing_rules = var.routing_rules
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.b.website_endpoint
    origin_id   = var.s3_origin_id
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

# react router
  custom_error_response {
    error_caching_min_ttl = 60
    error_code            = 403
    response_code         = 200
    response_page_path    = "${var.custom_error_index_document}"
  }

  custom_error_response {
    error_caching_min_ttl = 60
    error_code            = 404
    response_code         = 200
    response_page_path    = "${var.custom_error_index_document}"
  }

  logging_config {
    include_cookies = false
    bucket          = "${var.logs_bucket}.s3.amazonaws.com"
    prefix          = var.source_bucket
  }

  aliases = [var.app_domain_name]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    dynamic "lambda_function_association" {
      for_each = var.lambda_association == null ? [] : var.lambda_association
      content {
        event_type = lambda_function_association.value.event_type
        include_body = lambda_function_association.value.include_body
        lambda_arn = lambda_function_association.value.lambda_arn
      }
    }

    dynamic "function_association" {
      for_each = var.function_association == null ? [] : var.function_association
      content {
        event_type = function_association.value.event_type
        function_arn = function_association.value.function_arn
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
    compress               = var.compress
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
  depends_on = [aws_s3_bucket.b]
}

resource "aws_route53_record" "web_record" {
  zone_id = var.zone_id # Replace with your zone ID
  name    = "${var.app_domain_name}."                    # Replace with your name/domain/subdomain
  type    = "A"

  alias {
    name                   = replace(aws_cloudfront_distribution.s3_distribution.domain_name, "/[.]$/", "")
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }

  depends_on = [aws_cloudfront_distribution.s3_distribution]
}