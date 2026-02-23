# ── Bastion ───────────────────────────────────────────────────────────────────

resource "aws_security_group" "bastion" {
  name        = "${local.name_prefix}-bastion-sg"
  description = "SSM-managed Linux bastion. No inbound rules needed"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${local.name_prefix}-bastion-sg" }
}

# インバウンドルールなし（SSM はアウトバウンド通信のみで動作する）

resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ── Windows Bastion ───────────────────────────────────────────────────────────

resource "aws_security_group" "windows_bastion" {
  name        = "${local.name_prefix}-windows-bastion-sg"
  description = "SSM-managed Windows bastion. No inbound rules needed"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${local.name_prefix}-windows-bastion-sg" }
}

# インバウンドルールなし（SSM はアウトバウンド通信のみで動作する）

resource "aws_vpc_security_group_egress_rule" "windows_bastion_all" {
  security_group_id = aws_security_group.windows_bastion.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ── ALB (Internal) ────────────────────────────────────────────────────────────

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Allow HTTP from Linux and Windows bastions"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${local.name_prefix}-alb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_from_bastion" {
  security_group_id            = aws_security_group.alb.id
  description                  = "HTTP from Linux bastion"
  referenced_security_group_id = aws_security_group.bastion.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_from_windows_bastion" {
  security_group_id            = aws_security_group.alb.id
  description                  = "HTTP from Windows bastion"
  referenced_security_group_id = aws_security_group.windows_bastion.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ── ECS Fargate ───────────────────────────────────────────────────────────────

resource "aws_security_group" "ecs" {
  name        = "${local.name_prefix}-ecs-sg"
  description = "Allow app port from ALB"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${local.name_prefix}-ecs-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_app_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "App port from ALB"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

resource "aws_vpc_security_group_egress_rule" "ecs_all" {
  security_group_id = aws_security_group.ecs.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ── Aurora PostgreSQL ─────────────────────────────────────────────────────────

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "Allow PostgreSQL from ECS tasks"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${local.name_prefix}-rds-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "rds_pg_from_ecs" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from ECS tasks"
  referenced_security_group_id = aws_security_group.ecs.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

# ── VPC Endpoints ─────────────────────────────────────────────────────────────

resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.name_prefix}-vpc-endpoints-sg"
  description = "Allow HTTPS from VPC to SSM interface endpoints"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${local.name_prefix}-vpc-endpoints-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_https" {
  security_group_id = aws_security_group.vpc_endpoints.id
  description       = "HTTPS from VPC CIDR"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
