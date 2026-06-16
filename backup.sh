#!/bin/bash
set -euo pipefail

# Volume-only Postgres backup.
# Required env vars:
#   DATABASE_URL    - Postgres connection string (reference from Postgres service)
# Optional:
#   BACKUP_DIR      - where to write backups (default /backups, mount a volume here)
#   RETENTION_DAYS  - days to keep (default 14)

BACKUP_DIR="${BACKUP_DIR:-/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
TS=$(date +%Y%m%d_%H%M%S)
FILE="${BACKUP_DIR}/pg_backup_${TS}.sql.gz"

mkdir -p "${BACKUP_DIR}"

echo "[backup] Starting dump at ${TS}"
pg_dump "${DATABASE_URL}" | gzip > "${FILE}"
echo "[backup] Dump complete: ${FILE} ($(du -h "${FILE}" | cut -f1))"

echo "[backup] Pruning backups older than ${RETENTION_DAYS} days in ${BACKUP_DIR}"
find "${BACKUP_DIR}" -name 'pg_backup_*.sql.gz' -type f -mtime +${RETENTION_DAYS} -print -delete

echo "[backup] Current backups:"
ls -lh "${BACKUP_DIR}"/pg_backup_*.sql.gz 2>/dev/null || echo "  (none)"
echo "[backup] Done."
