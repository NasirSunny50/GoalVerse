#!/bin/sh
# Seeds the schedule into the (possibly empty / volume-mounted) data dir on the
# first run, then starts the server. goalverse.db is created/kept by the server.
#
# Persistence has two modes:
#   * LITESTREAM_BUCKET set  -> restore goalverse.db from the S3 replica on boot
#     (recovers data after Render wipes the ephemeral disk), then run the server
#     under `litestream replicate` so every change is streamed back to the bucket.
#   * LITESTREAM_BUCKET unset -> plain server on a real volume (local dev /
#     docker-compose), exactly as before.
set -e
mkdir -p /app/data
if [ ! -f /app/data/fixtures.json ]; then
  cp /app/seed/fixtures.json /app/data/fixtures.json
fi

if [ -n "$LITESTREAM_BUCKET" ]; then
  if [ ! -f /app/data/goalverse.db ]; then
    echo "[entrypoint] Restoring goalverse.db from S3 replica (if any)..."
    litestream restore -if-replica-exists -config /etc/litestream.yml /app/data/goalverse.db || true
  fi
  echo "[entrypoint] Starting server under Litestream replication."
  exec litestream replicate -config /etc/litestream.yml -exec "/app/bin/server"
else
  exec /app/bin/server
fi
