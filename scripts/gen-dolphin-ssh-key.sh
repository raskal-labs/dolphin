#!/usr/bin/env bash
set -euo pipefail

# Run this from the repo root: /root/dolphin
REPO_ROOT="$(pwd)"
KEY_DIR="$REPO_ROOT/roles/dolphin/files"

mkdir -p "$KEY_DIR"

echo "Generating new ed25519 keypair in:"
echo "  $KEY_DIR/id_ed25519"
echo

ssh-keygen -t ed25519 -f "$KEY_DIR/id_ed25519" -C "gamecube-dolphin"

chmod 600 "$KEY_DIR/id_ed25519"
chmod 644 "$KEY_DIR/id_ed25519.pub"

echo
echo "Public key (add this to GitHub -> SSH keys):"
echo "----------------------------------------------------------------"
cat "$KEY_DIR/id_ed25519.pub"
echo "----------------------------------------------------------------"
echo
echo "Next steps:"
echo "  1) Copy that public key into GitHub (Settings -> SSH and GPG keys)."
echo "  2) Run: ssh -T git@github.com   to test."
echo "  3) Run your dolphin bootstrap so it copies the key into /root/.ssh."
