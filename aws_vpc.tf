module "vpc_workload" {
  source = "git@github.com:bizmatesinc/terraform-template-module.git//aws_modules/module_vpc?ref=v2.0.17"

  // Network
  availability_zones = ["ap-southeast-1b", "ap-southeast-1c"]
  cidr_block         = local.workload.vpc.cidr_block
  project_name       = lower(local.env_project_name)
  enable_termination = var.ENABLE_TERMINATION

  // Subnet
  enable_public_subnet   = true
  enable_private_subnet  = true
  enable_internal_subnet = true

  // NAT Instance
  use_ec2_nat_instance  = true
  multi_az_nat_instance = false

  // Bastion
  is_bastion_enabled = true

  // Route53
  is_nat_ip_record_enabled         = true
  nat_ip_attach_r53zone_id         = local.workload.domain.zoneid
  nat_ip_attach_r53zone_id_domains = ["gw1", "gw2"]

}
