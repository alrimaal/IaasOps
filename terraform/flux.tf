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
    }
}

provider "github" {
  owner = "alrimaal"
  token = data.bitwarden_secret.flux_github_token.value
}


resource "flux_bootstrap_git" "this" {
  path               = "fluxcd"
  log_level = "debug"
  timeouts = {
    create = "1m"
    read = "1m"
    delete = "1m"
    update = "1m"
  }
  depends_on = [ module.talos ]
}