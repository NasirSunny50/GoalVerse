@echo off
REM Build the GoalVerse release APK, pointed at the backend.
REM   Usage:  scripts\build-apk.bat [API_BASE]
REM   Examples:
REM     scripts\build-apk.bat                          (-> http://localhost:8787, use with: adb reverse tcp:8787 tcp:8787)
REM     scripts\build-apk.bat http://192.168.1.50:8787 (-> backend on another host)
setlocal
set "API_BASE=%~1"
if "%API_BASE%"=="" set "API_BASE=http://localhost:8787"

echo.
echo === Building release APK against %API_BASE% ===
call flutter pub get || goto :err
call flutter build apk --release --dart-define=API_BASE=%API_BASE% || goto :err

echo.
echo Done. APK: build\app\outputs\flutter-apk\app-release.apk
echo Install on a connected phone:
echo     adb install -r build\app\outputs\flutter-apk\app-release.apk
endlocal
exit /b 0

:err
echo.
echo BUILD FAILED.
endlocal
exit /b 1
