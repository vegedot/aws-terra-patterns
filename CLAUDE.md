# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Terraform pattern library for AWS environments. It provides reusable infrastructure-as-code patterns intended for both PoC and production deployments.

## Repository Structure

- `patterns/` — Terraform deployment patterns. Each subdirectory is a self-contained Terraform root module.
- `modules/` — Reusable Terraform modules (currently empty; modules referenced by patterns go here).
- `patterns/00_common_format/` — Canonical template showing the standard file layout for all patterns.

## Standard Pattern File Layout

Every pattern directory follows this convention:

| File | Purpose |
|---|---|
| `versions.tf` | Terraform and provider version constraints |
| `provider.tf` | AWS provider configuration |
| `variables.tf` | Input variable declarations |
| `main.tf` | Primary resource definitions |
| `outputs.tf` | Output value declarations |
| `terraform.tfvars.example` | Example variable values (committed; actual `.tfvars` are gitignored) |
| `README.md` | Pattern-specific documentation |

## Common Terraform Commands

Run these from within a pattern directory (e.g., `patterns/<pattern-name>/`):

```bash
terraform init       # Initialize providers and backend
terraform validate   # Validate configuration syntax
terraform fmt -check # Check formatting (use `terraform fmt` to fix)
terraform plan       # Preview changes
terraform apply      # Apply changes
terraform destroy    # Tear down resources
```

## Key Conventions

- `.tfvars` and `.tfvars.json` files are gitignored — copy `terraform.tfvars.example` to `terraform.tfvars` and fill in values locally.
- Terraform state files (`.tfstate`) are gitignored and should never be committed.
- Pattern directories are numbered (e.g., `00_`, `01_`) to indicate ordering or progression.
- When adding a new pattern, copy the `00_common_format/` directory as the starting skeleton.
