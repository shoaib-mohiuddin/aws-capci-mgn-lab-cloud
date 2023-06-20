terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      "Project"     = "capci-mgn-lab"
      "Environment" = "Dev"
      "Platform"    = "on-cloud"
    }
  }
}
