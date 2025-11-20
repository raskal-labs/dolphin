#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
  DRY_RUN=true
fi

REPO_ROOT="/root/dolphin"
cd "$REPO_ROOT"

echo "==> Repo root: $REPO_ROOT"
echo "==> Dry run: $DRY_RUN"
echo

rename_dir() {
  local src="$1"
  local dst="$2"

  if [ ! -d "$src" ]; then
    echo "  - WARNING: $src not found (skipping)"
    return
  fi

  if $DRY_RUN; then
    echo "  - DRY RUN: would rename $src -> $dst"
  else
    echo "  - Renaming $src -> $dst"
    mv "$src" "$dst"
  fi
}

replace_in_files() {
  local search="$1"
  local replace="$2"

  if $DRY_RUN; then
    echo "  - DRY RUN: would replace '$search' -> '$replace' in YAML files"
  else
    sed -i "s/\\b$search\\b/$replace/g" "$f"
  fi
}

echo "==> Renaming core roles (dolphin, olimar, blathers)..."

rename_dir playbooks/roles/dolphin playbooks/roles/pve-node
rename_dir playbooks/roles/olimar playbooks/roles/pve-network
rename_dir playbooks/roles/blathers playbooks/roles/zfs-layout

echo
echo "==> Updating references inside playbooks..."

yaml_files=$(find playbooks -type f \( -name "*.yml" -o -name "*.yaml" \))

for f in $yaml_files; do
  echo "  - File: $f"
  if $DRY_RUN; then
    echo "      DRY RUN: would update role references here"
  else
    sed -i \
      -e 's/\bdolphin\b/pve-node/g' \
      -e 's/\bolimar\b/pve-network/g' \
      -e 's/\bblathers\b/zfs-layout/g' \
      "$f"
  fi
done

echo
echo "==> DONE."

if $DRY_RUN; then
  echo "Dry run complete. No changes were made."
  echo "Run again without --dry-run to apply changes."
else
  echo "Changes applied. Review with: git diff"
fi
