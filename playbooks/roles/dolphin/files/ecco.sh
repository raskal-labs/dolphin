# /etc/profile.d/ecco.sh
# Simple ssh-agent helper for Git on gamecube

ecco() {
  # If an agent already exists and has keys, reuse it
  if [ -n "$SSH_AUTH_SOCK" ] && ssh-add -l >/dev/null 2>&1; then
    echo "ecco: using existing ssh-agent ($SSH_AGENT_PID)"
    ssh-add -l
    return 0
  fi

  echo "ecco: starting new ssh-agent..."
  eval "$(ssh-agent -s)" >/dev/null

  echo "ecco: loading key /root/.ssh/id_ed25519..."
  ssh-add /root/.ssh/id_ed25519

  echo "ecco: ssh-agent ready for Git (SSH_AUTH_SOCK=$SSH_AUTH_SOCK)"
  ssh-add -l
}
