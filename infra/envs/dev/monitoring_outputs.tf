output "alerts_topic_arn" {
  value = module.monitoring.sns_topic_arn
}

output "dashboard_name" {
  value = module.monitoring.dashboard_name
}

output "alarm_names" {
  value = module.monitoring.alarm_names
}
