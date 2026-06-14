#!/usr/bin/env bash
# Safe ONLINE backup of the GoalVerse database (accounts + predictions +
# results) while the backend is running. Writes ./backups/goalverse-<ts>.db.
#   Usage:  scripts/db-backup.sh
set -e
cd "$(dirname "$0")/.."
C=goalverse-backend
TS=$(date +%Y%m%d-%H%M%S)
mkdir -p backups
# .backup is a consistent snapshot even mid-write (SQLite online backup API).
docker exec "$C" sqlite3 /app/data/goalverse.db ".backup '/app/data/_snapshot.db'"
docker cp "$C:/app/data/_snapshot.db" "backups/goalverse-$TS.db"
docker exec "$C" rm -f /app/data/_snapshot.db
echo "OK  backups/goalverse-$TS.db"
echo "    Copy it OFF this machine (cloud / another disk) for real safety."
