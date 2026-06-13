#!/usr/bin/env bash
# Start the GoalVerse backend (Docker). Run from anywhere in the repo.
set -e
cd "$(dirname "$0")/.."
echo "=== Starting GoalVerse backend (port 8787) ==="
docker compose up -d --build
echo
echo "Backend is up. Check: curl http://localhost:8787/health"
echo "Logs:  docker compose logs -f"
