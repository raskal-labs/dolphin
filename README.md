# Dolphin (Proxmox Bootstrap Role)

Homelab bootstrap role for a single Proxmox VE node.  
This repo contains an Ansible-based workflow that applies a consistent baseline configuration to your PVE host.

## Features

- Removes all Proxmox enterprise repositories  
- Enables the official no-subscription repository (PVE 9 / Debian 13 "trixie")
- Applies baseline datacenter config (keyboard and console mode)
- Ensures your API automation group exists (`labs`)
- Ensures `labs@pve` automation user exists and has `PVEAdmin` role
- Adds storage definitions using `pvesm` (currently just `local-zfs`)
- Fully idempotent (safe to re-run)

## Requirements

- Proxmox VE **9** (Debian **13** / trixie)
- Ansible installed on your control machine (or on the node itself)
- SSH access to the target node
- Your SSH key must be loaded into the agent before pushing/pulling from GitHub

## Directory Layout

```
dolphin/
├── inventories/
│   └── prod/
│       └── hosts.yaml
├── playbooks/
│   ├── bootstrap-dolphin.yaml
│   └── roles/
│       └── dolphin/
│           ├── defaults/
│           │   └── main.yml
│           └── tasks/
│               ├── configure.yml
│               └── main.yml
└── README.md
```

## Inventory

Define your Proxmox host inside:

`inventories/prod/hosts.yaml`

Example:

```yaml
all:
  hosts:
    gamecube:
      ansible_host: 192.168.0.20
      ansible_user: root
```

## How to Run

From the repo root:

```bash
ansible-playbook -i inventories/prod/hosts.yaml playbooks/bootstrap-dolphin.yaml
```

If you keep your SSH key locked behind `ssh-agent`, make sure your agent is running and the key is loaded before invoking Ansible.

## What the Playbook Does

1. Validates Proxmox is installed by calling `pveversion`
2. Removes:
   - `pve-enterprise.list`
   - `pve-enterprise.sources`
   - `ceph.list`
   - `ceph-squid.list`
   - `ceph.sources`
3. Ensures `/etc/apt/keyrings` exists
4. Creates the PVE no-subscription repo file:
   ```
   deb http://download.proxmox.com/debian/pve trixie pve-no-subscription
   ```
5. Runs `apt update`
6. Writes `/etc/pve/datacenter.cfg`:
   ```
   keyboard: en-us
   console: shell
   ```
7. Creates the `labs` group (if missing)
8. Creates `labs@pve` (if missing)
9. Grants `PVEAdmin` privileges to the group
10. Adds storages defined in `defaults/main.yml` using `pvesm`

## Notes

- This repo is meant for a single-node homelab, not a cluster.
- You can safely re-run the playbook after Proxmox updates.
- All tasks are idempotent and won’t duplicate work.
- When pushing from the PVE node, ensure your SSH agent has the key loaded (e.g. with `ecco`).
