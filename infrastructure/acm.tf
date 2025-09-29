resource "aws_acm_certificate" "liman" {
  domain_name       = "*.limanalhassan.work"
  validation_method = "DNS"
}

