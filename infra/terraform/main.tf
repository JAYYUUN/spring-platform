#provider + 태그
provider "aws" {
  region = var.aws_region
}

locals {
  tags = {
    Project = var.project
  }
}
