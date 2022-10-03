data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_s3_bucket" "security" {
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }
  bucket_prefix = "jit-security-${data.aws_region.current.name}"
  acl           = "private"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    "Name" : "Security Bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.security.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_policy" "enable_guardduty" {
  name        = "enable-guardduty-${data.aws_region.current.name}"
  path        = "/"
  description = "Allows setup and configuration of GuardDuty"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "guardduty:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/guardduty.amazonaws.com/AWSServiceRoleForAmazonGuardDuty",
            "Condition": {
                "StringLike": {
                    "iam:AWSServiceName": "guardduty.amazonaws.com"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy"
            ],
            "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/guardduty.amazonaws.com/AWSServiceRoleForAmazonGuardDuty"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "use_security_bucket" {
  name        = "access-security-bucket-${data.aws_region.current.name}"
  path        = "/security/"
  description = "Allows full access to the contents of the security bucket"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListAllMyBuckets",
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "${aws_s3_bucket.security.arn}",
        "${aws_s3_bucket.security.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_group" "guardduty" {
  name = "${var.group_name}-${data.aws_region.current.name}"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "enable" {
  group      = aws_iam_group.guardduty.name
  policy_arn = aws_iam_policy.enable_guardduty.arn
}

resource "aws_iam_group_policy_attachment" "useS3bucket" {
  group      = aws_iam_group.guardduty.name
  policy_arn = aws_iam_policy.use_security_bucket.arn
}

resource "aws_iam_group_policy_attachment" "access" {
  group      = aws_iam_group.guardduty.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonGuardDutyFullAccess"
}

resource "aws_iam_group_policy_attachment" "s3readonly" {
  group      = aws_iam_group.guardduty.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_group_membership" "guardduty" {
  name  = "guardduty-admin-members-${data.aws_region.current.name}"
  group = aws_iam_group.guardduty.name
  users = var.users
}

resource "aws_guardduty_detector" "guardduty" {
  enable = true
}
