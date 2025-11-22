#!/bin/bash
set -euo pipefail

echo "🔧 Fixing script references from playbooks/roles → roles..."

# Update all scripts with role path fixes
sed -i 's|playbooks/roles/|roles/|g' ./scripts/gen-dolphin-ssh-key.sh
sed -i 's|playbooks/roles/|roles/|g' ./scripts/rename_core_roles.sh
sed -i 's|playbooks/roles/|roles/|g' ./scripts/rename_link_cable_role.sh
sed -i 's|playbooks/roles/|roles/|g' ./scripts/sync-adguard-config.sh

echo "✅ Script references fixed."

echo "🧹 Cleaning up YAML comments mentioning playbooks/roles..."

# Delete comment lines in roles that mention playbooks/roles
find ./roles -type f -name '*.yml' -o -name '*.yml' | while read -r file; do
  sed -i '/^\s*#.*playbooks\/roles\//d' "$file"
done

echo "✅ YAML comment cleanup done."

echo "✅ All done. You can now review, commit, and snapshot."

echo "Suggested next steps:"
echo "  git add scripts/ roles/"
echo "  git commit -m 'Cleaned up role paths and references after roles/ move'"
echo "  zfs snapshot rpool/dolphin@dol-006-04-roles-final"
