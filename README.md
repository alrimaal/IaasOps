<div align="center">

# ☸️ IaasOps

### Production-grade GitOps lean infrastructure on Hetzner hosts running **Talos Linux**, provisioned with **Terraform** and reconciled by **FluxCD**.

<!-- ── Infrastructure ── -->

![Talos](https://img.shields.io/badge/Talos_Linux-FF7300?style=for-the-badge&logo=talos&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Hetzner](https://img.shields.io/badge/Hetzner_Cloud-D50C2D?style=for-the-badge&logo=hetzner&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=for-the-badge&logo=terraform&logoColor=white)

<!-- ── GitOps & Networking ── -->

![FluxCD](https://img.shields.io/badge/FluxCD-5468FF?style=for-the-badge&logo=flux&logoColor=white)
![Kustomize](https://img.shields.io/badge/Kustomize-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Cilium](https://img.shields.io/badge/Cilium_Gateway_API-F8C517?style=for-the-badge&logo=cilium&logoColor=black)
![cert-manager](https://img.shields.io/badge/cert--manager-32A0DE?style=for-the-badge&logo=letsencrypt&logoColor=white)
![SOPS](https://img.shields.io/badge/SOPS_+_PGP-000000?style=for-the-badge&logo=gnuprivacyguard&logoColor=white)

<!-- ── Data & Storage ── -->

![Percona](https://img.shields.io/badge/Percona_XtraDB-2C2255?style=for-the-badge&logo=percona&logoColor=white)
![MinIO](https://img.shields.io/badge/MinIO-C72E49?style=for-the-badge&logo=minio&logoColor=white)
![Elasticsearch](https://img.shields.io/badge/Elasticsearch-005571?style=for-the-badge&logo=elasticsearch&logoColor=white)
![OpenEBS](https://img.shields.io/badge/OpenEBS-E85A2B?style=for-the-badge&logo=cncf&logoColor=white)

<!-- ── Observability & Automation ── -->

![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![Loki](https://img.shields.io/badge/Loki-F5A800?style=for-the-badge&logo=grafana&logoColor=white)
![GitHub actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)

</div>

---

## 📖 Overview

IaasOps is the GitOps-aligned repository powering the infrastructure and deployments of [AlRimaal's](https://alrimaal.com) products. Since Alrimaal was launched a self-sustaining non-profit, the infrastructure had to be both lean and scalable from day 1. It's mostly comprised of open-source components self-hosted on raw Hetzner VMs with relatively low operational load and high availability.

While a lot of companies have scalable and state of the art infra, the obvious option for most small/low-budget teams is to host on BigTech cloud. This repo serves as proof that hosting complex production-grade workloads using OSS tooling is possible with low to moderate operational overhead.

**Highlights**

- 🔄 **IaC end-to-end** — Terraform provisions Talos on Hetzner, Flux (GitOps) reconciles the entire platform from Git.
- 🗄️ **HA data layer** — Replicated MySQL and MinIO with automatic recovery and backups.
- 🔐 **Secure by default** — immutable Talos OS (no SSH), secrets SOPS-encrypted in Git, transparent in-cluster encryption via Cilium.
- 📈 **Scales on demand** — cluster-autoscaler provisions nodes only for burst `ffmpeg` jobs, with full observability through Prometheus, Grafana, and Loki.

| Function              | Tooling                                                           |
| --------------------- | ----------------------------------------------------------------- |
| **OS / Compute**      | Kubernetes using Talos Linux                                      |
| **Provisioning**      | Terraform, Flux, Hetzner CSI                                      |
| **Networking**        | Cilium + Gateway API, cert-manager, Cloudflare DNS                |
| **Secrets**           | SOPS + PGP                                                        |
| **Storage**           | MinIO operator using Hetzner volumes                              |
| **Databases**         | HA Percona XtraDB (MySQL), Elasticsearch                          |
| **Observability**     | Prometheus, Grafana, Loki, Alloy                                  |
| **Disaster Recovery** | Daily Percona snapshots to Minio. Minio rsync to AWS Deep Archive |

---

## 🗺️ Architecture

<!--
  TODO: replace with the generated topology diagram.
  Recommended: mingrammer/diagrams (Python) or D2 → render to docs/overview.svg → embed below.
-->
<div align="center">
  <img src="docs/overview.svg" alt="Overview" width="900">
</div>

---

## 📁 Repository Structure

```
.
├── terraform/            # Talos + Hetzner cluster, Flux bootstrap
└── fluxcd/
    ├── cluster/          # Cluster-wide: Flux config, Helm charts, gateway, namespaces, SOPS secrets
    └── apps/             # Application workloads (base + dev/prod overlays)
```

---

## 🧰 Tech Stack

### Provisioning

All infrastructure is provisioned using IaC. We use Terraform [hcloud-talos](https://github.com/hcloud-talos/terraform-hcloud-talos) to provision the hardware (Talos), networking (Cilium), and FluxCD.

All applications are provisioned and managed using FluxCD (GitOps). External applications are installed via Helm.

For Internal applications:

- We build them using Github actions triggered by a merge on main using their docker files.
- ImageAutomation monitors new versions and commits them to this repo.
- FluxCD automatically reconciles new versions.

### Databases

MySQL is deployed using [Percona Operator](https://docs.percona.com/percona-operator-for-xtradb-cluster/1.20.0/index.html). Durability and HA are met with:

- Galera (replication layer) uses [Certificate Replication](https://mariadb.com/docs/galera-cluster/galera-architecture/certification-based-replication) where a write waits for O(WAL write + roundtrip to furthest instance). This is a leaderless topology with 3 replicas.
- Daily snapshot is taken and written to MinIO for recovery on quorum loss.
- Since HA is achieved on the application level, storage is provisioned using OpenEBS hostpath for automatic local provsioning (fast NVME storage).

All database users are declaratively generated using GitOps with passwords sops-encrypted.

ElasticSearch is deployed as a single instance.

### S3

S3 is used in multiple products including a video ondemand platform. We use [MinIO Operator](https://operator.min.io/) for a HA deployment.

- 4-server X 1 drive deployment
- Uses Hetzner volumes that are dynamically provisioned using [CSI](https://github.com/hetznercloud/csi-driver) and are LUKS encrypted.
- All buckets, users, policies are GitOps-declared using [Minio Operator Extension](https://github.com/benfiola/minio-operator-ext)
- Automatically rsynced to AWS Deep Archive for recovery in the unlikely scenario of 3 volumes failing at the same time along with their snapshots.

### Monitoring

Comprehensive monitoring of the cluster from the infra to the applications using Grafana stack.

- kube-prometheus-stack for cluster-level monitoring
- Grafana using MySQL as a backend (for persistent user preferences) for dashboards
- Alloy for application log collection pipeline
- Loki using S3 as storage for log storage/retrieval
- AlertManager for push alerts

### Autoscaling

Since caas_backend spawns CPU-intensive ffmpeg video processing workloads using k8s jobs, we use cluster-autoscaler to automatically provision nodes when there are pending pods. This keeps the compute cost minimal as videos are only processed once on upload.

---

## 🔐 Security

### Secrets

- All k8s secrets live in GitOps repo and are encrypted using sops.
- Some infra secrets that are required during provisioning are stored in Bitwarden and retrieved when doing `terraform apply`
- Secrets encrypted at rest using Talos LUKS encryption

### Certs

CertManager deployed on cluster which automatically renews SSL certificates

### TLS

[Cilium encryption](https://cilium.io/use-cases/transparent-encryption/) used for all inner-cluster communication. That's why TLS isn't needed inside the cluster.

### Firewall and SSH

Talos doesn't support SSH. Hetzner level firewall that blocks cluster access based on IP.

## Future Work

- HA elasticsearch deployment
- Application-aware horizontal autoscaling

---

<div align="center">

⭐ **Star this repo** if you found it useful!

</div>
