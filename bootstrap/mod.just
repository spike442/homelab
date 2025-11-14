set positional-arguments := true
set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

bootstrap_dir := justfile_dir() + '/bootstrap'
ansible_playbook_dir := justfile_dir() + '/ansible/playbooks'
kubernetes_dir := justfile_dir() + '/kubernetes'

[private]
default: os k8s

[doc('prepare os')]
os:
    just log info "Running stage..." "stage" "$0"
    ansible-playbook {{ansible_playbook_dir}}/prepare.yaml

[doc('install kubernetes')]
k8s:
    just log info "Running stage..." "stage" "$0"
    ansible-playbook {{ansible_playbook_dir}}/install.yaml

[doc('fetch kubeconfig')]
kubeconfig:
  just log info "Running stage..." "stage" "$0"
  ansible-playbook {{ansible_playbook_dir}}/kubeconfig.yaml

[doc('wait for nodes to be not-ready')]
wait:
    just log info "Running stage..." "stage" "$0"
    if ! kubectl wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; then \
        until kubectl wait nodes --for=condition=Ready=False --all --timeout=10s &>/dev/null; do \
            just log info "Nodes not available, waiting for nodes to be available. Retrying in 5 seconds..." "stage" "$0"; \
            sleep 5; \
        done \
    fi

[doc('apply kubernetes namespaces')]
namespaces:
    just log info "Running stage..." "stage" "$0"
    find "{{ kubernetes_dir }}/apps" -mindepth 1 -maxdepth 1 -type d | while IFS= read -r dir; do \
        if ! kustomize build "$dir" | yq ea -e 'select(.kind == "Namespace")' | kubectl apply --server-side --field-manager bootstrap --force-conflicts -f -; then \
            just log fatal "Failed to apply namespace" "stage" "$0" "namespace" "$(basename "$dir")"; \
        fi; \
    done

[doc('Apply Kubernetes resources')]
resources:
    just log info "Running stage..." "stage" "$0"
    if ! just template "{{ bootstrap_dir }}/resources.yaml.j2" | kubectl apply --server-side --field-manager bootstrap --force-conflicts -f -; then \
        just log fatal "Failed to apply resources" "stage" "$0"; \
    fi;


[doc('apply helmfile crds')]
crds:
    just log info "Running stage..." "stage" "$0"
    if ! helmfile -f "{{ bootstrap_dir }}/helmfile.d/00-crds.yaml" template -q | kubectl apply --server-side --field-manager bootstrap --force-conflicts -f -; then \
        just log fatal "Failed to apply crds" "stage" "$0"; \
    fi;

[doc('apply helmfile apps')]
apps:
    just log info "Running stage..." "stage" "$0"
    if ! helmfile -f "{{ bootstrap_dir }}/helmfile.d/01-apps.yaml" sync --hide-notes; then \
        just log fatal "Failed to sync helmfile" "stage" "$0"; \
    fi
