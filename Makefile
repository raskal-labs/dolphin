# Makefile for Dolphin Homelab

ANSIBLE_PLAYBOOK ?= ansible-playbook
ANSIBLE ?= ansible
INVENTORY ?= inventories/prod/hosts.yml
VAULT_PASS ?= .vault_pass

# Default Target
.DEFAULT_GOAL := help

# Environment Setup
export ANSIBLE_CONFIG := $(PWD)/ansible.cfg

help:
	@echo "🐬 Dolphin Homelab Commands:"
	@echo "  make deploy       # Run the full site.yml (Init -> Storage -> Net -> Apps)"
	@echo "  make init         # Run only Host Initialization (pve-init)"
	@echo "  make storage      # Run only ZFS Storage Layout (zfs-layout)"
	@echo "  make net          # Run only Networking Config (pve-networking)"
	@echo "  make adguard      # Run only AdGuard Deployment (lxc-adguard)"
	@echo "  make ping         # Ping all hosts"
	@echo "  make dry-run      # Test the full deployment (Check Mode)"

# --- Main Deployment ---
deploy:
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) site.yml --vault-password-file $(VAULT_PASS)

dry-run:
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) site.yml --vault-password-file $(VAULT_PASS) --check

# --- Individual Modules ---
init:
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) playbooks/pve-init.yml --vault-password-file $(VAULT_PASS)

storage:
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) playbooks/zfs-layout.yml --vault-password-file $(VAULT_PASS)

net:
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) playbooks/pve-networking.yml --vault-password-file $(VAULT_PASS)

adguard:
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) playbooks/lxc-adguard.yml --vault-password-file $(VAULT_PASS)

# --- Utilities ---
ping:
	$(ANSIBLE) -i $(INVENTORY) all -m ping
