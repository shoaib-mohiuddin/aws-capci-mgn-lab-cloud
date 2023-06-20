resource "aws_lb" "web_lb" {
  name                       = var.lb_name
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.lb_sg.id]
  subnets                    = module.target_vpc.public_subnets
  drop_invalid_header_fields = true
  enable_deletion_protection = true

  access_logs {
    bucket  = module.logs_bucket.s3_bucket_id
    enabled = true
  }

  # tags = var.tags
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  depends_on        = [data.aws_acm_certificate.acm_cert]
  load_balancer_arn = aws_lb.web_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.acm_cert.arn

  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.tg.arn
        weight = 100
      }
    }
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "alb-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.target_vpc.vpc_id
  health_check {
    port                = 80
    protocol            = "HTTP"
    path                = "/"
    healthy_threshold   = 3   # number of health check successes before considering an unhealthy target healthy
    unhealthy_threshold = 3   # number of health check failures before considering a target unhealthy
    timeout             = 5   # seconds during which no response means a failed health check
    interval            = 30  # seconds between health check
    matcher             = 200 # Status code
  }
  # tags = var.tags
}

resource "aws_lb_target_group_attachment" "tg_attach" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver.id
  port             = 80
}

resource "aws_route53_record" "lb_alias" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "pgadmin.${data.aws_route53_zone.primary.name}"
  type    = "A"

  alias {
    name                   = aws_lb.web_lb.dns_name
    zone_id                = aws_lb.web_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_security_group" "lb_sg" {
  # checkov:skip=CKV_AWS_260: ADD REASON
  name        = "web-lb-sg"
  description = "Allow https inbound traffic"
  vpc_id      = module.target_vpc.vpc_id

  ingress {
    description = "Inbound HTTPS from Anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Inbound HTTP from Anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    description = "Outboud traffic to Anywhere"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-lb-sg"
  }
}
