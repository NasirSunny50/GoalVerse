#!/usr/bin/env bash
# Restore the GoalVerse database from a backup file. OVERWRITES live data.
#   Usage:  scripts/db-restore.sh backups/goalverse-YYYYMMDD-HHMMSS.db
set -e
cd "$(dirname "$0")/.."
C=goalverse-backend
FILE="$1"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "Usage: $0 <backup-file>"; exit 1
fi
echo "WARNING: restoring '$FILE' overwrites the current database."
docker stop "$C"
docker cp "$FILE" "$C:/app/data/goalverse.db"
docker start "$C"
echo "OK  restored from $FILE — backend restarted."
