module "alb_workload_internet_facing" {
  source             = "git@github.com:bizmatesinc/terraform-template-module.git//aws_modules/module_alb_internetfacing?ref=v2.0.17"
  account_id         = data.aws_caller_identity.current.account_id
  enable_termination = var.ENABLE_TERMINATION
  alb_name           = "${lower(local.env_project_name)}-alb"
  subnet_ids         = module.vpc_workload.aws_subnet_public[*].id
  security_group_ids = [
    module.vpc_workload.public_subnet_group_security_group_id,
    module.vpc_workload.publish_internet_security_group_id
  ]
  ssl_certificate_arns = [local.workload.domain.acm_arn]
  route53_records = [
    {
      zone_id = local.workload.domain.zoneid
      name    = local.workload.domain.name
      type    = "A"
    }
  ]

  bluegreen_test_port_enabled = false
}
