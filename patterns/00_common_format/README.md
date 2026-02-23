# Pattern Name

Brief description of what this pattern provisions.

## Overview

Describe the architecture and purpose.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `aws_region` | AWS region to deploy resources into | `string` | `"ap-northeast-1"` | no |
| `project` | Project name used for resource naming and tagging | `string` | — | yes |
| `environment` | Deployment environment (dev / stg / prod) | `string` | — | yes |

## Outputs

| Name | Description |
|---|---|
| — | — |
