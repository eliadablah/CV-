terraform {
  # I need Terraform 1.10 or newer because backend.tf uses use_lockfile
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.61.0"
    }
  }
}

provider "aws" {
  region = var.region_name

  # I put these tags on everything, so I can find this project on my AWS bill
  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
    }
  }
}
