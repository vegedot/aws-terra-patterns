# ── Bastion 共通 (SSM) ────────────────────────────────────────────────────────
# Linux / Windows 両 Bastion で共用する IAM ロール

resource "aws_iam_role" "bastion" {
  name = "${local.name_prefix}-bastion"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${local.name_prefix}-bastion"
  role = aws_iam_role.bastion.name
}

resource "aws_iam_role_policy" "bastion_ecs_exec" {
  name = "${local.name_prefix}-bastion-ecs-exec"
  role = aws_iam_role.bastion.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ecs:ExecuteCommand", "ecs:DescribeTasks"]
        Resource = [
          aws_ecs_cluster.this.arn,
          "${aws_ecs_cluster.this.arn}/*", # タスク ARN
        ]
      },
      {
        # ECS Exec が内部的に起動する SSM セッションの開始を許可
        Effect   = "Allow"
        Action   = ["ssm:StartSession"]
        Resource = ["arn:aws:ecs:${var.aws_region}:*:task/${aws_ecs_cluster.this.name}/*"]
      },
    ]
  })
}

resource "aws_iam_role_policy" "bastion_ecr" {
  name = "${local.name_prefix}-bastion-ecr"
  role = aws_iam_role.bastion.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ecr:GetAuthorizationToken"]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
        ]
        Resource = [aws_ecr_repository.app.arn]
      },
    ]
  })
}

resource "aws_iam_role_policy" "bastion_s3" {
  name = "${local.name_prefix}-bastion-s3"
  role = aws_iam_role.bastion.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
      ]
      Resource = [
        aws_s3_bucket.dev_files.arn,
        "${aws_s3_bucket.dev_files.arn}/*",
      ]
    }]
  })
}

# ── ECS Task Role ─────────────────────────────────────────────────────────────
# タスク自身が使用するロール（ECS Exec / アプリの AWS API 呼び出しに使用）
# ※ Task Execution Role（ECR プル・Secrets Manager 取得）とは別物

resource "aws_iam_role" "ecs_task" {
  name = "${local.name_prefix}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Fluent Bit サイドカーが CloudWatch Logs にログを書き込むための権限
resource "aws_iam_role_policy" "ecs_task_cloudwatch_logs" {
  name = "${local.name_prefix}-ecs-task-cloudwatch-logs"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
      ]
      Resource = ["${aws_cloudwatch_log_group.app_files.arn}:*"]
    }]
  })
}

# ECS Exec（SSM Session Manager）に必要な最小権限
resource "aws_iam_role_policy" "ecs_task_exec_command" {
  name = "${local.name_prefix}-ecs-task-exec-command"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel",
      ]
      Resource = ["*"]
    }]
  })
}

# ── ECS Task Execution ────────────────────────────────────────────────────────

resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.name_prefix}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_secrets" {
  name = "${local.name_prefix}-ecs-secrets"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [aws_secretsmanager_secret.db.arn]
    }]
  })
}
