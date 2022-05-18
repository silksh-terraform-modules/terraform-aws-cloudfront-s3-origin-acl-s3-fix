output "zone_id" {
  value = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
}

output "domain_name" {
  # value = "${aws_cloudfront_distribution.s3_distribution.domain_name}"
  value = replace(aws_cloudfront_distribution.s3_distribution.domain_name, "/[.]$/", "")
}

output "app_domain_name" {
  # value = "${aws_cloudfront_distribution.s3_distribution.domain_name}"
  value = replace(aws_route53_record.web_record.name, "/[.]$/", "")
}

output "bucket_arn" {
  value = aws_s3_bucket.b.arn
}