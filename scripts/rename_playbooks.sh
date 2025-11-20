#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> Repo root: ${REPO_ROOT}"
echo "==> Dry run: ${DRY_RUN}"
echo

cd "${REPO_ROOT}"

# Mapping: old -> new
declare -A RENAMES=(
  ["playbooks/bootstrap-dolphin.yaml"]="playbooks/pve-bootstrap.yaml"
  ["playbooks/olimar-networking.yaml"]="playbooks/pve-networking.yaml"
  ["playbooks/blathers-storage.yaml"]="playbooks/zfs-layout.yaml"
  ["playbooks/link-cable-adguard.yaml"]="playbooks/lxc-adguard.yaml"
)

if ! $DRY_RUN; then
  backup_ref="$(git rev-parse HEAD)"
  echo "Backup git ref recorded: ${backup_ref} (.git/rename_playbooks_backup_ref)"
  echo "${backup_ref}" > .git/rename_playbooks_backup_ref
  echo
fi

for old in "${!RENAMES[@]}"; do
  new="${RENAMES[$old]}"

  if [[ ! -f "${old}" ]]; then
    echo "WARNING: ${old} does not exist, skipping"
    continue
  fi

  if $DRY_RUN; then
    echo "DRY RUN: would move ${old} -> ${new}"
  else
    echo "Moving ${old} -> ${new}"
    mkdir -p "$(dirname "${new}")"
    mv "${old}" "${new}"
  fi
done

echo

# Now update references in the repo
for old in "${!RENAMES[@]}"; do
  new="${RENAMES[$old]}"

  # We’ll search for the string "playbooks/<oldname>" and replace it with the new one
  old_str="${old}"
  new_str="${new}"

  # Find files that mention this playbook
  files=$(git grep -l -- "${old_str}" || true)

  if [[ -z "${files}" ]]; then
    echo "No references found for ${old_str}, skipping replacement."
    continue
  fi

  echo "Updating references: ${old_str} -> ${new_str}"
  while IFS= read -r f; do
    if $DRY_RUN; then
      echo "  DRY RUN: would update ${f}"
    else
      sed -i "s|${old_str}|${new_str}|g" "${f}"
    fi
  done <<< "${files}"
done

echo
echo "==> DONE."

if $DRY_RUN; then
  echo "Dry run complete. No changes were made."
  echo "Run again without --dry-run to apply changes."
else
  echo "Changes applied. Review with: git diff"
  echo "If needed, you can reset to backup ref with:"
  echo "  git reset --hard $(cat .git/rename_playbooks_backup_ref)"
fi

