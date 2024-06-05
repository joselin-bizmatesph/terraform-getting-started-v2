module "s3_pipeline_store" {
  source = "git@github.com:bizmatesinc/terraform-template-module.git//aws_modules/module_s3_bucket_internal?ref=v2.0.17"

  bucket_name          = "aws-pipeline-store-${lower(local.env_project_name)}-${data.aws_caller_identity.current.account_id}"
  enable_termination   = var.ENABLE_TERMINATION
  auto_archive_enabled = true
}