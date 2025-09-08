
resource "cloudflare_dns_record" "app_dns_record" {
  for_each = toset(var.cname_labels)

  zone_id = var.cloudflare_zone_id
  name    = each.value
  type    = "CNAME"
  content = data.aws_lb.opslevel_alb.dns_name

  proxied = var.cloudflare_proxied
  ttl     = var.cloudflare_proxied ? 1 : 3600

  depends_on = [helm_release.argocd]
}

resource "cloudflare_dns_record" "validate_acm_dns_record" {
  for_each = {
    for dvo in aws_acm_certificate.opslevel.domain_validation_options :
    dvo.domain_name => {
      name   = trimsuffix(dvo.resource_record_name, ".")
      record = trimsuffix(dvo.resource_record_value, ".")
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.record
  ttl     = 1
  proxied = false
  depends_on = [aws_acm_certificate.opslevel]
}
