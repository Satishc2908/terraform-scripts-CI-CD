## Variables

variable "aws_accounts_id" {
  type    = map(string)
  default = {
    admin-account     = "123456789012"
    sandbox           = "123456789013"
  }
}

variable "codebuild_configuration" {
  type    = map(string)
  default = {
    cb_compute_type = "BUILD_GENERAL1_SMALL"
    cb_image        = "aws/codebuild/standard:5.0"
    cb_type         = "LINUX_CONTAINER"
  }
}

variable "project_name" {
  type    = string
  default = "project"
}

## Locals

locals {

  ## pipeline related variables
  codebuild_bucket                   = "${var.project_name}-permission-sets-${var.aws_accounts_id["admin-account"]}"
  permission_sets_repository_name    = "${var.project_name}-sso-permsets-configuration"
  permission_sets_listen_branch_name = "master"

  ## tags & meta
  common_tags = {
    Project     = "My Project"
    ManagedBy   = "Terraform"
  }
}