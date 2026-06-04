# Cluster Autoscaler (Hetzner) inputs.
#
# Hetzner has no Terraform-native autoscaling, so scaling is handled inside the
# cluster by the Kubernetes cluster-autoscaler (deployed via Flux, see
# fluxcd/apps/cluster-autoscaler). This file builds the secret it consumes:
# the hcloud token plus HCLOUD_CLUSTER_CONFIG, which carries the Talos worker
# machine config that booted nodes use to join the cluster.
#
# Autoscaled nodes are byte-for-byte identical to the static workers (same Talos
# snapshot + same worker config): a plain burst pool that any pending pod can use.

locals {
  # Identity applied to autoscaled nodes. Kept as the single source of truth so
  # the Talos cloudInit (what the node actually registers with) and the
  # autoscaler's scheduling simulation stay in sync.
  autoscaler_node_labels = {
    "autoscaler" = "true"
  }
  autoscaler_node_taints = [
    {
      key    = "autoscaler"
      value  = "true"
      effect = "NoSchedule"
    }
  ]

  # All workers share one machine config (the worker_nodes in k8s.tf define no
  # per-node labels/taints), so the first one is representative.
  autoscaler_worker_base = values(module.talos.talos_machine_configurations_worker)[0].machine_configuration

  # # Inject the label + taint into the same keys the module itself uses
  # # (machine.nodeLabels and machine.kubelet.extraConfig.registerWithTaints),
  # # preserving everything else (imageGC config, openebs mounts, host entries...).
  # autoscaler_cloudinit = yamlencode(merge(local.autoscaler_worker_base, {
  #   machine = merge(local.autoscaler_worker_base.machine, {
  #     nodeLabels = merge(try(local.autoscaler_worker_base.machine.nodeLabels, {}), local.autoscaler_node_labels)
  #     kubelet = merge(local.autoscaler_worker_base.machine.kubelet, {
  #       extraConfig = merge(try(local.autoscaler_worker_base.machine.kubelet.extraConfig, {}), {
  #         registerWithTaints = local.autoscaler_node_taints
  #       })
  #     })
  #   })
  # }))

  # HCLOUD_CLUSTER_CONFIG (base64-encoded JSON). The nodeConfigs key ("cx33-hel1")
  # must match autoscalingGroups[].name in the HelmRelease values.
  # defaultSubnetIPRange matches node_ipv4_cidr in k8s.tf so booted nodes land in
  # the node subnet that the worker config's kubelet.nodeIP.validSubnets expects.
  # imagesForArch uses the same os=talos label selector the module uses
  # (server.tf data.hcloud_image.x86), so the autoscaler boots the most-recent
  # snapshot built by _packer/create.sh. The autoscaler filters x86 by the image
  # architecture attribute itself, so no arch label is needed in the selector.
  autoscaler_cluster_config = base64encode(jsonencode({
    imagesForArch = {
      arm64 = ""
      amd64 = "os=talos"
    }
    defaultSubnetIPRange = "10.0.1.0/24"
    nodeConfigs = {
      "cx33-hel1" = {
        cloudInit = local.autoscaler_worker_base
        labels = {
          "node.kubernetes.io/role" = "autoscaler-node"
        }
      }
    }
  }))
}

# Consumed by the cluster-autoscaler HelmRelease via `envFromSecret`. Created
# directly in the cluster by Terraform (same pattern as kubernetes_secret.sops_gpg)
# because the worker config is Terraform-generated and embeds cluster-join secrets.
resource "kubernetes_secret" "cluster_autoscaler_hcloud" {
  metadata {
    name      = "cluster-autoscaler-hcloud"
    namespace = "kube-system"
  }

  data = {
    HCLOUD_TOKEN          = data.bitwarden_secret.hcloud_token.value
    HCLOUD_CLUSTER_CONFIG = local.autoscaler_cluster_config
    HCLOUD_NETWORK        = tostring(module.talos.hetzner_network_id)
    HCLOUD_FIREWALL       = tostring(module.talos.firewall_id)
  }

  type       = "Opaque"
  depends_on = [module.talos, flux_bootstrap_git.this]
}
