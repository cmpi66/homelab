#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GLOBAL_ENV="$ROOT_DIR/env/homelab.env"

usage() {
  echo "Usage: $0 <service-name>"
  exit 1
}

[ $# -eq 1 ] || usage

SERVICE="$1"
SERVICE_DIR="$ROOT_DIR/services/$SERVICE"
SERVICE_ENV="$SERVICE_DIR/.env"
COMPOSE_FILE="$SERVICE_DIR/compose.yaml"

[ -f "$GLOBAL_ENV" ] || {
  echo "Missing $GLOBAL_ENV"
  exit 1
}
[ -d "$SERVICE_DIR" ] || {
  echo "Missing service dir: $SERVICE_DIR"
  exit 1
}
[ -f "$SERVICE_ENV" ] || {
  echo "Missing service env: $SERVICE_ENV"
  exit 1
}
[ -f "$COMPOSE_FILE" ] || {
  echo "Missing compose file: $COMPOSE_FILE"
  exit 1
}

set -a
source "$GLOBAL_ENV"
source "$SERVICE_ENV"
set +a

: "${HOMELAB_CONTEXT:?Missing HOMELAB_CONTEXT}"
: "${HOMELAB_REMOTE_USER:?Missing HOMELAB_REMOTE_USER}"
: "${HOMELAB_REMOTE_HOST:?Missing HOMELAB_REMOTE_HOST}"
: "${HOMELAB_REMOTE_PORT:?Missing HOMELAB_REMOTE_PORT}"
: "${HOMELAB_DATA_ROOT:?Missing HOMELAB_DATA_ROOT}"
: "${HOMELAB_BACKBONE_NETWORK:?Missing HOMELAB_BACKBONE_NETWORK}"
: "${SERVICE_DATA_SUBDIR:?Missing SERVICE_DATA_SUBDIR}"

REMOTE_SERVICE_ROOT="${HOMELAB_DATA_ROOT}/${SERVICE_DATA_SUBDIR}"

echo "[*] Ensuring remote directories exist..."
ssh -p "$HOMELAB_REMOTE_PORT" "${HOMELAB_REMOTE_USER}@${HOMELAB_REMOTE_HOST}" \
  "mkdir -p '$REMOTE_SERVICE_ROOT/data' '$REMOTE_SERVICE_ROOT/init'"

if [ -d "$SERVICE_DIR/init" ]; then
  echo "[*] Syncing init assets..."

  rsync -az --delete -e "ssh -p $HOMELAB_REMOTE_PORT" \
    "$SERVICE_DIR/init/" \
    "${HOMELAB_REMOTE_USER}@${HOMELAB_REMOTE_HOST}:$REMOTE_SERVICE_ROOT/init/"
else
  echo "[*] No init directory, skipping"
fi
echo "[*] Ensuring shared Docker network exists..."
docker --context "$HOMELAB_CONTEXT" network inspect "$HOMELAB_BACKBONE_NETWORK" >/dev/null 2>&1 ||
  docker --context "$HOMELAB_CONTEXT" network create "$HOMELAB_BACKBONE_NETWORK"

echo "[*] Deploying $SERVICE..."
(
  cd "$SERVICE_DIR"
  docker --context "$HOMELAB_CONTEXT" compose \
    --env-file "$GLOBAL_ENV" \
    --env-file ".env" \
    -f "$COMPOSE_FILE" \
    up -d
)

echo "[✓] Deployment complete"
