resource "aws_s3_bucket_public_access_block" "positive2354354344543453543345534345453534354" {
  bucket = aws_s3_bucket.example.id

  block_public_acls   = false
  block_public_policy = false
  ignore_public_acls  = false
}

resource "aws_s3_bucket_public_access_block" "positive2354354344rerererer543453543345534345453534354" {
  bucket = aws_s3_bucket.example.id

  block_public_acls   = false
  block_public_policy = false
  ignore_public_acls  = false
}
