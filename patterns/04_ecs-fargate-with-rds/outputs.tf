output "ecr_repository_url" {
  description = "ECR repository URL. Push your image here before starting the ECS service"
  value       = aws_ecr_repository.app.repository_url
}

output "linux_bastion_instance_id" {
  description = "Linux bastion instance ID (use with: aws ssm start-session --target <id>)"
  value       = aws_instance.bastion.id
}

output "windows_bastion_instance_id" {
  description = "Windows bastion instance ID (use in AWS Console > Fleet Manager to start RDP session)"
  value       = aws_instance.windows_bastion.id
}

output "alb_dns_name" {
  description = "Internal ALB DNS name (accessible from within the VPC via bastion)"
  value       = aws_lb.this.dns_name
}

output "oracle_endpoint" {
  description = "Oracle RDS instance endpoint"
  value       = aws_db_instance.this.address
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding Oracle RDS credentials"
  value       = aws_secretsmanager_secret.db.arn
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

output "dev_files_bucket_name" {
  description = "開発用ファイル共有 S3 バケット名（Bastion から aws s3 cp などで使用）"
  value       = aws_s3_bucket.dev_files.bucket
}

output "efs_file_system_id" {
  description = "EFS ファイルシステム ID（コンテナ内 var.efs_container_path にマウント済み）"
  value       = aws_efs_file_system.app.id
}
