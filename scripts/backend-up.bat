@echo off
REM Start the GoalVerse backend (Docker). Run from anywhere in the repo.
setlocal
cd /d "%~dp0\.."
echo === Starting GoalVerse backend (port 8787) ===
docker compose up -d --build || goto :err
echo.
echo Backend is up. Check: curl http://localhost:8787/health
echo Logs:  docker compose logs -f
endlocal
exit /b 0
:err
echo BACKEND FAILED TO START.
endlocal
exit /b 1
