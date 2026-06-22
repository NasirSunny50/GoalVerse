# Elevated one-time power fix so a locked, plugged-in laptop stays fully ONLINE
# (Docker + ngrok + AnyDesk reachable). Root cause was Modern Standby (S0
# "connected standby"): on lock/idle it suspends processes and drops Wi-Fi, so
# standby-timeout-ac=0 alone wasn't enough. Run elevated, then REBOOT.

# 1) Disable Modern Standby -> reverts to classic S3 (takes effect after reboot).
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" `
  -Name PlatformAoAcOverride -PropertyType DWord -Value 0 -Force | Out-Null

# 2) Stop Windows from powering off the Wi-Fi NIC to save power.
try {
  $pm = Get-NetAdapterPowerManagement -Name "Wi-Fi" -ErrorAction Stop
  if ($pm.AllowComputerToTurnOffDevice -ne "Unsupported") {
    $pm.AllowComputerToTurnOffDevice = "Disabled"
    $pm | Set-NetAdapterPowerManagement
  }
} catch {}

# 3) Reassert: never sleep on AC; deeper hibernate off on AC. Screen may still
#    turn off (harmless). Keep the machine PLUGGED IN.
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0

"OK" | Out-File "$env:TEMP\gv-power-fix.txt"
