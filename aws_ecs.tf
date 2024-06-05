module "ecs_cluster_workload" {
  source = "git@github.com:bizmatesinc/terraform-template-module.git//aws_modules/module_ecs_cluster?ref=v2.0.17"

  environment              = var.ENVIRONMENT
  cluster_name             = lower(local.env_project_name)
  vpc_id                   = module.vpc_workload.aws_vpc_default.id
  namespace                = "${replace(lower(local.env_project_name), "-", ".")}.internal"
  cwlogs_retention_in_days = lower(var.ENVIRONMENT) == "production" ? 0 : 30
}
