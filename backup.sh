#!/usr/bin/env bash
# Snapshot everything that holds state: the database and the uploads volume (attachments + encryption
# keys). Writes two timestamped files to ./backups. Safe to run any time, including while live.
set -euo pipefail
cd "$(dirname "$0")"
[ -f .env ] && { set -a; . ./.env; set +a; }

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="${BACKUP_DIR:-./backups}"; mkdir -p "$OUT"
DB_NAME="${DB_NAME:-throughly}"; DB_USER="${DB_USER:-throughly}"

echo "Dumping database '$DB_NAME'…"
docker compose exec -T postgres pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$OUT/db-$STAMP.sql.gz"

echo "Archiving uploads (attachments + keys)…"
docker run --rm -v throughly-onprem_uploads:/v -v "$PWD/$OUT":/out alpine \
  tar czf "/out/uploads-$STAMP.tgz" -C /v .

echo "✅ Backup written: $OUT/db-$STAMP.sql.gz  +  $OUT/uploads-$STAMP.tgz"
