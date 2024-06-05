locals {
  laravel = {
    name         = "${lower(local.env_project_name)}-api",
    default_tags = local.workload_config.default_tags
    ignore_tags  = local.workload_config.ignore_tags
    domain = {
      name            = "ex.${local.workload.domain.name}"
      root_name       = local.workload.domain.name
      zoneid          = local.workload.domain.zoneid
      acm_arn         = local.workload.domain.acm_arn
      acm_useast1_arn = null
    }
    cicd = {
      // repository
      repository_id = "joselin-bizmatesph/laravel-api-base-image"
      branch        = "master"

      // Build
      container_buildspec_path = "./buildspec.yml"

      // Deploy
      deployment_maximum_percent         = 200
      deployment_minimum_healthy_percent = 100
      force_new_deployment               = true
      autoscale_enabled                  = false
    }
    deployment_notification = {
      chatbot_sns_topic_arn = null
    }
    task = {
      repository_id      = ""
      desired_task_count = 0

      // Capacity provider strategy
      capacity_fargate_base        = 2
      capacity_fargate_weight      = 0
      capacity_fargate_spot_base   = 0
      capacity_fargate_spot_weight = 100

      // Build
      container_buildspec_path = "buildspec.yml"

      // Deploy
      deployment_maximum_percent         = 200
      deployment_minimum_healthy_percent = 100
      force_new_deployment               = true
      autoscale_enabled                  = false

      // Autoscale setting
      autoscale_max_capacity           = 10
      autoscale_min_capacity           = 0
      autoscale_target_value           = 60
      autoscale_scale_in_cooldown      = 1
      autoscale_scale_out_cooldown     = 60
      autoscale_predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    ecr = {
      repository_name = ["${lower(local.env_project_name)}-api/php-fpm", "${lower(local.env_project_name)}-api/nginx"]
    }
    lb_listener = {
      alb_target_enabled    = true
      foward_container_name = "nginx"
      foward_container_port = 80
      set_rule = {
        // Default rule
        enabled         = true
        foward_priority = 120 // 1 ~ 50000
        host_header     = ["${local.workload.domain.name}"]
        path_pattern    = ["/", "/*"]
        cognito = {
          enabled = false
        }
        oidc = {
          enabled = false
        }
      }
      set_cloudfront = {
        use_cloudfront      = local.workload.cloudfront.enabled
        shared_header_name  = null
        shared_header_value = null
      }
    }
    lb_healthcheck = {
      lb_health_check_responce_code             = "200"
      lb_health_check_port                      = 80
      lb_health_check_path                      = "/"
      lb_health_check_interval_sec              = 60
      lb_health_check_healthy_threshold_count   = 2
      lb_health_check_unhealthy_threshold_count = 5
      lb_health_check_timeout_sec               = 30
      lb_deregistration_delay_sec               = 60
      lb_slowstart_sec                          = 0
      lb_health_check_grace_period_seconds      = 90
    }
  }
}
