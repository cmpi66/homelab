#!/usr/bin/env bash
set -euo pipefail

REPO="/mnt/backups/restic"
PASS="/home/chris/backup/restic-pass"
DATA="/home/chris/homelab_data"
EXCLUDES="/home/chris/backup/excludes.txt"
LOG="/home/chris/backup/backup.log"

log() {
  echo "$(date '+%F %T') $*" >>"$LOG"
}

log "=== Backup start ==="

# backup
sudo restic \
  --repo "$REPO" \
  --password-file "$PASS" \
  backup "$DATA" \
  --exclude-file "$EXCLUDES"

# retention
sudo restic \
  --repo "$REPO" \
  --password-file "$PASS" \
  forget \
  --keep-last 10 \
  --keep-daily 7 \
  --keep-weekly 5 \
  --keep-monthly 12 \
  --prune

# light integrity check
sudo restic \
  --repo "$REPO" \
  --password-file "$PASS" \
  check --read-data-subset=10%

log "=== Backup complete ==="
