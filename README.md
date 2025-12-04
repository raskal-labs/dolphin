# Dolphin Homelab 🐬

Ansible-based infrastructure-as-code for configuring a Proxmox VE 9 node (**gamecube**) and its services.

This project is designed to be **stateless and idempotent**. You can wipe the host OS, reinstall Proxmox, and run this playbook to restore the entire configuration, including networking, storage, and applications.

## 📂 Project Structure

- **`site.yml`**: Master playbook. Orchestrates the entire deployment order.
- **`inventories/prod/`**:
  - `hosts.yml`: Defines the PVE host (`gamecube`) and local connection method.
  - `group_vars/all/services.yml`: Global service registry (IPs, Ports, Domains).
  - `host_vars/`: Host-specific overrides.
- **`roles/`**:
  - **`pve-init`**: Baseline setup (Repos, Packages, SSH Keys, Time Sync).
  - **`zfs-layout`**: Manages ZFS datasets (`rpool/box1`, `rpool/memory-card`).
  - **`pve-networking`**: Configures network bridges (`vmbr0`, `vmbr1`).
  - **`lxc-adguard`**: Provisions and configures AdGuard Home (with ZFS persistence).
  - **`pve-lxc`**: Generic LXC creation logic.

## 🚀 Quick Start

### Prerequisites
1. A fresh Proxmox VE 9 installation.
2. WinSCP/PuTTY public key placed in `keys/winscp.pub` (for personal access).
3. Vault password file `.vault_pass` in the project root.

### Deployment

Run the entire stack (Init -> Storage -> Network -> Apps):

```bash
# Using Make (Recommended)
make deploy

# Manual Command
ansible-playbook -i inventories/prod/hosts.yml site.yml --vault-password-file .vault_pass
