terraform {
  required_providers {
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = ">= 0.15.0"
    }
    flux = {
      source = "fluxcd/flux"
      version = "1.6.4"
    }

    github = {
      source  = "integrations/github"
      version = ">= 6.1"
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
