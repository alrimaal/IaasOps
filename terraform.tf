terraform {
  required_providers {
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = ">= 0.15.0"
    }
  }
  required_version = ">= 1.2"
}

provider "bitwarden" {
    server = "https://vault.bitwarden.eu"

    experimental {
      embedded_client = true
    }
}
