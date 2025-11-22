#!/usr/bin/env bash
set -euo pipefail

# Simple validation helper for key Ansible files in Dolphin.
# - Checks that important files exist
# - Runs ansible-lint on the main playbooks (if ansible-lint is installed)

FILES=(
  "playbooks/netbird-stack.yml"
  "playbooks/caddy-stack.yml"
  "roles/netbird-server/tasks/main.yml"
  "roles/netbird-server/templates/setup.env.j2"
  "roles/caddy-reverse/tasks/main.yml"
  "roles/caddy-reverse/templates/Caddyfile.j2"
)

echo "==> Checking that required files exist..."
for f in "${FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: Missing expected file: $f" >&2
    exit 1
  else
    echo "OK: $f"
  fi
done

# Optional ansible-lint run
if command -v ansible-lint >/dev/null 2>&1; then
  echo "==> Running ansible-lint on main playbooks..."
  ansible-lint playbooks/netbird-stack.yml playbooks/caddy-stack.yml
else
  echo "NOTE: ansible-lint not found in PATH, skipping lint step."
fi

echo "All checks passed."
