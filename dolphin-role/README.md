# dolphin (Proxmox core config role)

`dolphin` is the first layer in the homelab bootstrap.  
It handles the basic Proxmox VE configuration so the host is in a predictable state before building anything else on top.

This role is intentionally small. It only manages things that every other layer depends on.

---

## What dolphin does

- removes all Proxmox enterprise/ceph enterprise repos  
- enables the PVE “no-subscription” repository  
- runs an apt metadata update  
- writes simple datacenter defaults (`keyboard`, `console`)  
- creates a `labs` PVE group  
- creates `labs@pve` user and assigns it to that group  
- applies the `PVEAdmin` ACL for that group at `/`  
- ensures the `local-zfs` storage exists on `rpool/data`

All tasks are idempotent. Running the playbook multiple times is safe.

---

## What dolphin does *not* do

- it doesn’t install Proxmox  
- it doesn’t configure networking  
- it doesn’t create LXCs or VMs  
- it doesn’t touch host-level OS configs  
- it doesn’t manage developer tools (tree, htop, etc.)

Those belong to later layers (e.g., `wavebird`, `falco`, `orchard`, etc).

---

## Layout

