# 開発用ファイル共有バケット（Bastion からのみアクセス可）
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
