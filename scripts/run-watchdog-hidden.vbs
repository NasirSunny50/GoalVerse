' Launches the ngrok watchdog PowerShell script FULLY hidden (window style 0),
' so the every-2-minutes Scheduled Task never flashes a console window.
' powershell.exe -WindowStyle Hidden still flashes briefly when started by Task
' Scheduler; running it through WScript.Shell.Run with intWindowStyle=0 does not.
Set sh = CreateObject("WScript.Shell")
sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""D:\Projects\Personal\GoalVerse\GoalVerse\scripts\ngrok-watchdog.ps1""", 0, False
