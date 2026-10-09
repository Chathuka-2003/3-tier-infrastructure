# ---------------------------------------------------------------- Encryption key
resource "aws_kms_key" "rds" {
  description             = "${var.name} RDS storage, Performance Insights and master secret"
  enable_key_rotation     = true
  deletion_window_in_days = 14
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.name}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# ---------------------------------------------------------------- Networking
resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db"
  subnet_ids = var.subnet_ids

  tags = { Name = "${var.name}-db-subnet-group" }
}

# No egress rules: the database never initiates outbound connections.
resource "aws_security_group" "db" {
  name_prefix = "${var.name}-db-"
  description = "MySQL - reachable only from the application tier"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.name}-db-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "from_app" {
  count = length(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = var.allowed_security_group_ids[count.index]
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  description                  = "MySQL from app tier"
}

# ---------------------------------------------------------------- Parameters
resource "aws_db_parameter_group" "this" {
  name_prefix = "${var.name}-mysql-"
  family      = var.parameter_group_family

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "require_secure_transport"
    value = "1"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------- Enhanced monitoring role
data "aws_iam_policy_document" "monitoring_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  name_prefix        = "${var.name}-rds-mon-"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume.json
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ---------------------------------------------------------------- Instance
resource "aws_db_instance" "this" {
  identifier = "${var.name}-mysql"

  engine         = "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  db_name  = var.db_name
  username = var.master_username
  port     = 3306

  # RDS generates the password and stores it in Secrets Manager,
  # so it never appears in Terraform state or code.
  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.rds.arn

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  parameter_group_name   = aws_db_parameter_group.this.name

  backup_retention_period   = var.backup_retention_period
  backup_window             = "02:00-03:00"
  maintenance_window        = "sun:03:30-sun:04:30"
  copy_tags_to_snapshot     = true
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-mysql-final"

  auto_minor_version_upgrade          = true
  iam_database_authentication_enabled = true
  enabled_cloudwatch_logs_exports     = ["error", "slowquery"]

  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? aws_kms_key.rds.arn : null
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.monitoring.arn

  depends_on = [aws_iam_role_policy_attachment.monitoring]
}
