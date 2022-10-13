# Comment

resource "aws_s3_bucket" "main" {
  bucket = local.localBucketName

  acl    = "private"
  policy = data.aws_iam_policy_document.bucket_policy.json

  website {
    index_document = var.index_document
    error_document = var.error_document
    routing_rules  = var.routing_rules
  }

  versioning {
    enabled = true
  }

  force_destroy = var.force_destroy

  # Transfer acceleration is not possible right now for hosted sites,
  # as bucket names cannot contain a dot.
  # https://docs.aws.amazon.com/AmazonS3/latest/userguide/BucketRestrictions.html
  acceleration_status = var.acceleration_status

  tags = merge(
    var.tags,
    {
      "Name" = var.fqdn
    },
  )
}
