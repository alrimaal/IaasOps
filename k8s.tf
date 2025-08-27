module "talos" {
  source  = "hcloud-talos/talos/hcloud"
  version = "2.16.0"

  # Use versions compatible with each other and supported by the module/Talos
  talos_version      = "v1.10.0"
  kubernetes_version = "1.30.3"
  cilium_version     = "1.16.2"

  hcloud_token = data.bitwarden_secret.hcloud_token.value

  cluster_name     = "alrimaal"
  cluster_domain   = "alrimaal.local"
  datacenter_name = "fsn1-dc14"

  output_mode_config_cluster_endpoint = "public_ip"
  firewall_use_current_ip = true
  
  enable_floating_ip = true
  enable_alias_ip = true


  control_plane_count       = 1
  control_plane_server_type = "cax11"

  worker_count       = 2
  worker_server_type = "cax21"
  disable_x86 = true

  network_ipv4_cidr = "10.0.0.0/16"
  node_ipv4_cidr    = "10.0.1.0/24"
  pod_ipv4_cidr     = "10.0.16.0/20"
  service_ipv4_cidr = "10.0.8.0/21"
}
output "talosconfig" {
  value     = module.talos.talosconfig
  sensitive = true
}

output "kubeconfig" {
  value     = module.talos.kubeconfig
  sensitive = true
}