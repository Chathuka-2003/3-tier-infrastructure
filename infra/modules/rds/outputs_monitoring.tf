output "db_instance_identifier" {
  description = "Used by CloudWatch alarms and dashboards."
  value       = aws_db_instance.this.identifier
}
