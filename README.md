# railway-backup

Scheduled PostgreSQL backups for Railway, uploading gzipped dumps to any S3-compatible bucket (e.g. Cloudflare R2).

## How it works

A Railway service builds the Dockerfile (postgres:16 + aws-cli) and runs `backup.sh` on a cron schedule. Each run:
1. `pg_dump` the database referenced by `DATABASE_URL`
2. gzip the dump
3. upload to `s3://$BACKUP_BUCKET/postgres/`
4. prune backups older than `RETENTION_DAYS` (default 14)

## Setup on Railway

1. Create a new service in your project -> Deploy from GitHub repo -> select this repo.
2. In the service Settings -> add a **Cron Schedule**, e.g. `0 3 * * *` (daily 03:00 UTC).
3. Add the environment variables below.
4. Deploy. Check the Deploy logs for `[backup] Done.`

## Environment variables

| Variable | Required | Notes |
|---|---|---|
| `DATABASE_URL` | yes | Reference the Postgres service variable (e.g. `${{Postgres.DATABASE_URL}}`) |
| `BACKUP_BUCKET` | yes | Bucket name |
| `S3_ENDPOINT` | yes | S3-compatible endpoint URL |
| `AWS_ACCESS_KEY_ID` | yes | Storage access key (set by you) |
| `AWS_SECRET_ACCESS_KEY` | yes | Storage secret key (set by you) |
| `RETENTION_DAYS` | no | Days to keep, default 14 |

## Cloudflare R2 notes

- `S3_ENDPOINT` looks like `https://<account_id>.r2.cloudflarestorage.com`
- Create an R2 API token (Object Read & Write) to get the access key id / secret.
- R2 has no egress fees and a free tier suitable for small dumps.

## Restoring a backup

Download the desired `pg_backup_YYYYMMDD_HHMMSS.sql.gz` and run:

```
gunzip -c pg_backup_XXXX.sql.gz | psql "$DATABASE_URL"
```

> Secrets are never stored in this repo. Set them only as Railway service variables.
