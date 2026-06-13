#!/bin/sh
# Seeds the schedule into the (possibly empty / volume-mounted) data dir on the
# first run, then starts the server. goalverse.db is created/kept by the server.
set -e
mkdir -p /app/data
if [ ! -f /app/data/fixtures.json ]; then
  cp /app/seed/fixtures.json /app/data/fixtures.json
fi
exec /app/bin/server
