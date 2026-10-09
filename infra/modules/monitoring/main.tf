data "aws_region" "current" {}

locals {
  alb_dims = { LoadBalancer = var.alb_arn_suffix }
  tg_dims  = { LoadBalancer = var.alb_arn_suffix, TargetGroup = var.target_group_arn_suffix }
  ecs_dims = { ClusterName = var.ecs_cluster_name, ServiceName = var.ecs_service_name }
  rds_dims = { DBInstanceIdentifier = var.db_instance_identifier }

  # Every entry has the same set of attributes.
  alarms = {
    "no-healthy-targets" = {
      description        = "No healthy app tasks behind the load balancer - the site is down"
      namespace          = "AWS/ApplicationELB"
      metric_name        = "HealthyHostCount"
      dimensions         = local.tg_dims
      statistic          = "Minimum"
      comparison         = "LessThanThreshold"
      threshold          = 1
      period             = 60
      evaluation_periods = 2
      missing            = "breaching"
    }
    "unhealthy-targets" = {
      description        = "One or more app tasks are failing health checks"
      namespace          = "AWS/ApplicationELB"
      metric_name        = "UnHealthyHostCount"
      dimensions         = local.tg_dims
      statistic          = "Maximum"
      comparison         = "GreaterThanOrEqualToThreshold"
      threshold          = 1
      period             = 60
      evaluation_periods = 3
      missing            = "notBreaching"
    }
    "app-5xx" = {
      description        = "The application is returning 5xx errors"
      namespace          = "AWS/ApplicationELB"
      metric_name        = "HTTPCode_Target_5XX_Count"
      dimensions         = local.tg_dims
      statistic          = "Sum"
      comparison         = "GreaterThanOrEqualToThreshold"
      threshold          = var.target_5xx_threshold
      period             = 300
      evaluation_periods = 1
      missing            = "notBreaching"
    }
    "slow-responses" = {
      description        = "Average response time is high"
      namespace          = "AWS/ApplicationELB"
      metric_name        = "TargetResponseTime"
      dimensions         = local.alb_dims
      statistic          = "Average"
      comparison         = "GreaterThanThreshold"
      threshold          = var.response_time_seconds
      period             = 300
      evaluation_periods = 2
      missing            = "notBreaching"
    }
    "ecs-cpu-high" = {
      description        = "ECS service CPU is high"
      namespace          = "AWS/ECS"
      metric_name        = "CPUUtilization"
      dimensions         = local.ecs_dims
      statistic          = "Average"
      comparison         = "GreaterThanThreshold"
      threshold          = var.ecs_cpu_threshold
      period             = 300
      evaluation_periods = 2
      missing            = "notBreaching"
    }
    "ecs-memory-high" = {
      description        = "ECS service memory is high (risk of out-of-memory restarts)"
      namespace          = "AWS/ECS"
      metric_name        = "MemoryUtilization"
      dimensions         = local.ecs_dims
      statistic          = "Average"
      comparison         = "GreaterThanThreshold"
      threshold          = var.ecs_memory_threshold
      period             = 300
      evaluation_periods = 2
      missing            = "notBreaching"
    }
    "db-cpu-high" = {
      description        = "Database CPU is high"
      namespace          = "AWS/RDS"
      metric_name        = "CPUUtilization"
      dimensions         = local.rds_dims
      statistic          = "Average"
      comparison         = "GreaterThanThreshold"
      threshold          = var.db_cpu_threshold
      period             = 300
      evaluation_periods = 3
      missing            = "notBreaching"
    }
    "db-free-storage-low" = {
      description        = "Database is running out of disk space"
      namespace          = "AWS/RDS"
      metric_name        = "FreeStorageSpace"
      dimensions         = local.rds_dims
      statistic          = "Minimum"
      comparison         = "LessThanThreshold"
      threshold          = var.db_free_storage_bytes
      period             = 300
      evaluation_periods = 1
      missing            = "notBreaching"
    }
    "db-free-memory-low" = {
      description        = "Database is low on memory"
      namespace          = "AWS/RDS"
      metric_name        = "FreeableMemory"
      dimensions         = local.rds_dims
      statistic          = "Minimum"
      comparison         = "LessThanThreshold"
      threshold          = var.db_free_memory_bytes
      period             = 300
      evaluation_periods = 3
      missing            = "notBreaching"
    }
    "db-connections-high" = {
      description        = "Many open database connections"
      namespace          = "AWS/RDS"
      metric_name        = "DatabaseConnections"
      dimensions         = local.rds_dims
      statistic          = "Average"
      comparison         = "GreaterThanThreshold"
      threshold          = var.db_connections_threshold
      period             = 300
      evaluation_periods = 2
      missing            = "notBreaching"
    }
  }
}

# ---------------------------------------------------------------- Notifications
# Not encrypted on purpose: CloudWatch alarms cannot publish to topics that use
# the AWS-managed SNS key. Use a customer-managed key if encryption is required.
resource "aws_sns_topic" "alerts" {
  name = "${var.name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ---------------------------------------------------------------- Alarms
resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.alarms

  alarm_name          = "${var.name}-${each.key}"
  alarm_description   = each.value.description
  namespace           = each.value.namespace
  metric_name         = each.value.metric_name
  dimensions          = each.value.dimensions
  statistic           = each.value.statistic
  comparison_operator = each.value.comparison
  threshold           = each.value.threshold
  period              = each.value.period
  evaluation_periods  = each.value.evaluation_periods
  treat_missing_data  = each.value.missing

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# ---------------------------------------------------------------- Dashboard
resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = var.name

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title  = "Load balancer: requests and errors"
          region = data.aws_region.current.name
          stat   = "Sum"
          period = 300
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            [".", "HTTPCode_Target_5XX_Count", ".", "."],
            [".", "HTTPCode_ELB_5XX_Count", ".", "."]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title  = "Response time (seconds)"
          region = data.aws_region.current.name
          stat   = "Average"
          period = 300
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix]
          ]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title  = "App tasks: healthy vs unhealthy"
          region = data.aws_region.current.name
          stat   = "Maximum"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", var.alb_arn_suffix, "TargetGroup", var.target_group_arn_suffix],
            [".", "UnHealthyHostCount", ".", ".", ".", "."]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title  = "ECS service: CPU and memory (%)"
          region = data.aws_region.current.name
          stat   = "Average"
          period = 300
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
        }
      },
      {
        type = "metric", x = 0, y = 12, width = 12, height = 6
        properties = {
          title  = "Database: CPU (%) and connections"
          region = data.aws_region.current.name
          stat   = "Average"
          period = 300
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_instance_identifier],
            [".", "DatabaseConnections", ".", "."]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 12, width = 12, height = 6
        properties = {
          title  = "Database: free storage and memory (bytes)"
          region = data.aws_region.current.name
          stat   = "Minimum"
          period = 300
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.db_instance_identifier],
            [".", "FreeableMemory", ".", "."]
          ]
        }
      }
    ]
  })
}
