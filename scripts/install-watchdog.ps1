# One-time elevated setup: removes the (non-working) LocalSystem ngrok service
# and registers the user-context watchdog Scheduled Task that keeps the tunnel
# alive. Run elevated.
$ng = "C:\Users\nasir.uddin\AppData\Local\Microsoft\WinGet\Links\ngrok.exe"

# 1) Remove the broken Windows service (LocalSystem can't read the user config).
try { & $ng service stop } catch {}
try { & $ng service uninstall } catch {}
cmd /c "sc delete ngrok" 2>$null

# 2) Register the watchdog task: at logon + every 2 minutes, as the user.
$wd = "D:\Projects\Personal\GoalVerse\GoalVerse\scripts\ngrok-watchdog.ps1"
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
  -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$wd`""
$tLogon = New-ScheduledTaskTrigger -AtLogOn
$tRepeat = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) `
  -RepetitionInterval (New-TimeSpan -Minutes 2) -RepetitionDuration (New-TimeSpan -Days 3650)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
  -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" `
  -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName "GoalVerse-ngrok-watchdog" -Action $action `
  -Trigger $tLogon,$tRepeat -Settings $settings -Principal $principal `
  -Description "Keeps the GoalVerse ngrok tunnel alive (auto-restart)" -Force | Out-Null

"OK" | Out-File "$env:TEMP\gv-watchdog-setup.txt"
