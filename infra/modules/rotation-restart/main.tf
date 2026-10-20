data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  function_name = "${var.name}-restart-on-rotation"
  service_arn   = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${var.cluster_name}/${var.service_name}"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/lambda/handler.zip"
}

# ---------------------------------------------------------------- IAM (least privilege)
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name_prefix        = "${var.name}-rotation-"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "permissions" {
  statement {
    sid       = "ReadSecretMetadata"
    actions   = ["secretsmanager:DescribeSecret"]
    resources = [var.secret_arn]
  }

  statement {
    sid       = "RestartOneService"
    actions   = ["ecs:DescribeServices", "ecs:UpdateService"]
    resources = [local.service_arn]
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "restart-ecs-after-rotation"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.permissions.json
}

# ---------------------------------------------------------------- Function
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "this" {
  function_name    = local.function_name
  role             = aws_iam_role.this.arn
  runtime          = "python3.12"
  handler          = "handler.handler"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      CLUSTER    = var.cluster_name
      SERVICE    = var.service_name
      SECRET_ARN = var.secret_arn
    }
  }

  depends_on = [aws_cloudwatch_log_group.this, aws_iam_role_policy_attachment.logs]
}

# ---------------------------------------------------------------- Schedule
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${local.function_name}-schedule"
  description         = "Check whether the DB secret was rotated after the current ECS deployment"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule = aws_cloudwatch_event_rule.schedule.name
  arn  = aws_lambda_function.this.arn
}

resource "aws_lambda_permission" "events" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}

# ---------------------------------------------------------------- Alert if the fixer itself breaks
resource "aws_cloudwatch_metric_alarm" "errors" {
  count = var.enable_error_alarm ? 1 : 0

  alarm_name          = "${local.function_name}-errors"
  alarm_description   = "The rotation-restart function is failing; tasks may keep a stale database password"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = aws_lambda_function.this.function_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.alarm_topic_arn]
}
