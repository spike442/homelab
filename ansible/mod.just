set positional-arguments := true
set quiet := true
set shell := ["/bin/bash", "-euo", "pipefail", "-c"]

[private]
default:
    just -l ansible

[doc('Initialize ansible dependencies')]
init:
    just log info "running stage..." "stage" "$0"
    ansible-galaxy install -r requirements.yaml --force

[doc('Nuclear option: destroy cluster')]
nuke:
    just log info "running stage..." "stage" "$0"
    gum confirm "confirm cluster nuke ?!" --default="No" && \
    ansible-playbook playbooks/nuke.yaml

[doc('Reboot cluster')]
reboot:
    just log info "running stage..." "stage" "$0"
    gum confirm "confirm cluster reboot ?" --default="No" && \
    ansible-playbook playbooks/reboot.yaml

[doc('Poweroff cluster')]
poweroff:
    just log info "running stage..." "stage" "$0"
    gum confirm "confirm cluster shutdown ?" --default="No" && \
    ansible all -a '/usr/bin/systemctl poweroff' --become

[doc('Test connectivity')]
ping:
    just log info "running stage..." "stage" "$0"
    ansible all -m 'ping'

[doc('Show cluster status')]
status:
    just log info "gathering cluster status..." "stage" "$0"
    echo "=== CONNECTIVITY ==="
    ansible all -m 'ping' --one-line
    echo "=== UPTIME ==="
    ansible all --one-line -a 'uptime'
    echo "=== DISK SPACE ==="
    ansible all --one-line -a 'df -h /'
