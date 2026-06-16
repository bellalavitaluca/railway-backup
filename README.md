# railway-backup

Scheduled PostgreSQL backups for Railway, written to a mounted Railway volume (no external storage required).

## How it works

A Railway service builds the Dockerfile (postgres:16 + bash) and runs `backup.sh` on a cron schedule. Each run:
1. `pg_dump` the database referenced by `DATABASE_URL`
2. gzip the dump into `BACKUP_DIR` (default `/backups`)
3. prune local backups older than `RETENTION_DAYS` (default 14)

Backups live on the attached volume. This protects against DB corruption, bad migrations, and accidental data loss.

> Note: this is on-platform, not off-site. For disaster-grade safety, add an off-site copy later (e.g. push to S3/GCS).

## Setup on Railway

1. Create a new service in your project -> Deploy from GitHub repo -> select this repo.
2. In the service Settings -> **Volumes** -> add a volume mounted at `/backups`.
3. In Settings -> add a **Cron Schedule**, e.g. `0 3 * * *` (daily 03:00 UTC).
4. Add the environment variable below.
5. Deploy. Check the Deploy logs for `[backup] Done.`

## Environment variables

| Variable | Required | Notes |
|---|---|---|
| `DATABASE_URL` | yes | Reference the Postgres service variable (e.g. `${{Postgres.DATABASE_URL}}`) |
| `BACKUP_DIR` | no | Where to write backups, default `/backups` (match the volume mount path) |
| `RETENTION_DAYS` | no | Days to keep, default 14 |

## Restoring a backup

Backups are at `BACKUP_DIR/pg_backup_YYYYMMDD_HHMMSS.sql.gz` on the volume. To restore:

```
gunzip -c pg_backup_XXXX.sql.gz | psql "$DATABASE_URL"
```

> No secrets are stored in this repo.
