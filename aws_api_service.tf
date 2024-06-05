module "fargate_api_service" {
  source = "git@github.com:bizmatesinc/terraform-template-module.git//aws_modules/module_ecs_fargate_spotscale?ref=v2.0.17"

  // Name
  env_prefix                                 = local.env_prefix
  service_name                               = local.laravel.name
  service_name_option_add_env_prefix_enabled = false
  enable_envprefix_cloudmap_domain           = false

  // ECS
  deploy_cluster_name = module.ecs_cluster_workload.aws_ecs_cluster_default.name
  deploy_cluster_arn  = module.ecs_cluster_workload.aws_ecs_cluster_default.arn
  deploy_subnet_ids   = module.vpc_workload.aws_subnet_private[*].id
  service_security_group_ids = [
    module.vpc_workload.private_subnet_group_security_group_id,
    module.vpc_workload.http_server_external_security_group_id,
  ]
  task_definition_resource     = aws_ecs_task_definition.init_laravel.family
  desired_task_count           = local.laravel.task.desired_task_count
  capacity_fargate_base        = local.laravel.task.capacity_fargate_base
  capacity_fargate_weight      = local.laravel.task.capacity_fargate_weight
  capacity_fargate_spot_base   = local.laravel.task.capacity_fargate_spot_base
  capacity_fargate_spot_weight = local.laravel.task.capacity_fargate_spot_weight
  enable_execute_command       = true

  // Autoscale
  autoscale_enabled                = local.laravel.task.autoscale_enabled
  autoscale_max_capacity           = local.laravel.task.autoscale_max_capacity
  autoscale_min_capacity           = local.laravel.task.autoscale_min_capacity
  autoscale_target_value           = local.laravel.task.autoscale_target_value
  autoscale_scale_in_cooldown      = local.laravel.task.autoscale_scale_in_cooldown
  autoscale_scale_out_cooldown     = local.laravel.task.autoscale_scale_out_cooldown
  autoscale_predefined_metric_type = local.laravel.task.autoscale_predefined_metric_type

  // Deploy
  deployment_maximum_percent         = local.laravel.task.deployment_maximum_percent
  deployment_minimum_healthy_percent = local.laravel.task.deployment_minimum_healthy_percent
  force_new_deployment               = local.laravel.task.force_new_deployment

  // Blue/Green Option
  bluegreen_enabled                            = false
  foward_alb_listener_arn_bluegreen_test_route = module.alb_workload_internet_facing.bluegreen_test_port_arn

  // LB
  lb_target_group_enabled              = local.laravel.lb_listener.alb_target_enabled
  lb_listener_rule_option_xff_allow_ip = "*" // Need open.
  vpc_id                               = module.vpc_workload.aws_vpc_default.id
  foward_alb_listener_arn              = module.alb_workload_internet_facing.aws_lb_listener_port_443_arn
  foward_container_name                = local.laravel.lb_listener.foward_container_name
  foward_container_port                = local.laravel.lb_listener.foward_container_port
  lb_listener_rule_enabled             = local.laravel.lb_listener.set_rule.enabled
  foward_priority                      = local.laravel.lb_listener.set_rule.foward_priority
  host_header                          = local.laravel.lb_listener.set_rule.host_header
  path_pattern                         = local.laravel.lb_listener.set_rule.path_pattern

  // Cognito
  lb_authenticate_cognito_enabled = local.laravel.lb_listener.set_rule.cognito.enabled

  // OiDC (Listener rule)
  lb_authenticate_oidc_enabled = local.laravel.lb_listener.set_rule.oidc.enabled

  // CloudFront (Listener rule)
  lb_cloudfront_enabled                    = local.laravel.lb_listener.set_cloudfront.use_cloudfront
  lb_cloudfront_option_shared_header_name  = local.laravel.lb_listener.set_cloudfront.shared_header_name
  lb_cloudfront_option_shared_header_value = local.laravel.lb_listener.set_cloudfront.shared_header_value

  // HealthCheck
  lb_health_check_responce_code             = local.laravel.lb_healthcheck.lb_health_check_responce_code
  lb_health_check_interval_sec              = local.laravel.lb_healthcheck.lb_health_check_interval_sec
  lb_health_check_healthy_threshold_count   = local.laravel.lb_healthcheck.lb_health_check_healthy_threshold_count
  lb_health_check_unhealthy_threshold_count = local.laravel.lb_healthcheck.lb_health_check_unhealthy_threshold_count
  lb_health_check_timeout_sec               = local.laravel.lb_healthcheck.lb_health_check_timeout_sec
  lb_deregistration_delay_sec               = local.laravel.lb_healthcheck.lb_deregistration_delay_sec
  lb_slowstart_sec                          = local.laravel.lb_healthcheck.lb_slowstart_sec
  lb_health_check_port                      = local.laravel.lb_healthcheck.lb_health_check_port
  lb_health_check_path                      = local.laravel.lb_healthcheck.lb_health_check_path
  lb_health_check_grace_period_seconds      = local.laravel.lb_healthcheck.lb_health_check_grace_period_seconds

  // Service discovery
  aws_service_discovery_private_dns_namespace_id = module.ecs_cluster_workload.aws_service_discovery_private_dns_namespace_default.id
}

// Task definition will be ignored !! =====================================================
// [RollingUpdate] -> Need to change taskdef version of Service to LATEST version manualy.
// [BlueGreen]     -> Need to update taskdef.template.json. 
//                    Will be overwritten at the next run the Pipeline.
// ========================================================================================
resource "aws_ecs_task_definition" "init_laravel" {

  lifecycle {
    ignore_changes = [
      // [Important!]
      // Exclude container_definitions. Because developers need to set Secrets. 
      // After the initial construction, changes are made using the management console.
      container_definitions
    ]
  }

  family                   = "${lower(local.env_prefix)}${lower(local.laravel.name)}"
  cpu                      = 512
  memory                   = 1024
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role_laravel.arn
  task_role_arn            = aws_iam_role.ecs_task_role_laravel.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "${data.aws_caller_identity.current.id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.laravel.name}/nginx:latest"
      essential = true
      cpu       = 0
      portMappings = [
        {
          hostPort      = 80
          protocol      = "tcp"
          containerPort = 80
        }
      ]
      linuxParameters = {
        initProcessEnabled = true
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${module.ecs_cluster_workload.aws_ecs_cluster_default.name}/${lower(local.laravel.name)}"
          awslogs-region        = "${data.aws_region.current.name}"
          awslogs-stream-prefix = "container"
          awslogs-create-group  = "true"
        }
      }
    },
    {
      name      = "php-fpm"
      image     = "${data.aws_caller_identity.current.id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.laravel.name}/php-fpm:latest"
      essential = false
      cpu       = 0
      portMappings = [
        {
          hostPort      = 9000
          protocol      = "tcp"
          containerPort = 9000
        }
      ]
      linuxParameters = {
        initProcessEnabled = true
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${module.ecs_cluster_workload.aws_ecs_cluster_default.name}/${lower(local.laravel.name)}"
          awslogs-region        = "${data.aws_region.current.name}"
          awslogs-stream-prefix = "container"
          awslogs-create-group  = "true"
        }
      }
      environment = [
        {
          name  = "APP_NAME",
          value = "Laravel"
        },
        {
          name  = "APP_ENV",
          value = "prod"
        },
        {
          name  = "APP_KEY",
          value = "base64:i8ZI10k9Nob0lqQHR+Z7W53w8UtTZfX0dOIEerT6bOw="
        },
        {
          name  = "APP_DEBUG",
          value = "true"
        }
      ]
      secrets = []
    }
  ])
}

resource "aws_cloudwatch_log_group" "laravel" {
  name              = "/ecs/${lower(module.ecs_cluster_workload.aws_ecs_cluster_default.name)}/${local.laravel.name}"
  retention_in_days = 30
}

## Roles
data "aws_iam_policy_document" "assumerole_ecs-tasks_laravel" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role_laravel" {
  name               = "ecs_task_execution_role_${local.laravel.name}"
  path               = "/servicerole/"
  assume_role_policy = data.aws_iam_policy_document.assumerole_ecs-tasks_laravel.json

  inline_policy {
    name   = "ecs_task_execusion_basic_action_laravel"
    policy = data.aws_iam_policy_document.ecs_task_execusion_basic_action_laravel.json
  }

  inline_policy {
    name   = "secrets_parameter_action_for_laravel"
    policy = data.aws_iam_policy_document.secrets_parameter_action_for_laravel.json
  }

  # inline_policy {
  #   name   = "adot_collector_laravel"
  #   policy = data.aws_iam_policy_document.adot_collector_laravel.json
  # }
}

data "aws_iam_policy_document" "ecs_task_execusion_basic_action_laravel" {
  version = "2012-10-17"
  statement {
    sid       = "KMS"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:key/*"]
  }

  statement {
    sid    = "ECR"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CloudWatch"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:${data.aws_caller_identity.current.id}:log-group:/ecs/*",
    ]
  }
}

data "aws_iam_policy_document" "secrets_parameter_action_for_laravel" {
  statement {
    sid     = "SecretsManager"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      "*"
    ]
  }
  statement {
    sid       = "SystemsManager"
    effect    = "Allow"
    actions   = ["ssm:GetParameters"]
    resources = ["arn:aws:ssm:*:${data.aws_caller_identity.current.id}:parameter/*"]
  }
}

resource "aws_iam_role" "ecs_task_role_laravel" {
  name               = "ecs_task_role_${local.laravel.name}"
  path               = "/servicerole/"
  assume_role_policy = data.aws_iam_policy_document.assumerole_ecs-tasks_laravel.json

  inline_policy {
    name   = "secrets_parameter_action_for_laravel"
    policy = data.aws_iam_policy_document.secrets_parameter_action_for_laravel.json
  }

  inline_policy {
    name   = "ecs_task_basic_action_for_laravel"
    policy = data.aws_iam_policy_document.ecs_task_basic_action_for_laravel.json
  }
}

data "aws_iam_policy_document" "ecs_task_basic_action_for_laravel" {
  version = "2012-10-17"

  statement {
    sid    = "Exec"
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ssm:UpdateInstanceInformation"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]
    resources = [
      "arn:aws:logs:*:${data.aws_caller_identity.current.id}:log-group:/ecs/*",
    ]
  }

  statement {
    sid    = "S3PreventActions"
    effect = "Deny"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["arn:aws:s3:::*log*/*"]
  }
}

## ECR
module "ecr_laravel" {
  for_each = toset(local.laravel.ecr.repository_name)
  source   = "git@github.com:bizmatesinc/terraform-template-module.git//aws_modules/module_ecr_repository?ref=v2.0.17"

  repository_name                 = each.key
  image_tag_mutability            = "MUTABLE" // Update latest image.
  image_scan_on_push              = true
  lifecycle_enabled               = true
  lifecycle_number_of_images_keep = 10
}

## CodeBuild
module "pipeline_laravel" {
  source = "git@github.com:bizmatesinc/terraform-template-module.git//aws_modules/module_codepipeline_ecs?ref=v2.0.17"

  // Name / Env
  project_name = lower(local.laravel.name)
  environment  = var.ENVIRONMENT

  // Pipeline
  pipeline_s3_bucket       = module.s3_pipeline_store.aws_s3_bucket_default.id
  cwlogs_retention_in_days = 30
  enable_termination       = var.ENABLE_TERMINATION

  // Source
  repository_id              = local.laravel.cicd.repository_id
  branch                     = local.laravel.cicd.branch
  buildspec_path             = local.laravel.cicd.container_buildspec_path
  poll_source_change_enabled = true

  // Build
  codebuild_compute_type           = "BUILD_GENERAL1_MEDIUM"
  codebuild_compute_provided_image = "aws/codebuild/amazonlinux2-x86_64-standard:4.0" // Reference: https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
  codebuild_compute_envtype        = "LINUX_CONTAINER"
  codebuild_custom_role_arns       = []
  codebuild_build_env = {
    // Env, Domain
    build_vars_environment = "dev"
    // ECR
    build_vars_container_image_prefix = "${data.aws_caller_identity.current.id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
    // ECS
    build_vars_cluster     = module.ecs_cluster_workload.aws_ecs_cluster_default.name
    build_vars_service     = local.laravel.name
    build_vars_taskdef     = aws_ecs_task_definition.init_laravel.family
    build_vars_domain_root = "ex.${local.workload.domain.name}"
  }

  // Approve
  notification_sns_topic_arn = null
  approve_message            = "Deployment"
  approve_message_ext_link   = "Deployment Approval"

  // Deploy
  deploy_enabled          = true
  deploy_ecs_cluster_name = module.ecs_cluster_workload.aws_ecs_cluster_default.name
  deploy_ecs_service_name = lower(local.laravel.name)

  // Blue/Green Deploy 
  bluegreen_deploy_enabled   = false
  test_lb_listener_arns      = [module.alb_workload_internet_facing.aws_lb_listener_port_443_arn]
  prod_lb_listener_arns      = [module.alb_workload_internet_facing.bluegreen_test_port_arn]
  lb_target_group_green_name = module.fargate_api_service.target_group_green_name
  lb_target_group_blue_name  = module.fargate_api_service.target_group_blue_name
  taskdef_name               = null
  appspec_name               = null
}
