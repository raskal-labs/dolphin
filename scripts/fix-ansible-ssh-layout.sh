#!/usr/bin/env bash
set -euo pipefail

# Fix up Ansible SSH layout:
# - Remove SSH key settings from netbird_stack.yml
# - Ensure lxc.yml defines:
#     ansible_ssh_private_key_file: /root/.ssh/id_ed25519_ansible
#     pve_lxc_ssh_bootstrap_pubkey_path: /root/.ssh/id_ed25519_ansible.pub
#
# Modes:
#   --dry-run  Show diffs only, no changes
#   --apply    Apply changes (creates .sshfix.bak backups if missing)
#   --undo     Restore from .sshfix.bak backups

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

NETBIRD_GV="$ROOT_DIR/inventories/prod/group_vars/netbird_stack.yml"
LXC_GV="$ROOT_DIR/inventories/prod/group_vars/lxc.yml"

BACK_SUFFIX=".sshfix.bak"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run | --apply | --undo]

  --dry-run   Show proposed changes, do not modify files
  --apply     Apply changes, creating backups if needed
  --undo      Restore files from backups created by --apply
EOF
  exit 1
}

if [[ $# -ne 1 ]]; then
  usage
fi

MODE="$1"

require_file() {
  local f="$1"
  if [[ ! -f "$f" ]]; then
    echo "ERROR: Required file not found: $f" >&2
    exit 1
  fi
}

backup_if_needed() {
  local f="$1"
  local bak="${f}${BACK_SUFFIX}"
  if [[ -f "$bak" ]]; then
    echo "Backup already exists for $f -> $bak"
  else
    echo "Creating backup: $bak"
    cp "$f" "$bak"
  fi
}

transform_netbird() {
  local src="$1"
  local dst="$2"

  # Remove any SSH related lines we do not want in netbird_stack.yml
  sed \
    -e '/^[[:space:]]*pve_lxc_ssh_bootstrap_pubkey_path[[:space:]]*:/d' \
    -e '/^[[:space:]]*ansible_ssh_private_key_file[[:space:]]*:/d' \
    "$src" > "$dst"
}

transform_lxc() {
  local src="$1"
  local dst="$2"

  awk '
  BEGIN {
    seen_privkey = 0
    seen_pubkey  = 0
  }
  {
    # Normalize ansible_ssh_private_key_file
    if ($0 ~ /^[[:space:]]*ansible_ssh_private_key_file[[:space:]]*:/) {
      print "ansible_ssh_private_key_file: /root/.ssh/id_ed25519_ansible"
      seen_privkey = 1
      next
    }

    # Normalize pve_lxc_ssh_bootstrap_pubkey_path
    if ($0 ~ /^[[:space:]]*pve_lxc_ssh_bootstrap_pubkey_path[[:space:]]*:/) {
      print "pve_lxc_ssh_bootstrap_pubkey_path: /root/.ssh/id_ed25519_ansible.pub"
      seen_pubkey = 1
      next
    }

    print
  }
  END {
    if (seen_privkey == 0 || seen_pubkey == 0) {
      print ""
    }
    if (seen_privkey == 0) {
      print "ansible_ssh_private_key_file: /root/.ssh/id_ed25519_ansible"
    }
    if (seen_pubkey == 0) {
      print "pve_lxc_ssh_bootstrap_pubkey_path: /root/.ssh/id_ed25519_ansible.pub"
    }
  }
  ' "$src" > "$dst"
}

do_dry_run() {
  echo "Dry run. No files will be modified."
  echo

  require_file "$NETBIRD_GV"
  require_file "$LXC_GV"

  local tmp_netbird tmp_lxc
  tmp_netbird="$(mktemp)"
  tmp_lxc="$(mktemp)"

  transform_netbird "$NETBIRD_GV" "$tmp_netbird"
  transform_lxc "$LXC_GV" "$tmp_lxc"

  echo "=== Diff for $NETBIRD_GV ==="
  if ! diff -u "$NETBIRD_GV" "$tmp_netbird" || true; then
    :
  fi
  echo

  echo "=== Diff for $LXC_GV ==="
  if ! diff -u "$LXC_GV" "$tmp_lxc" || true; then
    :
  fi
  echo

  rm -f "$tmp_netbird" "$tmp_lxc"
}

do_apply() {
  require_file "$NETBIRD_GV"
  require_file "$LXC_GV"

  backup_if_needed "$NETBIRD_GV"
  backup_if_needed "$LXC_GV"

  local tmp_netbird tmp_lxc
  tmp_netbird="$(mktemp)"
  tmp_lxc="$(mktemp)"

  echo "Applying transforms..."

  transform_netbird "$NETBIRD_GV" "$tmp_netbird"
  transform_lxc "$LXC_GV" "$tmp_lxc"

  mv "$tmp_netbird" "$NETBIRD_GV"
  mv "$tmp_lxc" "$LXC_GV"

  echo "Done. Backups stored as:"
  echo "  $NETBIRD_GV$BACK_SUFFIX"
  echo "  $LXC_GV$BACK_SUFFIX"
}

do_undo() {
  local any=0
  for f in "$NETBIRD_GV" "$LXC_GV"; do
    local bak="${f}${BACK_SUFFIX}"
    if [[ -f "$bak" ]]; then
      echo "Restoring $f from $bak"
      # Optional: keep a copy of the current version before overwriting
      cp "$f" "${f}.sshfix.current.$(date +%Y%m%d%H%M%S).bak"
      cp "$bak" "$f"
      any=1
    else
      echo "No backup found for $f, skipping"
    fi
  done

  if [[ "$any" -eq 0 ]]; then
    echo "Nothing to undo. No backups found."
  else
    echo "Undo complete."
  fi
}

case "$MODE" in
  --dry-run)
    do_dry_run
    ;;
  --apply)
    do_apply
    ;;
  --undo)
    do_undo
    ;;
  *)
    usage
    ;;
esac
