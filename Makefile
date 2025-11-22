ANSIBLE_PLAYBOOK ?= ansible-playbook
ANSIBLE ?= ansible

INVENTORY ?= inventories/prod/hosts.yml
PLAYBOOK ?= playbooks/pve-bootstrap.yml
LIMIT ?=

export ANSIBLE_CONFIG := $(PWD)/ansible.cfg

.DEFAULT_GOAL := help

help:
	@echo "homelab controls:"
	@echo "  make bootstrap        # run full Proxmox bootstrap playbook"
	@echo "  make bootstrap-check  # dry-run (check mode) for bootstrap"
	@echo "  make net              # apply Proxmox networking playbook"
	@echo "  make net-check        # dry-run (check mode) for networking"
	@echo "  make storage          # apply ZFS layout playbook"
	@echo "  make ping             # ansible ping all hosts"
	@echo "  make hosts            # list hosts in inventory"
	@echo "  make facts            # gather basic facts"
	@echo "  make adguard-sync     # sync live AdGuard config into Git"

bootstrap:
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) $(PLAYBOOK) $(if $(LIMIT),--limit $(LIMIT),)

bootstrap-check:
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) $(PLAYBOOK) --check $(if $(LIMIT),--limit $(LIMIT),)

ping:
	$(ANSIBLE) -i $(INVENTORY) all -m ping

hosts:
	$(ANSIBLE) -i $(INVENTORY) all --list-hosts

facts:
	$(ANSIBLE) -i $(INVENTORY) all -m setup -a 'gather_subset=min'

net:
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) playbooks/pve-networking.yml $(if $(LIMIT),--limit $(LIMIT),)

net-check:
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) playbooks/pve-networking.yml --check $(if $(LIMIT),--limit $(LIMIT),)

storage:
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) playbooks/zfs-layout.yml $(if $(LIMIT),--limit $(LIMIT),)

adguard-sync:
	./scripts/sync-adguard-config.sh
