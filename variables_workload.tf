# For PoC resource
variable "ENABLE_TERMINATION" {
  type    = bool
  default = true
}

locals {
  env_project_name = "selin-tf"
  workload_config = {
    default_tags = local.service_account.default_tags
    ignore_tags  = local.service_account.ignore_tags
  }
  workload = {
    vpc = {
      cidr_block = "10.0.0.0/16"
    }
    cloudfront = {
      enabled = false
    }
    domain = {
      zoneid  = "Z09199501MS1MJQMJ796B"
      name    = "joselin.sre.bizmates.co.jp"
      acm_arn = "arn:aws:acm:ap-northeast-1:890942158228:certificate/974445f0-da15-40a7-8225-3232914ad461"
    }
  }
}

locals {
  env_prefix = ""
}

## Account global setting
locals {
  service_account = {
    default_tags = {
      CodedResource  = "true"
      IaC            = "local"
      Service        = lower(local.env_project_name)
      Environment    = lower(var.ENVIRONMENT)
      CmBillingGroup = "OTHER"
      Owner          = ""
    }
    ignore_tags = [
      "SET.AutoUpdateEnable",
      "SET.AutoUpdateScheduleCron",
      "SET.AutoStartEnable",
      "SET.AutoStartScheduleCron",
      "SET.AutoStopEnable",
      "SET.AutoStopScheduleCron",
      "SET.DefaultTaskCount",
      "SET.DefaultInstanceType",
      "SET.DefaultInstanceNodeCount",
      "SET.DefaultNodeType",
      "SET.DefaultCapacity"
    ]
  }
}
