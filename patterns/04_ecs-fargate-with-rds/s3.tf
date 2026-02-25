data "aws_elb_service_account" "main" {}

# ALB アクセスログ用バケット
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${local.name_prefix}-alb-logs"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ALB サービスアカウントからの PutObject を許可
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = data.aws_elb_service_account.main.arn }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.alb_logs.arn}/AWSLogs/*"
    }]
  })
}

# ── 開発用ファイル共有バケット（Bastion からのみアクセス可）
resource "aws_s3_bucket" "dev_files" {
  bucket        = "${local.name_prefix}-files"
  force_destroy = true # PoC: 本番では false にすること
}

resource "aws_s3_bucket_public_access_block" "dev_files" {
  bucket = aws_s3_bucket.dev_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dev_files" {
  bucket = aws_s3_bucket.dev_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
