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

Pi-hole runs as a Docker Compose application on TrueNAS, managed by the Ansible `pihole` playbook. Persistent state lives under `/mnt/oasis/Appdata/pihole`; DNS uses `192.168.1.17:53`; the web/API service is exposed at `http://192.168.1.17:8080/admin` because TrueNAS owns ports 80 and 443.

## Core Stack

- **Flux:** GitOps controller applying everything from `kubernetes/apps`.
- **HelmRelease + Kustomize:** app deployment and environment composition.
- **Cilium:** CNI, service routing, and LAN LoadBalancer IPs. Pods use the `veth` datapath: under `netkit` with this configuration, replies from a same-node Service backend are rejected by the receiving pod's ingress NetworkPolicy, which broke the Strimzi-managed Kafka pods. The agent refuses to start in a new datapath mode while pods created under the old one exist, so changing `bpf.datapathMode` requires recreating every pod on each node.
- **Sentinel:** SRE and PR review agents in `agents`, deployed from the Sentinel chart. The `sentinel-infra` Flux Kustomization (`sentinel/infra/`) creates its PostgreSQL database and roles, Kafka users, and their ExternalSecrets, and must be ready before the `sentinel` Kustomization (`sentinel/app/`) installs the chart. Every Sentinel ExternalSecret reads the `sentinel` 1Password item.
- **Envoy Gateway:** HTTPRoute ingress for internal domains.
- **External Secrets:** syncs secrets from 1Password.
- **OpenEBS:** local persistent volumes for app state.
- **Tailscale:** remote access to the LAN through a subnet router.
- **Observability:** Grafana, Gatus, VictoriaLogs, Fluent Bit, and Prometheus stack.
