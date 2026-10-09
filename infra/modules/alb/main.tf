locals {
  https = var.certificate_arn != null
}

# ---------------------------------------------------------------- Security group
resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-"
  description = "Public load balancer"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.name}-alb-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  for_each = toset(var.ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "HTTP"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  for_each = local.https ? toset(var.ingress_cidrs) : toset([])

  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS"
}

# ALB -> app tier, and only on the container port.
resource "aws_vpc_security_group_egress_rule" "to_app" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = var.app_security_group_id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
  description                  = "To ECS tasks"
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = var.app_security_group_id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
  description                  = "From ALB"
}

# ---------------------------------------------------------------- Load balancer
resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.alb.id]

  drop_invalid_header_fields = true
  enable_deletion_protection = var.deletion_protection
  idle_timeout               = 60
}

resource "aws_lb_target_group" "app" {
  name_prefix          = "tg-"
  port                 = var.container_port
  protocol             = "HTTP"
  target_type          = "ip" # required for Fargate (awsvpc)
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = { Name = "${var.name}-tg" }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------- Listeners
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = local.https ? "redirect" : "forward"
    target_group_arn = local.https ? null : aws_lb_target_group.app.arn

    dynamic "redirect" {
      for_each = local.https ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count = local.https ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
