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
      acm_arn = "arn:aws:acm:ap-southeast-1:890942158228:certificate/47805cae-14f6-4091-a434-23d828fd5c22"
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
