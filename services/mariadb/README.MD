# MariaDB

This service deploys a single MariaDB instance using Docker Compose against the remote Docker context.

## Storage
Remote bind mount base:
- `${HOMELAB_DATA_ROOT}/services/mariadb/data`
- `${HOMELAB_DATA_ROOT}/services/mariadb/init`

## Notes
- Init scripts only run on first boot with an empty data directory.
- Deleting the data directory will re-trigger first-time initialization.
- Uses the shared `homelab_backbone` Docker network.
