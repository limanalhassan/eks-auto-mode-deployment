resource "aws_acm_certificate" "opslevel" {
  domain_name       = "*.limanalhassan.work"
  validation_method = "DNS"
}

