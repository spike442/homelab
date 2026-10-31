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

Renovate runs hourly from `.github/workflows/renovate.yaml`, on Renovate config changes, and on `sre-release`, `knowledge-release`, and `stonks-release` repository dispatches from each repository's Publish. The workflows authenticate as the bot GitHub App through the `BOT_APP_ID` and `BOT_APP_PRIVATE_KEY` secrets; the token action's `client-id` input accepts the App ID.

Flux, Helm values, and Kubernetes manifests are tracked by the built-in managers. Values those managers cannot read carry a `# renovate: datasource=<datasource> depName=<package>` comment on the line above (CloudNativePG `imageName`, the Flux distribution artifact, the Airflow Stonks version, the Kafka version). Raw GitHub URLs are pinned either to `refs/tags/<tag>`, updated from GitHub tags, or to a commit SHA on `main` for repositories without releases.

Kafka version updates wait for approval on the Dependency Dashboard: approve one only when the deployed Strimzi operator lists that version as supported.

## S3 credentials

Every app reaches RustFS with one shared S3 key: the 1Password item `s3` (`S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`), which the `ClusterExternalSecret/s3` (`kubernetes/apps/external-secrets/s3/`) projects into a Secret named `s3` in every namespace that uses S3 (`agents`, `database`, `datalakehouse`). Stonks, Knowledge, SRE, Trino, and the CloudNativePG backups read their keys from that Secret, and Airflow builds its `s3_logs` connection from the same item; no app's own item or Secret holds an S3 key. A new namespace that needs S3 is one more entry in the ClusterExternalSecret's namespace list. The key needs read and write access to every bucket the apps use (`stonks`, `sre`, `logs`, `cloudnative-pg`). RustFS's own root credentials (the `rustfs` item) stay with RustFS alone.

## Lakekeeper

Lakekeeper (`kubernetes/apps/datalakehouse/lakekeeper/`) is the Apache Iceberg REST catalog of the Stonks lake. It keeps its state in the `lakekeeper` database of `postgres0` and needs the 1Password item `lakekeeper` with `LAKEKEEPER_DB_PASSWORD` and `LAKEKEEPER_ENCRYPTION_KEY`, a random string that encrypts the warehouse storage credentials Lakekeeper stores (replacing it makes them unreadable). Authorization is `allowall` and the catalog has no authentication: Spark and the Stonks API reach it at `http://lakekeeper.datalakehouse.svc.cluster.local:8181/catalog`, and the workstation and its UI at `https://lakekeeper.timcasa.me` through the internal gateway. The chart's migration Job creates Lakekeeper's schema on install. The Stonks repository creates the warehouse, its namespaces, and its tables with `task catalog`.

## Trino

Trino (`kubernetes/apps/datalakehouse/trino/`) is the SQL engine over the Stonks lake: a single node, the coordinator scheduling queries on itself (`server.workers: 0`, `node-scheduler.include-coordinator=true`, 1GB of query memory in a 2G heap), whose `stonks` catalog is the Iceberg connector on Lakekeeper's `stonks` warehouse, reading and writing the `stonks` bucket with the shared S3 key (the `s3` Secret, through `envFrom`). It has no authentication and is reachable in the cluster at `trino.datalakehouse.svc.cluster.local:8080`, where the Stonks dbt models run, and from the workstation at `https://trino.timcasa.me` for the `trino` CLI or any JDBC client (`jdbc:trino://trino.timcasa.me:443/stonks?SSL=true`).
