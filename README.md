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
| `rift` | `192.168.1.11` | External Pi-hole host | TBD | Debian 13 | DNS host managed by Ansible, outside K3s |
| `truenas` | `192.168.1.7` | NAS / NFS storage | TBD | TrueNAS | Shared media, downloads, backups, and bulk storage |

Ansible manages the machine layer, then Flux manages Kubernetes state from this repository.

## Core Stack

- **Flux:** GitOps controller applying everything from `kubernetes/apps`.
- **HelmRelease + Kustomize:** app deployment and environment composition.
- **Cilium:** CNI, service routing, and LAN LoadBalancer IPs.
- **Envoy Gateway:** HTTPRoute ingress for internal domains.
- **External Secrets:** syncs secrets from 1Password.
- **OpenEBS:** local persistent volumes for app state.
- **Tailscale:** remote access to the LAN through a subnet router.
- **Observability:** Grafana, Gatus, VictoriaLogs, Fluent Bit, and Prometheus stack.
