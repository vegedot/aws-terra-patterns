resource "aws_efs_file_system" "app" {
  encrypted = true

  tags = { Name = "${local.name_prefix}-efs" }
}

# プライベートサブネット各 AZ にマウントターゲットを作成（ECS タスクと同じサブネット）
resource "aws_efs_mount_target" "app" {
  count           = length(aws_subnet.private)
  file_system_id  = aws_efs_file_system.app.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}
