module "www_redirect" {
  
  source  = "github.com/silksh-terraform-modules/terraform-aws-cloudfront-redirect?ref=v0.0.1"

  source_domain_name = [
    "www.${var.tld}"
  ]
  source_bucket_name = "www.${var.tld}"
  target_domain_name = "${var.tld}"
  acm_certificate_arn = data.terraform_remote_state.infra.outputs.ssl_cert_in_us_certificate_arn
  zone_id = data.terraform_remote_state.infra.outputs.ssl_cert_in_us_zone_id
  comment = "redirects www.${var.tld} to ${var.tld}"
  price_class = "PriceClass_200"
  geo_restriction = false

}