#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="../env/homelab.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "[!] Missing env file: $ENV_FILE"
  exit 1
fi

# Load env

set -a
source "$ENV_FILE"
set +a

log() { echo "[*] $*"; }

mkdir -p ~/.ssh
chmod 700 ~/.ssh

KNOWN_HOSTS=~/.ssh/known_hosts

# Validate required vars

: "${SSH_HOST:?Missing SSH_HOST}"
: "${SSH_PORT:?Missing SSH_PORT}"

# Check if already trusted

if ssh-keygen -F "$SSH_HOST" >/dev/null 2>&1; then
  log "Host $SSH_HOST already trusted"
else
  log "Adding SSH host key for $SSH_HOST:$SSH_PORT"

  ssh-keyscan -p "$SSH_PORT" -H "$SSH_HOST" >>"$KNOWN_HOSTS" 2>/dev/null

  chmod 600 "$KNOWN_HOSTS"

  log "Host key added ✓"
fi
