#!/usr/bin/env bash
set -euo pipefail

OLD_ROLE="link-cable"
NEW_ROLE="lxc-adguard"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
if [[ -z "$ROOT" ]]; then
  echo "Error: must run inside a git repo."
  exit 1
fi

cd "$ROOT"

echo "==> Repo root: $ROOT"
echo "==> Renaming role: $OLD_ROLE -> $NEW_ROLE"
echo "==> Dry run: $DRY_RUN"
echo

# Ensure clean working tree
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: git working tree is not clean."
  echo "Commit or stash your changes before running this script."
  exit 1
fi

ROLE_OLD_DIR="playbooks/roles/${OLD_ROLE}"
ROLE_NEW_DIR="playbooks/roles/${NEW_ROLE}"
PLAYBOOK_FILE="playbooks/lxc-adguard.yaml"

if [[ ! -d "$ROLE_OLD_DIR" ]]; then
  echo "Error: $ROLE_OLD_DIR does not exist."
  exit 1
fi

if [[ ! -f "$PLAYBOOK_FILE" ]]; then
  echo "Error: $PLAYBOOK_FILE not found."
  exit 1
fi

if $DRY_RUN; then
  echo "DRY RUN:"
  echo "  - Would move: $ROLE_OLD_DIR -> $ROLE_NEW_DIR"
  echo "  - Would update role reference in: $PLAYBOOK_FILE"
  echo
  echo "No changes made."
  exit 0
fi

# Backup ref for undo
BACKUP_REF="$(git rev-parse HEAD)"
echo "$BACKUP_REF" > .git/rename_link_cable_role_backup_ref
echo "Backup git ref recorded: $BACKUP_REF (.git/rename_link_cable_role_backup_ref)"
echo

# Move the role directory
echo "Renaming role directory..."
mv "$ROLE_OLD_DIR" "$ROLE_NEW_DIR"
echo "  Moved $ROLE_OLD_DIR -> $ROLE_NEW_DIR"

# Update the playbook's roles list WITHOUT changing hosts: link-cable
echo "Updating playbook role reference in $PLAYBOOK_FILE..."
sed -i -E 's/^(\s*-\s*)link-cable(\s*)$/\1lxc-adguard\2/' "$PLAYBOOK_FILE"
echo "  Updated roles: - link-cable -> - lxc-adguard"

echo
echo "Done."
echo "Next steps:"
echo "  1) Review changes: git diff"
echo "  2) Test: ansible-playbook $PLAYBOOK_FILE -i inventories/prod/hosts.yaml --limit link-cable"
echo "  3) If happy: git add . && git commit -m \"Rename link-cable role to lxc-adguard\""
echo
echo "If something looks wrong, you can manually reset to the backup ref:"
echo "  git reset --hard $(cat .git/rename_link_cable_role_backup_ref)"
