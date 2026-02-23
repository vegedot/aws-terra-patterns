resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.db[*].id
}

resource "aws_rds_cluster" "this" {
  cluster_identifier      = "${local.name_prefix}-aurora"
  engine                  = "aurora-postgresql"
  engine_version          = "16.6"
  database_name           = var.db_name
  master_username         = var.db_master_username
  master_password         = random_password.db.result
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  storage_encrypted       = true
  backup_retention_period = 1
  skip_final_snapshot     = true  # PoC: 本番では false にしてスナップショットを取得すること
  deletion_protection     = false # PoC: 本番では true に変更すること
  apply_immediately       = true  # PoC: 本番では false にしてメンテナンスウィンドウで適用すること
}

resource "aws_rds_cluster_instance" "this" {
  count              = var.db_instance_count
  identifier         = "${local.name_prefix}-aurora-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.db_instance_class
  engine              = aws_rds_cluster.this.engine
  engine_version      = aws_rds_cluster.this.engine_version
  publicly_accessible = false
  apply_immediately   = true # PoC: 本番では false にしてメンテナンスウィンドウで適用すること
}
