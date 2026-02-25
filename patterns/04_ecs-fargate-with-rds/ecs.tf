locals {
  # var.efs_log_paths の各パスに対して [INPUT] ブロックを生成する
  # printf に渡すため \n は文字列としての \n（バックスラッシュ + n）で表現する
  fluent_bit_inputs = join("\\n", [
    for i, path in var.efs_log_paths :
    "[INPUT]\\n    Name tail\\n    Path ${path}\\n    Tag app.${i}\\n    DB /tmp/fluent-bit-${i}.db\\n    Refresh_Interval 5"
  ])
}

resource "aws_ecs_cluster" "this" {
  name = "${local.name_prefix}-cluster"
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.name_prefix}-app"
  retention_in_days = 7
}

# EFS ファイルログ用（Fluent Bit サイドカーが書き込む）
resource "aws_cloudwatch_log_group" "app_files" {
  name              = "/ecs/${local.name_prefix}-app-files"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${local.name_prefix}-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.app_cpu
  memory                   = var.app_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = "app"
    image     = "${aws_ecr_repository.app.repository_url}:${var.app_image_tag}"
    essential = true

    portMappings = [{
      containerPort = var.app_port
      protocol      = "tcp"
    }]

    # DB 接続情報を Secrets Manager から取得して環境変数として注入
    secrets = [
      {
        name      = "DB_USERNAME"
        valueFrom = "${aws_secretsmanager_secret.db.arn}:username::"
      },
      {
        name      = "DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.db.arn}:password::"
      }
    ]

    environment = [
      { name = "DB_HOST",        value = aws_db_instance.this.address },
      { name = "DB_PORT",        value = tostring(aws_db_instance.this.port) },
      { name = "DB_NAME",        value = var.db_name },
      # docker-entrypoint.sh がログディレクトリを作成する際のベースパス
      { name = "EFS_MOUNT_PATH", value = var.efs_container_path },
    ]

    # ECS Exec (SSM) がゾンビプロセスを残さないよう init プロセスを有効化
    linuxParameters = {
      initProcessEnabled = true
    }

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:${var.app_port}${var.health_check_path} || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60 # Tomcat 起動時間を考慮
    }

    mountPoints = [{
      sourceVolume  = "efs-volume"
      containerPath = var.efs_container_path
      readOnly      = false
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.app.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  },
  {
    # Fluent Bit サイドカー: EFS 上のアプリログファイルを CloudWatch Logs に転送する
    # ログパスは var.efs_log_paths で変更可能
    name      = "fluent-bit"
    image     = "public.ecr.aws/aws-observability/aws-for-fluent-bit:stable"
    essential = false

    # app コンテナの docker-entrypoint.sh が EFS ログディレクトリを作成してから起動する
    dependsOn = [{
      containerName = "app"
      condition     = "START"
    }]

    command = [
      "/bin/sh", "-c",
      # ECS メタデータエンドポイントからタスク ID を取得し <TASKID> プレースホルダを置換する
      # $ECS_CONTAINER_METADATA_URI_V4 は Terraform 変数でなく実行時の環境変数のため $ のままでよい
      # curl の代わりに wget を使用（aws-for-fluent-bit の Amazon Linux minimal に確実に存在する）
      # dirname の代わりに awk で代替（同様の理由）
      "TASK_ID=$(wget -qO- $ECS_CONTAINER_METADATA_URI_V4/task | grep -o '\"TaskARN\":\"[^\"]*\"' | awk -F/ '{print $NF}' | tr -d '\"'); [ -z \"$TASK_ID\" ] && TASK_ID=local; printf '[SERVICE]\\n    Flush 5\\n    Log_Level info\\n${local.fluent_bit_inputs}\\n[OUTPUT]\\n    Name cloudwatch_logs\\n    Match *\\n    region ${var.aws_region}\\n    log_group_name ${aws_cloudwatch_log_group.app_files.name}\\n    log_stream_prefix task/<TASKID>/\\n    auto_create_group false\\n' > /tmp/fb.conf; sed -i \"s|<TASKID>|$TASK_ID|g\" /tmp/fb.conf; exec /fluent-bit/bin/fluent-bit -c /tmp/fb.conf"
    ]

    mountPoints = [{
      sourceVolume  = "efs-volume"
      containerPath = var.efs_container_path
      readOnly      = true
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.app.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "fluent-bit"
      }
    }
  }])

  volume {
    name = "efs-volume"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.app.id
      transit_encryption = "ENABLED"
    }
  }
}

resource "aws_ecs_service" "app" {
  name            = "${local.name_prefix}-app"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = var.app_port
  }

  enable_execute_command = true # Bastion から `aws ecs execute-command` で接続可能にする

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_lb_listener.http]
}
