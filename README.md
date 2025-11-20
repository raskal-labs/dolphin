# Homelab Bootstrap

Ansible-based workflow for configuring a single Proxmox VE 9 node (**gamecube**) in a fully reproducible way.  
This repo contains multiple roles that layer cleanly on top of each other:

- `dolphin`  (PVE baseline)  
- `olimar`   (networking)  
- `blathers` (ZFS datasets + storage layout)

Everything here is idempotent, safe to re-run, and designed for a stateless-style homelab.

# dolphin (Proxmox Bootstrap Role)

Baseline configuration for a fresh Proxmox VE 9 (Debian 13 / trixie) install.

## Features

- Removes all Proxmox enterprise repositories  
- Enables official PVE no-subscription repo  
- Applies datacenter defaults (`keyboard`, `console`)  
- Ensures automation group/user (`labs`, `labs@pve`)  
- Grants `PVEAdmin` at `/`  
- Adds storage definitions using `pvesm`  
- Fully idempotent

## How to Run

```bash
ansible-playbook -i inventories/prod/hosts.yaml playbooks/pve-bootstrap.yaml
```

## What it Does (Summary)

1. Confirms PVE is installed  
2. Removes enterprise/ceph repo files  
3. Adds PVE no-sub repo  
4. Updates apt  
5. Sets datacenter defaults  
6. Ensures `labs` + `labs@pve`  
7. Grants permissions  
8. Defines `local-zfs` storage  

---

# olimar (Networking)

Network configuration handler for `/etc/network/interfaces`.  
Bridge definitions come from variables, not hard-coded templates.

## Features

- Renders vmbr0, vmbr1, etc, from a list  
- Timestamped backup of existing interface file  
- Clean Jinja2 template  
- Safe to re-run (cold or live)

## How to Run

```bash
ansible-playbook -i inventories/prod/hosts.yaml playbooks/pve-networking.yaml
```

---

# blathers (ZFS Storage Layout)

Creates and manages all ZFS datasets used by the homelab, and registers PVE storages.

## Dataset Layout

```text
/box1          # infra (system, apps, docs, logs)
/box2          # personal active data
/box3          # lifelog + archive
/disc          # VM ZFS storage (PVE storage: disc)
/cart          # LXC ZFS storage (PVE storage: cart)
/memory-card   # backups/archives
```

### Subdatasets

```text
box1/system
box1/apps
box1/docs
box1/logs

box2/gallery
box2/library
box2/files
box2/journal
box2/workshop
box2/save

box3/lifelog/{sms,calls,location,social,devices}
box3/archive
box3/processed
```

## What Blathers Does

- Creates datasets + subdatasets  
- Sets mountpoints  
- Applies ZFS properties (recordsize, compression, logbias)  
- Registers `disc` + `cart` via `pvesm`  
- Ensures the structure can be rebuilt exactly from scratch  

## How to Run

```bash
ansible-playbook -i inventories/prod/hosts.yaml playbooks/zfs-layout.yaml
```

---

# Directory Layout

```text
dolphin/
├── inventories/
│   └── prod/
│       └── hosts.yaml
├── playbooks/
│   ├── bootstrap-dolphin.yaml
│   ├── olimar-networking.yaml
│   ├── blathers-storage.yaml
│   └── roles/
│       ├── dolphin/
│       │   ├── defaults/
│       │   └── tasks/
│       ├── olimar/
│       │   ├── defaults/
│       │   └── tasks/
│       └── blathers/
│           ├── defaults/
│           └── tasks/
└── README.md
```

---

# Inventory

Inventory file:

`inventories/prod/hosts.yaml`

Example:

```yaml
all:
  hosts:
    gamecube:
      ansible_host: 192.168.0.20
      ansible_user: root
```

---

# Snapshots

Snapshot naming scheme:

```text
dol-00X-<label>
```

Examples:

```text
dol-001-ecco-baseline
dol-003-olimar-interfaces
dol-005-blathers-storage
```

Recursive snapshot command:

```bash
zfs snapshot -r rpool@dol-005-blathers-storage
```

---

# Notes

- Designed for a **single-node PVE homelab**  
- All tasks are idempotent  
- Safe to re-run after upgrades  
- Requires SSH agent (`ecco`) for git pushes  
