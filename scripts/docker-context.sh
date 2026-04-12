#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="../env/homelab.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[!] Missing env file: $ENV_FILE"
  exit 1
fi

# Load environment

set -a
source "$ENV_FILE"
set +a

log() { echo "[*] $*"; }
warn() { echo "[!] $*" >&2; }

# Required variables

: "${SSH_HOST:?Missing SSH_HOST}"
: "${SSH_USER:?Missing SSH_USER}"
: "${SSH_PORT:?Missing SSH_PORT}"

# Optional override (default to "homelab")

CONTEXT_NAME="${DOCKER_CONTEXT:-homelab}"

# Construct expected Docker endpoint (DO NOT export as DOCKER_HOST)

EXPECTED_HOST="ssh://${SSH_USER}@${SSH_HOST}"

# Ensure DOCKER_HOST is not interfering

if [[ -n "${DOCKER_HOST:-}" ]]; then
  warn "DOCKER_HOST is set and will override Docker contexts"
  warn "Unsetting DOCKER_HOST for this session"
  unset DOCKER_HOST
fi

# Check if context exists

if docker context inspect "$CONTEXT_NAME" >/dev/null 2>&1; then
  log "Context '$CONTEXT_NAME' already exists"

  CURRENT_HOST="$(docker context inspect "$CONTEXT_NAME" --format '{{ (index .Endpoints "docker").Host }}')"

  if [[ "$CURRENT_HOST" != "$EXPECTED_HOST" ]]; then
    warn "Context exists but host mismatch:"
    warn "Expected: $EXPECTED_HOST"
    warn "Found:    $CURRENT_HOST"
    warn "Fix manually:"
    warn "docker context rm $CONTEXT_NAME"
    exit 1
  fi
else
  log "Creating context '$CONTEXT_NAME' → $EXPECTED_HOST"
  docker context create "$CONTEXT_NAME" --docker "host=$EXPECTED_HOST"
fi

# Ensure correct context is active

CURRENT_CONTEXT="$(docker context show)"

if [[ "$CURRENT_CONTEXT" != "$CONTEXT_NAME" ]]; then
  log "Switching to context '$CONTEXT_NAME'"
  docker context use "$CONTEXT_NAME"
else
  log "Context '$CONTEXT_NAME' already active"
fi

log "Context ready ✓"
