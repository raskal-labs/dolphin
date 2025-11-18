ANSIBLE_PLAYBOOK ?= ansible-playbook
ANSIBLE ?= ansible

INVENTORY ?= inventories/prod/hosts.yaml
PLAYBOOK ?= playbooks/bootstrap-dolphin.yaml
LIMIT ?=

export ANSIBLE_CONFIG := $(PWD)/ansible.cfg

.DEFAULT_GOAL := help

help:
	@echo "dolphin controls:"
	@echo "  make bootstrap        # run full bootstrap playbook"
	@echo "  make bootstrap-check  # dry-run (check mode)"
	@echo "  make ping             # ansible ping all hosts"
	@echo "  make hosts            # list hosts in inventory"
	@echo "  make facts            # gather basic facts"

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
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) playbooks/olimar-networking.yaml $(if $(LIMIT),--limit $(LIMIT),)

net-check:
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) playbooks/olimar-networking.yaml --check $(if $(LIMIT),--limit $(LIMIT),)
