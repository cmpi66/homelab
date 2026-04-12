#!/usr/bin/env bash
set -euo pipefail

./ssh-trust.sh
./docker-context.sh

echo "[*] Homelab bootstrap complete ✓"
