@echo off
REM Starts the GoalVerse backend on http://localhost:8787
cd /d "%~dp0"
echo Starting GoalVerse backend...
call dart pub get
call dart run bin/server.dart
pause
