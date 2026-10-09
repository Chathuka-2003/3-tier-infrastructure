output "address" {
  value = aws_db_instance.this.address
}

output "port" {
  value = aws_db_instance.this.port
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "security_group_id" {
  value = aws_security_group.db.id
}

output "master_user_secret_arn" {
  description = "Secrets Manager secret holding the generated master credentials."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "kms_key_arn" {
  description = "Grant kms:Decrypt on this key to the ECS task execution role."
  value       = aws_kms_key.rds.arn
}
