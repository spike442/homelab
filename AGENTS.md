# Homelab agent instructions

These rules apply to every coding agent working in this repository (Claude Code reads them through `CLAUDE.md`, Codex and others read `AGENTS.md` directly).

## Start here

- Work from the repository root. Check `git status --short` and preserve existing edits. Use `README.md` as the source map.
- This is a GitOps repository: Flux reconciles `kubernetes/apps/`. Change files only; never run commands that mutate the live cluster (`kubectl apply/edit/delete`, `helm install/upgrade`, `flux reconcile` with changes). Read-only inspection is fine when asked.
- Installs are always fresh: do not add backup restore, upgrade, or migration paths for SRE, Knowledge, or Stonks.
- Do not commit, push, or publish unless asked.

## Layout

- Each app lives at `kubernetes/apps/<namespace>/<app>/` with a Flux `ks.yaml` and an `app/` kustomization (HelmRelease, routes, ExternalSecrets). Shared pieces live in `kubernetes/components/`.
- Secrets come only from 1Password through External Secrets; never write credential values into the repository.
- The agent releases in `agents` deploy charts from their own repositories: SRE (`kubernetes/apps/agents/sre/`, from `spike442/sre`) owns its database role, Kafka users and ACLs, ExternalSecrets, and site values; Knowledge (`kubernetes/apps/agents/knowledge/`, from `spike442/knowledge`) and Stonks (`kubernetes/apps/agents/stonks/`, from `spike442/stonks`) own their ExternalSecrets and site values. Each chart and its `config/` own the application's settings; one-time initialization (SQL, prompts, Iceberg tables) runs from each repository with `task sql`, `task s3`, or `task catalog`, not from Jobs here.
- Ansible under `ansible/` manages the machine layer (`task ansible:*`, `task bootstrap:*`).

## Code style

- Write no comments in YAML, templates, or scripts. Keep only functional comments: `# yaml-language-server:` schema hints, `# renovate:` markers, and shebangs. Put explanations in `README.md`.
- Format YAML with `yamlfmt` (`.yamlfmt.yaml`).

## Validate changes

- `task pre-commit` (trailing whitespace, secrets, shellcheck, gitleaks) and `yamlfmt -lint` on changed YAML.
- `kustomize build kubernetes/apps/<namespace>/<app>/app` for each changed app.
- Run `git diff --check` and review changed files before reporting completion.
