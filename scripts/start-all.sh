#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICES_DIR="$ROOT_DIR/services"
GLOBAL_ENV="$ROOT_DIR/env/homelab.env"

set -a
source "$GLOBAL_ENV"
set +a

: "${HOMELAB_CONTEXT:?Missing HOMELAB_CONTEXT}"
: "${HOMELAB_BACKBONE_NETWORK:?Missing HOMELAB_BACKBONE_NETWORK}"

echo "[*] Ensuring shared Docker network exists..."

docker --context "$HOMELAB_CONTEXT" network inspect "$HOMELAB_BACKBONE_NETWORK" >/dev/null 2>&1 ||
  docker --context "$HOMELAB_CONTEXT" network create "$HOMELAB_BACKBONE_NETWORK"

echo "[*] Starting all services..."

echo "[*] Starting all services..."

for SERVICE_PATH in "$SERVICES_DIR"/*; do
  [ -d "$SERVICE_PATH" ] || continue

  SERVICE_NAME="$(basename "$SERVICE_PATH")"
  COMPOSE_FILE="$SERVICE_PATH/compose.yaml"
  SERVICE_ENV="$SERVICE_PATH/.env"

  if [ ! -f "$COMPOSE_FILE" ]; then
    continue
  fi

  echo "[*] Starting $SERVICE_NAME..."

  docker --context "$HOMELAB_CONTEXT" compose \
    --env-file "$GLOBAL_ENV" \
    --env-file "$SERVICE_ENV" \
    -f "$COMPOSE_FILE" \
    up -d
done

echo "[✓] All services started"
