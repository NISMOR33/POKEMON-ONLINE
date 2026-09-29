@echo off
cd /d "%~dp0"
echo Verification de la base de donnees PostgreSQL...
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "if (-not (Get-NetTCPConnection -LocalPort 55433 -State Listen -ErrorAction SilentlyContinue)) { Start-Process -FilePath 'C:\Program Files\PostgreSQL\16\bin\postgres.exe' -ArgumentList '-D', 'C:\Users\admin\Documents\Pokemon-MMO-Modern\.runtime\pgdata' -WindowStyle Hidden; Start-Sleep -Seconds 2 }"

echo Reset et redemarrage du serveur MMO...
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-Process | Where-Object { $_.Name -match 'ruby' } | Stop-Process -Force -ErrorAction SilentlyContinue; Start-Sleep -Milliseconds 500; $env:DATABASE_URL = 'postgres://postgres:pemk_dev@127.0.0.1:55433/pemk_eternal_emerald'; $env:PEMK_BIND = '127.0.0.1'; $env:PEMK_PORT = '9998'; $env:Path = 'C:\Ruby31-x64\bin;' + $env:Path; Set-Location -LiteralPath '%~dp0server'; & 'C:\Ruby31-x64\bin\bundle.bat' exec rake db:migrate; Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList '-NoProfile', '-Command', 'Set-Location -LiteralPath ''%~dp0server''; $env:DATABASE_URL=''postgres://postgres:pemk_dev@127.0.0.1:55433/pemk_eternal_emerald''; $env:PEMK_BIND=''127.0.0.1''; $env:PEMK_PORT=''9998''; & ''C:\Ruby31-x64\bin\bundle.bat'' exec ruby bin/pemk_server.rb'"
echo Serveur et Base de donnees relances avec succes !
timeout /t 2 >nul

