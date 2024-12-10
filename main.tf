/*
  보안 그룹
*/

module "security_group" {
  source  = "app.terraform.io/animal-squad/security-group/aws"
  version = "1.0.1"

  name_prefix = "${var.name}-alb-sg"
  vpc_id      = var.vpc_id

  ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
}

/*
  ALB
*/

resource "aws_lb" "alb" {
  name               = var.name
  load_balancer_type = "application"

  subnets         = var.subnet_ids
  security_groups = [module.security_group.id]

  client_keep_alive = 3600 // Default
  idle_timeout      = var.idle_timeout

  enable_deletion_protection = var.enable_deletion_protection
}

/*
  ALB Listener
*/

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn

  port     = "80"
  protocol = "HTTP"


  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  certificate_arn   = var.certificate_arn

  //NOTE: ssl_policy 설정 값 참조 https://docs.aws.amazon.com/elasticloadbalancing/latest/application/describe-ssl-policies.html
  ssl_policy = "ELBSecurityPolicy-TLS13-1-0-2021-06"
  port       = "443"
  protocol   = "HTTPS"


  default_action {
    type = "forward"

    forward {
      dynamic "target_group" {
        for_each = aws_lb_target_group.default_target_groups

        content {
          arn = target_group.value.arn
        }
      }
    }
  }
}

resource "aws_lb_target_group" "default_target_groups" {
  for_each = var.default_target_groups

  vpc_id                            = var.vpc_id
  load_balancing_cross_zone_enabled = "use_load_balancer_configuration"
  target_type                       = "instance"

  name = each.key
  port = each.value.port

  protocol         = "HTTP"
  protocol_version = "HTTP1"

  health_check {
    path = each.value.health_check_path
  }

  tags = {
    Name = "${var.name}-default-tg-${each.key}"
  }
}

resource "aws_lb_target_group_attachment" "default_target" {
  for_each = var.default_targets

  target_group_arn = aws_lb_target_group.default_target_groups[each.value.target_group_key].arn
  target_id        = each.key
  port             = each.value.port
}

/*
  ALB Listener Rule
*/

resource "aws_lb_listener_rule" "https_listener_rules" {
  for_each = var.https_listener_rules

  listener_arn = aws_lb_listener.https.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_groups[each.key].arn
  }

  condition {
    path_pattern {
      values = each.value.path
    }
  }

  condition {
    host_header {
      values = each.value.host
    }
  }
}

resource "aws_lb_target_group" "target_groups" {
  for_each = var.target_groups

  vpc_id                            = var.vpc_id
  load_balancing_cross_zone_enabled = "use_load_balancer_configuration"
  target_type                       = "instance"

  name = each.key
  port = each.value.port

  protocol         = "HTTP"
  protocol_version = "HTTP1"

  health_check {
    path = each.value.health_check_path
  }

  tags = {
    Name = "${var.name}-tg-${each.key}"
  }
}

resource "aws_lb_target_group_attachment" "target" {
  for_each = var.targets

  target_group_arn = aws_lb_target_group.target_groups[each.value.target_group_key].arn
  target_id        = each.key
  port             = each.value.port
}
