locals {
  name_prefix = "${var.project}-${var.environment}"
}

data "aws_availability_zones" "available" {
  state = "available"
}
