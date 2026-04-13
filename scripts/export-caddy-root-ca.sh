#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GLOBAL_ENV="$ROOT_DIR/env/homelab.env"
CADDY_ENV="$ROOT_DIR/services/caddy/.env"

[ -f "$GLOBAL_ENV" ] || {
  echo "Missing $GLOBAL_ENV"
  exit 1
}
[ -f "$CADDY_ENV" ] || {
  echo "Missing $CADDY_ENV"
  exit 1
}

set -a
source "$GLOBAL_ENV"
source "$CADDY_ENV"
set +a

: "${HOMELAB_REMOTE_USER:?Missing HOMELAB_REMOTE_USER}"
: "${HOMELAB_REMOTE_HOST:?Missing HOMELAB_REMOTE_HOST}"
: "${HOMELAB_REMOTE_PORT:?Missing HOMELAB_REMOTE_PORT}"
: "${HOMELAB_DATA_ROOT:?Missing HOMELAB_DATA_ROOT}"
: "${SERVICE_DATA_SUBDIR:?Missing SERVICE_DATA_SUBDIR}"

REMOTE_CA_PATH="${HOMELAB_DATA_ROOT}/${SERVICE_DATA_SUBDIR}/data/caddy/pki/authorities/local/root.crt"
LOCAL_OUT="${ROOT_DIR}/artifacts/caddy-root-ca.crt"

mkdir -p "$ROOT_DIR/artifacts"

ssh -p "$HOMELAB_REMOTE_PORT" "${HOMELAB_REMOTE_USER}@${HOMELAB_REMOTE_HOST}" \
  "sudo -S cat '$REMOTE_CA_PATH'" >"$LOCAL_OUT"

test -s "$LOCAL_OUT" || {
  echo "[!] Export failed: $LOCAL_OUT is empty"
  exit 1
}

echo "[✓] Exported CA to $LOCAL_OUT"
echo "[*] Source path: $REMOTE_CA_PATH"
