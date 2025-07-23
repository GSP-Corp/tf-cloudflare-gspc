terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
  backend "s3" {
    bucket       = "tf-gspc-cloudflare-state"
    key          = "cloudflare/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "cloudflare" {}
