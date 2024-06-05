# -------------------------------------
# Terraform configuration
# -------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.8.0"
    }
  }
}

# -------------------------------------
# Provider
# -------------------------------------
provider "aws" {
  profile = "playground_mfa"
  region  = "ap-southeast-1"

  default_tags {
    tags = local.service_account.default_tags
  }

  ignore_tags {
    keys = local.service_account.ignore_tags
  }
}

data "aws_caller_identity" "current" {} // Service account ID.

data "aws_region" "current" {}

variable "ENVIRONMENT" {
  type    = string
  default = "playground"
}
