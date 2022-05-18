module "cloudfront_log_storage" {
  source = "cloudposse/s3-log-storage/aws"
  # Cloud Posse recommends pinning every module to a specific version
  version = "0.24.0"
  name                     = "${var.project_full_name}-cloudfront-logs-${var.env_name}"
  acl                      = "log-delivery-write"
  standard_transition_days = 30
  glacier_transition_days  = 90
  expiration_days          = 180
}