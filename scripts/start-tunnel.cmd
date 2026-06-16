@echo off
REM Starts the ngrok tunnel for the GoalVerse backend on the permanent
REM static domain. Launched at logon by the hidden VBS in the Startup folder
REM (see scripts/install-autostart.ps1). Docker (restart: unless-stopped)
REM brings the backend itself back up.
"C:\Users\nasir.uddin\AppData\Local\Microsoft\WinGet\Links\ngrok.exe" http 8787 --url=https://shadow-hummus-dismantle.ngrok-free.dev --log=stdout > "D:\Projects\Personal\GoalVerse\GoalVerse\ngrok.log" 2>&1
