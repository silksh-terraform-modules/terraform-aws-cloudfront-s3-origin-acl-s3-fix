resource "aws_cloudfront_function" "basicauth" {
  name    = "basicauth"
  runtime = "cloudfront-js-1.0"
  publish = true
  code    = templatefile("${path.module}/templates/functions/basicauth.js", {
    # base64 from: `echo -n "user:password" |base64`
    basicauth_string = "dXNlcjpwYXNzd29yZA=="
  })
}

module "cloudfront_app_example" {

  source = "github.com/silksh-terraform-modules/terraform-aws-cloudfront-s3-origin?ref=v0.0.1"

  app_domain_name = "example.${var.tld}"
  # remember to add the following bucket to the eligible ones in iam_deployment_user.tf
  source_bucket = "example.${var.tld}"
  # bucket of logs created earlier
  logs_bucket = module.cloudfront_log_storage.bucket_id
  s3_origin_id = "exampleS3Origin"
  acm_certificate_arn = data.terraform_remote_state.infra.outputs.ssl_cert_certificate_arn_dao_us
  zone_id = data.terraform_remote_state.infra.outputs.ssl_cert_zone_id_dao_us
  comment = "${var.tld} example site"
  geo_restriction = false
  
  create_redirect = true
  rf_source_bucket = "www.example.${var.tld}"
  rf_domain_name = "www.example.${var.tld}"

  function_association = [{
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.basicauth.arn
    }]
  
  # restriction_locations = ["PL"]
  
  ## optional redirects: 
  ## /prefix -> /prefix.html
  ## /pre-fix -> /prefix.html
  # routing_rules = jsonencode(
  #   [
  #     {
  #       Condition = {
  #         KeyPrefixEquals = "prefix"
  #       }
  #       Redirect  = {
  #         HostName              = "example.${var.tld}"
  #         Protocol              = "https"
  #         ReplaceKeyPrefixWith  = "prefix.html"
  #       }
  #     },
  #     {
  #       Condition = {
  #         KeyPrefixEquals = "pre-fix"
  #         HttpErrorCodeReturnedEquals = "404"
  #       }
  #       Redirect  = {
  #         HostName              = "example.${var.tld}"
  #         Protocol              = "https"
  #         ReplaceKeyPrefixWith  = "prefix.html"
  #       }
  #     }
  #   ]
  # )
}

output example_app_domain_name {
  value = module.cloudfront_app_example.app_domain_name
}