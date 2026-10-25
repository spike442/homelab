# Homelab K3s Cluster

GitOps-managed homelab cluster for media, networking, observability, storage, and personal experiments.

## Architecture

```text
Ansible
  └─ prepares hosts and base machine configuration

Git repository
  └─ Flux reconciles Kubernetes manifests
      └─ K3s cluster
          ├─ control-plane / server nodes
          ├─ worker / agent nodes
          ├─ Cilium networking and LoadBalancer IPs
          ├─ Envoy Gateway ingress
          ├─ OpenEBS local app storage
          └─ NAS/NFS media storage
```

## K3s Machines

| Machine | IP | Role | Specs | OS | Notes |
| --- | --- | --- | --- | --- | --- |
| `nexus` | `192.168.1.9` | K3s server / control-plane | `16 CPU`, `32 GiB RAM`, `amd64` | Debian 13 | Main cluster node and workload host |
| `atlas` | `192.168.1.12` | K3s server / control-plane | `8 CPU`, `16 GiB RAM`, `amd64` | Debian 13 | Secondary control-plane and workload host |
| `truenas` | `192.168.1.17` | NAS / Pi-hole host | TrueNAS 25.04 | Shared media, downloads, backups, bulk storage, and Pi-hole Docker Compose |

Ansible manages the machine layer, then Flux manages Kubernetes state from this repository.

## Renovate

Renovate runs hourly from `.github/workflows/renovate.yaml`, on Renovate config changes, and on `shed-release` repository dispatches from Shed Publish. The workflows authenticate as the bot GitHub App through the `BOT_APP_ID` and `BOT_APP_PRIVATE_KEY` secrets; the token action's `client-id` input accepts the App ID.

Flux, Helm values, and Kubernetes manifests are tracked by the built-in managers. Values those managers cannot read carry a `# renovate: datasource=<datasource> depName=<package>` comment on the line above (CloudNativePG `imageName`, the Flux distribution artifact, the Airflow Stonks version, the Kafka version). Raw GitHub URLs are pinned either to `refs/tags/<tag>`, updated from GitHub tags, or to a commit SHA on `main` for repositories without releases.

Kafka version updates wait for approval on the Dependency Dashboard: approve one only when the deployed Strimzi operator lists that version as supported.
