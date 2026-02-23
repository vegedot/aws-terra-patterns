# 04 — ECS Fargate + Aurora PostgreSQL (Internal)

ECS Fargate アプリケーションと Aurora PostgreSQL クラスターを、プライベートネットワーク上に構築するパターンです。
ALB は VPC 内部にのみ公開し、Bastion ホスト経由で動作確認を行います。

## アーキテクチャ

```
                          AWS Systems Manager
                                 ↕ (HTTPS アウトバウンドのみ)
[Linux Bastion  - AL2023  t3.micro ] ─┐
[Windows Bastion - WS2025 t3.medium] ─┤  private subnet
                                       │ (HTTP :80)
                                       ▼
                              [ALB - Internal] ── private subnet
                                       │
                                       ▼
                              [ECS Fargate] ────── private subnet
                                       │ (PostgreSQL :5432)
                                       ▼
                              [Aurora PostgreSQL] ── DB subnet
```

- **VPC**: パブリック × 2 / プライベート × 2 / DB × 2 サブネット（各 AZ）。パブリックサブネットは NAT Gateway のみ使用
- **Linux Bastion**: Amazon Linux 2023 (t3.micro)、プライベートサブネット。SSM Session Manager で接続し curl 等で ALB を確認する
- **Windows Bastion**: Windows Server 2025 (t3.medium)、プライベートサブネット。Fleet Manager で RDP 接続し Edge ブラウザで Web UI を確認する
- 両 Bastion ともインバウンドポート開放不要・キーペア不要。IAM ロールで SSM 接続を制御
- **ALB**: Internal。プライベートサブネットに配置。両 Bastion からのみ到達可能
- **ECS Fargate**: プライベートサブネット。ECR からイメージをプル（NAT Gateway 経由）
- **Aurora PostgreSQL 16**: DB サブネット。ECS タスクからのみアクセス可能
- **Secrets Manager**: DB 接続情報（username / password）を保管。ECS タスク起動時に自動注入

## アプリへ渡される環境変数

| 変数名 | 取得元 |
|---|---|
| `DB_USERNAME` | Secrets Manager（JSON キー抽出） |
| `DB_PASSWORD` | Secrets Manager（JSON キー抽出） |
| `DB_HOST` | Aurora writer エンドポイント（環境変数） |
| `DB_PORT` | Aurora ポート（環境変数） |
| `DB_NAME` | `var.db_name`（環境変数） |

## 使い方

```bash
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars を環境に合わせて編集

terraform init
terraform plan
terraform apply
```

apply 完了後、ECR リポジトリ URL・各 Bastion のインスタンス ID・ALB DNS 名が output に表示されます。

ECR へイメージをプッシュしてから ECS サービスが正常起動します:

```bash
aws ecr get-login-password --region ap-northeast-1 \
  | docker login --username AWS --password-stdin <ecr_repository_url>

docker build -t <ecr_repository_url>:latest .
docker push <ecr_repository_url>:latest
```

**Linux Bastion（CLI 確認）:**
```bash
# SSM Session Manager でシェルを開く（AWS CLI + Session Manager Plugin が必要）
aws ssm start-session --target <linux_bastion_instance_id>

# セッション内で ALB へリクエスト
curl http://<alb_dns_name>/health
```

**Windows Bastion（ブラウザ確認）:**

1. AWS コンソール → **Systems Manager** → **Fleet Manager**
2. `<windows_bastion_instance_id>` を選択
3. **Node actions** → **Start Remote Desktop session**
4. Edge ブラウザで `http://<alb_dns_name>` を開いてアプリを確認

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project` | プロジェクト名 | `string` | — | yes |
| `environment` | デプロイ環境 (dev/stg/prod) | `string` | — | yes |
| `aws_region` | AWSリージョン | `string` | `ap-northeast-1` | no |
| `windows_bastion_instance_type` | Windows Bastion インスタンスタイプ | `string` | `t3.medium` | no |
| `app_image_tag` | ECR にプッシュしたイメージタグ | `string` | `latest` | no |
| `app_port` | アプリのリスニングポート | `number` | `8080` | no |
| `app_cpu` | Fargate CPU ユニット | `number` | `512` | no |
| `app_memory` | Fargate メモリ (MiB) | `number` | `1024` | no |
| `app_desired_count` | ECS タスク数 | `number` | `1` | no |
| `db_name` | 初期 DB 名 | `string` | — | yes |
| `db_master_username` | Aurora マスターユーザー名 | `string` | `postgres` | no |
| `db_instance_class` | Aurora インスタンスクラス | `string` | `db.t4g.medium` | no |
| `db_instance_count` | Aurora インスタンス数 | `number` | `1` | no |

## Outputs

| Name | Description |
|---|---|
| `ecr_repository_url` | ECR リポジトリ URL（イメージのプッシュ先） |
| `linux_bastion_instance_id` | Linux Bastion のインスタンス ID（SSM start-session で使用） |
| `windows_bastion_instance_id` | Windows Bastion のインスタンス ID（Fleet Manager で使用） |
| `alb_dns_name` | Internal ALB の DNS 名 |
| `aurora_endpoint` | Aurora Writer エンドポイント |
| `aurora_reader_endpoint` | Aurora Reader エンドポイント |
| `db_secret_arn` | Secrets Manager シークレットの ARN |
| `ecs_cluster_name` | ECS クラスター名 |
