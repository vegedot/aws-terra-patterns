resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.db[*].id
}

resource "aws_db_instance" "this" {
  identifier     = "${local.name_prefix}-oracle"
  engine         = "oracle-se2"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class
  license_model  = "license-included"

  db_name  = var.db_name # Oracle SID（最大8文字、英字始まり）
  username = var.db_master_username
  password = random_password.db.result

  allocated_storage = var.db_allocated_storage
  storage_encrypted = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 1
  skip_final_snapshot     = true  # PoC: 本番では false にしてスナップショットを取得すること
  deletion_protection     = false # PoC: 本番では true に変更すること
  apply_immediately       = true  # PoC: 本番では false にしてメンテナンスウィンドウで適用すること
  publicly_accessible     = false
  multi_az                = false # PoC: 本番では true にすることを検討すること
}
