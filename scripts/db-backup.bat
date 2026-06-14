@echo off
REM Safe ONLINE backup of the GoalVerse database (run while the backend is up).
REM Writes backups\goalverse-<timestamp>.db
setlocal
cd /d "%~dp0\.."
set "C=goalverse-backend"
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "TS=%%i"
if not exist backups mkdir backups
docker exec %C% sqlite3 /app/data/goalverse.db ".backup '/app/data/_snapshot.db'" || goto :err
docker cp %C%:/app/data/_snapshot.db "backups\goalverse-%TS%.db" || goto :err
docker exec %C% rm -f /app/data/_snapshot.db
echo OK  backups\goalverse-%TS%.db
echo     Copy it OFF this machine (cloud / another disk) for real safety.
endlocal & exit /b 0
:err
echo BACKUP FAILED. Is the backend running?  ( docker compose up -d )
endlocal & exit /b 1
