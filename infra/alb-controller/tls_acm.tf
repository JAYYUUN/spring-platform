############################################
# tls_acm.tf (single file example)
############################################

# ====== 입력값(원하면 변수로 빼도 됨) ======
locals {
  zone_name   = "yunhwan.click"     # Hosted Zone (뒤에 점 없이)
  domain_name = "app.yunhwan.click" # 인증서 받을 FQDN
}

# Route53 Hosted Zone 찾기
data "aws_route53_zone" "main" {
  name         = "${local.zone_name}."
  private_zone = false
}

# 1) ACM 인증서 생성 (DNS 검증)
resource "aws_acm_certificate" "app" {
  domain_name       = local.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# 2) DNS validation 레코드 자동 생성
resource "aws_route53_record" "app_validation" {
  for_each = {
    for dvo in aws_acm_certificate.app.domain_validation_options :
    dvo.domain_name => dvo
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60
}

# 3) 인증서 검증 완료 처리
resource "aws_acm_certificate_validation" "app" {
  certificate_arn         = aws_acm_certificate.app.arn
  validation_record_fqdns = [for r in aws_route53_record.app_validation : r.fqdn]
}

# 출력(나중에 Ingress annotation에 넣을 ARN)
output "acm_certificate_arn" {
  value = aws_acm_certificate_validation.app.certificate_arn
}