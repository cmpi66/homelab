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

[ -f "$GLOBAL_ENV" ] || {
  echo "Missing $GLOBAL_ENV"
  exit 1
}
[ -f "$SERVICE_ENV" ] || {
  echo "Missing $SERVICE_ENV"
  exit 1
}

set -a
source "$GLOBAL_ENV"
source "$SERVICE_ENV"
set +a

: "${HOMELAB_CONTEXT:?Missing HOMELAB_CONTEXT}"
: "${CONTAINER_NAME:?Missing CONTAINER_NAME}"

echo "[*] Container status"
docker --context "$HOMELAB_CONTEXT" ps --filter "name=^/${CONTAINER_NAME}$"

echo
echo "[*] Health status"
docker --context "$HOMELAB_CONTEXT" inspect \
  --format '{{.State.Status}} / health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
  "$CONTAINER_NAME"

echo
echo "[*] Recent logs"
docker --context "$HOMELAB_CONTEXT" logs --tail 50 "$CONTAINER_NAME"
