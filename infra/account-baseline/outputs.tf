output "security_alerts_topic_arn" {
  value = aws_sns_topic.security.arn
}

output "budget_name" {
  value = aws_budgets_budget.monthly.name
}

output "cloudtrail_bucket" {
  value = try(aws_s3_bucket.trail[0].id, null)
}

output "guardduty_detector_id" {
  value = try(aws_guardduty_detector.this[0].id, null)
}
