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
  default     = 1
}

# ── Aurora PostgreSQL ─────────────────────────────────────────────────────────

variable "db_name" {
  description = "Name of the initial database to create in Aurora"
  type        = string
}

variable "db_master_username" {
  description = "Master username for Aurora"
  type        = string
  default     = "postgres"
}

variable "db_instance_class" {
  description = "Aurora instance class"
  type        = string
  default     = "db.t4g.medium"
}

variable "db_instance_count" {
  description = "Number of Aurora cluster instances (1 = writer only)"
  type        = number
  default     = 1
}
