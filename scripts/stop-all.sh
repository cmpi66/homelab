#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICES_DIR="$ROOT_DIR/services"
GLOBAL_ENV="$ROOT_DIR/env/homelab.env"

[ -f "$GLOBAL_ENV" ] || {
  echo "Missing $GLOBAL_ENV"
  exit 1
}

set -a
source "$GLOBAL_ENV"
set +a

: "${HOMELAB_CONTEXT:?Missing HOMELAB_CONTEXT}"

echo "[*] Stopping all services..."

for SERVICE_PATH in "$SERVICES_DIR"/*; do
  [ -d "$SERVICE_PATH" ] || continue

  SERVICE_NAME="$(basename "$SERVICE_PATH")"
  COMPOSE_FILE="$SERVICE_PATH/compose.yaml"
  SERVICE_ENV="$SERVICE_PATH/.env"

  if [ ! -f "$COMPOSE_FILE" ]; then
    echo "[*] Skipping $SERVICE_NAME (no compose file)"
    continue
  fi

  echo "[*] Stopping $SERVICE_NAME..."

  docker --context "$HOMELAB_CONTEXT" compose \
    --project-name "$SERVICE_NAME" \
    --env-file "$GLOBAL_ENV" \
    --env-file "$SERVICE_ENV" \
    -f "$COMPOSE_FILE" \
    down || true
done

echo "[✓] All services stopped"
