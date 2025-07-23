resource "cloudflare_zero_trust_access_application" "zt" {
  type    = "self_hosted"
  zone_id = local.zone_id
  domain  = "${local.domain}/zt"
  name    = "zt"
}
