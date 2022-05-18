# user definition with access to s3 buckets with application scripts
# for gitlab deployment
resource "aws_iam_user" "s3_cf_apps_uploader" {
  name = "s3_cf_apps_uploader_${var.env_name}"
  tags = {
    description = "user with permissions to upload static apps to appropriate s3 buckets"
  }
}

resource "aws_iam_access_key" "s3_cf_apps_uploader" {
  user = aws_iam_user.s3_cf_apps_uploader.name
}

resource "aws_iam_policy_attachment" "s3_cf_apps_uploader" {
  name       = "s3_cf_apps_uploader"
  users      = [aws_iam_user.s3_cf_apps_uploader.name]
  policy_arn = aws_iam_policy.s3_cf_apps_upload.arn
}

resource "aws_iam_policy" "s3_cf_apps_upload" {
  name = "s3_cf_apps_upload_${var.env_name}"

  policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation",
                "s3:ListBucketMultipartUploads"
            ],
            "Resource": [
                "${module.cloudfront_app_example.bucket_arn}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:GetObjectAcl",
                "s3:GetObjectVersion",
                "s3:GetObjectVersionAcl",
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "${module.cloudfront_app_example.bucket_arn}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "s3:ListAllMyBuckets",
            "Resource": "*",
            "Condition": {}
        }
    ]
}
DOC
}
