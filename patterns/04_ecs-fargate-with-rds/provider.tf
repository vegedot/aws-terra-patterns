provider "aws" {
  region = var.aws_region
  profile = "vegedot-dev"

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

provider "random" {}
