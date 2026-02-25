# ── General ──────────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "ap-northeast-1"
}

variable "project" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev / stg / prod)"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "environment must be one of: dev, stg, prod."
  }
}

# ── Networking ────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ, minimum 2)"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets used by ALB and ECS (one per AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for isolated DB subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

# ── Bastion ───────────────────────────────────────────────────────────────────

variable "windows_bastion_instance_type" {
  description = "Instance type for the Windows bastion (t3.medium minimum recommended for Windows Server)"
  type        = string
  default     = "t3.medium"
}

# ── ECS ───────────────────────────────────────────────────────────────────────

variable "app_image_tag" {
  description = "Image tag to deploy from the ECR repository created by this pattern"
  type        = string
  default     = "latest"
}

variable "app_port" {
  description = "Port the application container listens on"
  type        = number
  default     = 8080
}

variable "app_cpu" {
  description = "Fargate task CPU units (256 / 512 / 1024 / 2048 / 4096)"
  type        = number
  default     = 512
}

variable "app_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 1024
}

variable "app_desired_count" {
  description = "Desired number of ECS task instances"
  type        = number
  default     = 2
}

variable "efs_container_path" {
  description = "EFS ボリュームをマウントするコンテナ内のパス"
  type        = string
  default     = "/mnt/efs"
}

variable "efs_log_paths" {
  description = "EFS 上のアプリログファイルパス一覧（Fluent Bit の tail input に使用）。glob パターン可。<TASKID> はコンテナ起動時に ECS タスク ID に置換される"
  type        = list(string)
  default     = ["/mnt/efs/logs/<TASKID>/*.log"]
}

variable "alb_sticky_session_cookie_name" {
  description = "ALB スティッキーセッションに使用するアプリ Cookie 名（アプリが Set-Cookie で発行する名前と一致させること）"
  type        = string
  default     = "JSESSIONID"
}

variable "health_check_path" {
  description = "ヘルスチェックパス。Tomcat HealthCheckValve のパスと一致させること"
  type        = string
  default     = "/health-check"
}

# ── Oracle RDS ────────────────────────────────────────────────────────────────

variable "db_name" {
  description = "Oracle SID（最大8文字、英字始まり）"
  type        = string
  default     = "ORCL"

  validation {
    condition     = length(var.db_name) <= 8 && can(regex("^[A-Za-z][A-Za-z0-9]*$", var.db_name))
    error_message = "db_name (Oracle SID) must be 1-8 alphanumeric characters starting with a letter."
  }
}

variable "db_master_username" {
  description = "Oracle RDS マスターユーザー名（sys / system / oracle などの予約語は使用不可）"
  type        = string
  default     = "dbadmin"
}

variable "db_engine_version" {
  description = "Oracle SE2 エンジンバージョン（例: 19.0.0.0.ru-2025-01.rur-2025-01.r1）。利用可能なバージョンは `aws rds describe-db-engine-versions --engine oracle-se2` で確認すること"
  type        = string
}

variable "db_instance_class" {
  description = "Oracle RDS インスタンスクラス（oracle-se2 は ARM 非対応のため db.t4g 系は使用不可）"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Oracle RDS に割り当てるストレージ容量 (GiB)。最小 10 GiB"
  type        = number
  default     = 20
}
