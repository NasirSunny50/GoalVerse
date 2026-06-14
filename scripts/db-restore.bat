@echo off
REM Restore the GoalVerse database from a backup file. OVERWRITES live data.
REM   Usage:  scripts\db-restore.bat backups\goalverse-YYYYMMDD-HHMMSS.db
setlocal
cd /d "%~dp0\.."
set "C=goalverse-backend"
set "FILE=%~1"
if "%FILE%"=="" echo Usage: scripts\db-restore.bat ^<backup-file^> & endlocal & exit /b 1
if not exist "%FILE%" echo Not found: %FILE% & endlocal & exit /b 1
echo WARNING: restoring %FILE% overwrites the current database.
docker stop %C% || goto :err
docker cp "%FILE%" %C%:/app/data/goalverse.db || goto :err
docker start %C% || goto :err
echo OK  restored from %FILE% -- backend restarted.
endlocal & exit /b 0
:err
echo RESTORE FAILED.
endlocal & exit /b 1
