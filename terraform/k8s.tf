module "talos" {
  source  = "hcloud-talos/talos/hcloud"
  version = "2.16.0"

  # Use versions compatible with each other and supported by the module/Talos
  talos_version             = "v1.10.0"
  kubernetes_version        = "1.30.3"
  cilium_version            = "1.16.2"
  cilium_enable_gateway_api = true
  cilium_enable_encryption  = true

  hcloud_token = data.bitwarden_secret.hcloud_token.value

  cluster_name    = "cluster"
  cluster_domain  = "cluster.local"
  datacenter_name = "fsn1-dc14"

  output_mode_config_cluster_endpoint = "public_ip"
  firewall_use_current_ip             = true
  extra_firewall_rules = [
    {
      direction   = "in"
      protocol    = "tcp"
      port        = "30178"
      source_ips  = ["10.0.0.0/8"]
      description = "Allow access to NodePort services within private network (for load balancer)"
    }
  ]

  enable_floating_ip = true
  enable_alias_ip    = true


  control_plane_count       = 3
  control_plane_server_type = "cx22"

  worker_count       = 3
  worker_server_type = "cpx21"
  disable_arm        = true

  network_ipv4_cidr = "10.0.0.0/16"
  node_ipv4_cidr    = "10.0.1.0/24"
  pod_ipv4_cidr     = "10.0.16.0/20"
  service_ipv4_cidr = "10.0.8.0/21"

  talos_worker_extra_config_patches = [
    <<EOT
    machine:
      kubelet:
        extraMounts:
          #Default Hostpath directory
          - destination: /var/openebs/local
            type: bind
            source: /var/openebs/local
            options:
              - rbind
              - rshared
              - rw
    EOT
  ]

}

output "talosconfig" {
  value     = module.talos.talosconfig
  sensitive = true
}

output "kubeconfig" {
  value     = module.talos.kubeconfig
  sensitive = true
}

resource "local_file" "kubeconfig" {
  content         = module.talos.kubeconfig
  filename        = "${path.module}/kubeconfig.yaml"
  file_permission = "600"
}

resource "local_file" "talosconfig" {
  content         = module.talos.talosconfig
  filename        = "${path.module}/talosconfig.yaml"
  file_permission = "600"
}

resource "kubernetes_secret" "sops_gpg" {
  metadata {
    name      = "sops-gpg"
    namespace = "flux-system"
  }

  data = {
    "sops.asc" = data.bitwarden_secret.gpg_sops_private_key.value
  }
  depends_on = [module.talos, local_file.talosconfig]

  type = "Opaque"
}