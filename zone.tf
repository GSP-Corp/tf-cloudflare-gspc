resource "cloudflare_zone" "gspc" {
  name   = "gspc.digital"
  paused = false
  type   = "full"
  account = {
    id   = "075dfe0421fbb29f90fb7ae88e2804fa"
    name = "Serundeputy@gmail.com's Account"
  }
}

resource "cloudflare_zone" "gspc_finance" {
  name   = "gspc.finance"
  paused = false
  type   = "full"
  account = {
    id   = "075dfe0421fbb29f90fb7ae88e2804fa"
    name = "Serundeputy@gmail.com's Account"
  }
}

