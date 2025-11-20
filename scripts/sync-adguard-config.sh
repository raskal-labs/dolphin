#!/usr/bin/env bash
set -euo pipefail

# Sync live AdGuard config from ZFS into the Git repo
# Run this on the Proxmox host (gamecube) after making changes in the AdGuard GUI.

# Detect repo root (assumes this script lives under scripts/ inside the repo)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Paths
LIVE_CONFIG="/box1/apps/link-cable/AdGuardHome.yaml"
REPO_CONFIG="${REPO_ROOT}/playbooks/roles/lxc-adguard/files/AdGuardHome.yaml"

echo "==> Repo root: ${REPO_ROOT}"
echo "==> Live AdGuard config: ${LIVE_CONFIG}"
echo "==> Repo AdGuard config: ${REPO_CONFIG}"
echo

# Basic sanity checks
if [ ! -f "${LIVE_CONFIG}" ]; then
    echo "ERROR: Live config not found at ${LIVE_CONFIG}"
    echo "Make sure the bind-mount is correct and AdGuard has written its config."
    exit 1
fi

if [ ! -f "${REPO_CONFIG}" ]; then
    echo "WARNING: Repo config does not exist at ${REPO_CONFIG}"
    echo "Creating it for the first time."
    mkdir -p "$(dirname "${REPO_CONFIG}")"
else
    # Backup the existing repo copy with a timestamp
    ts="$(date +%Y%m%d-%H%M%S)"
    backup="${REPO_CONFIG}.bak.${ts}"
    echo "Backing up existing repo config to:"
    echo "  ${backup}"
    cp -p "${REPO_CONFIG}" "${backup}"
    echo
fi

echo "Copying live config into repo..."
cp -p "${LIVE_CONFIG}" "${REPO_CONFIG}"
echo "Done."
echo

# Show a quick diff so you can see what changed
if command -v git >/dev/null 2>&1; then
    echo "Git diff for AdGuardHome.yaml:"
    echo
    (cd "${REPO_ROOT}" && git diff -- playbooks/roles/lxc-adguard/files/AdGuardHome.yaml) || true
    echo
    echo "Next steps (if you're happy):"
    echo "  cd ${REPO_ROOT}"
    echo "  git add playbooks/roles/lxc-adguard/files/AdGuardHome.yaml"
    echo "  git commit -m \"Sync AdGuard config from live container\""
else
    echo "git not found in PATH, skipping diff/commit hints."
fi
