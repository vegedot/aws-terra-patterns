resource "random_password" "db" {
  length           = 28 # Oracle RDS パスワードは最大30文字
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${local.name_prefix}/oracle/credentials"
  recovery_window_in_days = 0 # Allow immediate deletion for PoC
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = var.db_master_username
    password = random_password.db.result
    engine   = "oracle-se2"
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
  })
}
