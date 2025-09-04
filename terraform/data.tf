data "bitwarden_secret" "hcloud_token" {
  id = "2464f47a-7b28-49e4-b637-b34500acb29d"
}

data "bitwarden_secret" "flux_github_token" {
  id = "45303925-34d4-4d49-93ee-b347007514b2"
}

data "bitwarden_secret" "gpg_sops_private_key" {
  id = "ccdf7009-6a30-4285-a21e-b34a00b5994e"
}

data "kubectl_file_documents" "gateway_api_crds_yamls" {
  content = file("${path.module}/gateway-crds.yaml")
}