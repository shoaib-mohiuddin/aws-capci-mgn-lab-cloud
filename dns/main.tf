# Route53 PUBLIC hosted zone
resource "aws_route53_zone" "primary" {
  name = var.public_domain_name
  tags = var.tags
}

resource "aws_route53_record" "resolve_test" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "${var.subdomain_name}.${var.public_domain_name}"
  type    = "A"
  ttl     = 300
  records = ["106.193.36.120"] # random IP, just to check if it resolves correctly
}

# Route53 PRIVATE hosted zone
resource "aws_route53_zone" "private" {
  depends_on = [data.aws_vpc.target_vpc]
  name       = var.private_domain_name

  vpc {
    vpc_id = data.aws_vpc.target_vpc.id
  }
  tags = var.tags
}

resource "aws_route53_record" "private_resolve_test" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "${var.subdomain_name}.${var.private_domain_name}"
  type    = "A"
  ttl     = 300
  records = ["192.168.0.25"] # random IP, just to check if it resolves correctly
}

# AWS Certificate Manager 
resource "aws_acm_certificate" "acm_cert" {
  domain_name               = var.public_domain_name
  subject_alternative_names = ["pgadmin.${var.public_domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_acm_certificate_validation" "acm_cert_validn" {
  certificate_arn         = aws_acm_certificate.acm_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_dns_record : record.fqdn]
}

resource "aws_route53_record" "cert_dns_record" {
  for_each = {
    for dvo in aws_acm_certificate.acm_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.primary.zone_id
}
