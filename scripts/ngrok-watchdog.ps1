# GoalVerse ngrok watchdog — keeps the permanent tunnel alive.
# Runs in the logged-in USER context (where ngrok.yml/authtoken resolve), so it
# succeeds where a LocalSystem Windows service cannot. Registered as a Scheduled
# Task that fires at logon and repeats every couple of minutes; if the ngrok
# agent process has died, it relaunches it on the static domain. Docker
# (restart: unless-stopped) keeps the backend itself up.
$ng  = "C:\Users\nasir.uddin\AppData\Local\Microsoft\WinGet\Links\ngrok.exe"
# Config lives in the project dir (not %LOCALAPPDATA%): a Limited-token
# Scheduled Task can read D:\ but not always the user profile's AppData.
$cfg = "D:\Projects\Personal\GoalVerse\GoalVerse\ngrok-tunnel.yml"
$log = "D:\Projects\Personal\GoalVerse\GoalVerse\ngrok.log"

if (-not (Get-Process ngrok -ErrorAction SilentlyContinue)) {
  Start-Process -FilePath $ng `
    -ArgumentList 'start','--all','--config',$cfg `
    -RedirectStandardOutput $log -RedirectStandardError "$log.err" `
    -WindowStyle Hidden
}
