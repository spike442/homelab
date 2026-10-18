# Homelab agent instructions

These rules apply to every coding agent working in this repository (Claude Code reads them through `CLAUDE.md`, Codex and others read `AGENTS.md` directly).

## Start here

- Work from the repository root. Check `git status --short` and preserve existing edits. Use `README.md` as the source map.
- This is a GitOps repository: Flux reconciles `kubernetes/apps/`. Change files only; never run commands that mutate the live cluster (`kubectl apply/edit/delete`, `helm install/upgrade`, `flux reconcile` with changes). Read-only inspection is fine when asked.
- Installs are always fresh: do not add backup restore, upgrade, or migration paths for Sentinel.
- Do not commit, push, or publish unless asked.

## Layout

- Each app lives at `kubernetes/apps/<namespace>/<app>/` with a Flux `ks.yaml` and an `app/` kustomization (HelmRelease, routes, ExternalSecrets). Shared pieces live in `kubernetes/components/`.
- Secrets come only from 1Password through External Secrets; never write credential values into the repository.
- Sentinel (`kubernetes/apps/agents/sentinel/`) deploys the chart from the Sentinel repository and owns its database roles, Kafka users and topics, ExternalSecrets, and site values. Sentinel's chart and its `config/` own Sentinel settings; one-time Sentinel initialization (SQL, prompts) runs from the Sentinel repository with `task deploy`, not from Jobs here.
- Ansible under `ansible/` manages the machine layer (`task ansible:*`, `task bootstrap:*`).

## Code style

- Write no comments in YAML, templates, or scripts. Keep only functional comments: `# yaml-language-server:` schema hints, `# renovate:` markers, and shebangs. Put explanations in `README.md`.
- Format YAML with `yamlfmt` (`.yamlfmt.yaml`).

## Validate changes

- `task pre-commit` (trailing whitespace, secrets, shellcheck, gitleaks) and `yamlfmt -lint` on changed YAML.
- `kustomize build kubernetes/apps/<namespace>/<app>/app` for each changed app.
- Run `git diff --check` and review changed files before reporting completion.
