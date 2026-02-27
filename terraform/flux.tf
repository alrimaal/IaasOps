provider "flux" {
  kubernetes = {
    config_path = local_file.kubeconfig.filename
  }

  git = {
    url = "https://github.com/alrimaal/IaasOps"
    http = {
      username = "git" # Using PAT so any string works
      password = data.bitwarden_secret.flux_github_token.value
    }
    branch = "migration"
  }
}

provider "github" {
  owner = "alrimaal"
  token = data.bitwarden_secret.flux_github_token.value
}


resource "flux_bootstrap_git" "this" {
  path = "fluxcd/cluster/production"
  timeouts = {
    create = "1m"
    read   = "1m"
    delete = "1m"
    update = "1m"
  }
  components_extra = ["image-reflector-controller", "image-automation-controller"]
  depends_on       = [module.talos, local_file.kubeconfig, local_file.talosconfig]
}