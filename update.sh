#!/usr/bin/env bash
# Update an existing install to the latest published images. Never destroys data: it backs up first,
# then pulls the new images and restarts. Database migrations apply automatically on start; the pgdata
# and uploads volumes are preserved.
set -euo pipefail
cd "$(dirname "$0")"

echo "1/3 Backing up (so the update is always safe to roll back)…"
./backup.sh

echo "2/3 Pulling the latest images…"
docker compose pull

echo "3/3 Applying the update…"
docker compose up -d

echo "✅ Updated. Migrations ran automatically on start; your data is intact."
echo "   If something looks wrong, restore the latest ./backups/* snapshot (see README → Backups & restore)."
