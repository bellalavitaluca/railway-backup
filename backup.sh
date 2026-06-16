#!/bin/bash
set -euo pipefail

# Required env vars:
#   DATABASE_URL          - Postgres connection string (reference from Postgres service)
#   BACKUP_BUCKET         - bucket name (e.g. railway-backups)
#   S3_ENDPOINT           - S3-compatible endpoint (e.g. https://<acct>.r2.cloudflarestorage.com)
#   AWS_ACCESS_KEY_ID     - storage access key
#   AWS_SECRET_ACCESS_KEY - storage secret key
#   RETENTION_DAYS        - optional, days to keep (default 14)

TS=$(date +%Y%m%d_%H%M%S)
FILE="pg_backup_${TS}.sql.gz"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

echo "[backup] Starting dump at ${TS}"
pg_dump "${DATABASE_URL}" | gzip > "/tmp/${FILE}"
echo "[backup] Dump complete: ${FILE}"

echo "[backup] Uploading to ${BACKUP_BUCKET}"
aws s3 cp "/tmp/${FILE}" "s3://${BACKUP_BUCKET}/postgres/${FILE}" --endpoint-url "${S3_ENDPOINT}"
echo "[backup] Upload complete"

CUTOFF=$(date -d "-${RETENTION_DAYS} days" +%Y%m%d 2>/dev/null || date -v-${RETENTION_DAYS}d +%Y%m%d)
echo "[backup] Pruning backups older than ${CUTOFF}"
aws s3 ls "s3://${BACKUP_BUCKET}/postgres/" --endpoint-url "${S3_ENDPOINT}" | while read -r line; do
  fname=$(echo "$line" | awk '{print $4}')
  [ -z "$fname" ] && continue
  fdate=$(echo "$fname" | sed -n 's/pg_backup_\([0-9]\{8\}\)_.*/\1/p')
  [ -z "$fdate" ] && continue
  if [ "$fdate" -lt "$CUTOFF" ]; then
    echo "[backup] Deleting old backup: $fname"
    aws s3 rm "s3://${BACKUP_BUCKET}/postgres/${fname}" --endpoint-url "${S3_ENDPOINT}"
  fi
done

rm -f "/tmp/${FILE}"
echo "[backup] Done."
