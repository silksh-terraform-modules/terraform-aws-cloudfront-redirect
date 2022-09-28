variable "source_bucket" {
  default = ""
}

variable "logs_bucket" {
  default = ""
}

variable "index_document" {
  default = "index.html"
}

variable "error_document" {
  default = "index.html"
}

variable "s3_origin_id" {
  default = ""
}

variable "target_domain_name" {
  default = ""
}

variable "min_ttl" {
  default = 0
}

variable "default_ttl" {
  default = 60
}

variable "max_ttl" {
  default = 300
}

variable "compress" {
  default = false
}

variable "price_class" {
  default = "PriceClass_100"
}

## domyslnie data.terraform_remote_state.domain_cert_us.outputs.certificate_arn
variable "acm_certificate_arn" {
  default = ""
}

## data.terraform_remote_state.domain_cert_us.outputs.zone_id
variable "zone_id" {
  default = ""
}

variable "comment" {
  default = "created by SilkSH with terraform"
}

variable "minimum_protocol_version" {
  default = "TLSv1.2_2018"
}

variable "geo_restriction" {
  type = bool
  default = false
}

variable "restriction_locations" {
  default = ["PL", "US", "GB", "DE", "CA"]
}

variable "source_bucket_name" {
  default = ""
}

variable "source_domain_name" {
  default = ""
}

variable "routing_rules" {
  default = "" 
  description = "A json array containing routing rules describing redirect behavior and when redirects are applied"
  type        = string
}