#!/usr/bin/env bash
# Build the GoalVerse release APK, pointed at the backend.
#   Usage:  scripts/build-apk.sh [API_BASE]
#   Examples:
#     scripts/build-apk.sh                          # -> http://localhost:8787 (use: adb reverse tcp:8787 tcp:8787)
#     scripts/build-apk.sh http://192.168.1.50:8787 # -> backend on another host
set -e
cd "$(dirname "$0")/.."
API_BASE="${1:-http://localhost:8787}"

echo
echo "=== Building release APK against $API_BASE ==="
flutter pub get
flutter build apk --release --dart-define=API_BASE="$API_BASE"

echo
echo "Done. APK: build/app/outputs/flutter-apk/app-release.apk"
echo "Install on a connected phone:"
echo "    adb install -r build/app/outputs/flutter-apk/app-release.apk"
