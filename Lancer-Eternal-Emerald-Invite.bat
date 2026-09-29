@echo off
cd /d "%~dp0"
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Eternal-Emerald-MMO.ps1" -Guest
if errorlevel 1 pause
