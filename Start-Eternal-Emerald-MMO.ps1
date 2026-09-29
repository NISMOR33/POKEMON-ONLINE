[CmdletBinding()]
param([switch]$Guest)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$serverDir = Join-Path $root 'server'
$runtime = Join-Path $root '.runtime'
$stateFile = Join-Path $runtime 'server.json'
$bundle = 'C:\Ruby31-x64\bin\bundle.bat'
$databaseUrl = 'postgres://postgres:pemk_dev@127.0.0.1:55433/pemk_eternal_emerald'
$env:Path = 'C:\Ruby31-x64\bin;' + $env:Path

New-Item -ItemType Directory -Force -Path $runtime | Out-Null

if (-not (Get-NetTCPConnection -LocalPort 55433 -State Listen -ErrorAction SilentlyContinue)) {
    $pgData = 'C:\Users\admin\Documents\Pokemon-MMO-Modern\.runtime\pgdata'
    if (Test-Path $pgData) {
        Start-Process -FilePath 'C:\Program Files\PostgreSQL\16\bin\postgres.exe' -ArgumentList '-D', "`"$pgData`"" -WindowStyle Hidden
        Start-Sleep -Seconds 2
    }
}

$listener = Get-NetTCPConnection -LocalPort 9998 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
if ($listener) {
    $process = Get-CimInstance Win32_Process -Filter "ProcessId=$($listener.OwningProcess)"
    if ($process.Name -ne 'ruby.exe') {
        throw "Le port 9998 est occupé par $($process.Name), arrêt automatique refusé."
    }
    # bundle.bat creates ruby -> ruby -> cmd -> PowerShell. Stop the whole tree.
    $treeRoot = $process
    $cursor = $process
    for ($depth = 0; $depth -lt 5; $depth++) {
        $parent = Get-CimInstance Win32_Process -Filter "ProcessId=$($cursor.ParentProcessId)" -ErrorAction SilentlyContinue
        if (-not $parent) { break }
        $isServerProcess = $parent.Name -in @('ruby.exe', 'cmd.exe') -or
            ($parent.Name -eq 'powershell.exe' -and $parent.CommandLine -match 'pemk_server\.rb')
        if (-not $isServerProcess) { break }
        $treeRoot = $parent
        $cursor = $parent
    }
    & taskkill.exe /PID $treeRoot.ProcessId /T /F | Out-Null
    for ($i = 0; $i -lt 20; $i++) {
        if (-not (Get-NetTCPConnection -LocalPort 9998 -State Listen -ErrorAction SilentlyContinue)) { break }
        Start-Sleep -Milliseconds 250
    }
    if (Get-NetTCPConnection -LocalPort 9998 -State Listen -ErrorAction SilentlyContinue) {
        throw 'Impossible de liberer le port 9998 utilise par un ancien serveur.'
    }
}

$env:DATABASE_URL = $databaseUrl
Push-Location $serverDir
try {
    & $bundle exec rake db:migrate
    if ($LASTEXITCODE -ne 0) { throw 'La migration de la base a échoué.' }
} finally { Pop-Location }

$serverLog = Join-Path $runtime 'server.log'
Remove-Item -LiteralPath $serverLog -Force -ErrorAction SilentlyContinue
$server = Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -PassThru -ArgumentList @(
    '-NoProfile', '-Command',
    "Set-Location -LiteralPath '$($serverDir.Replace("'", "''"))'; `$env:DATABASE_URL='$databaseUrl'; `$env:PEMK_BIND='127.0.0.1'; `$env:PEMK_PORT='9998'; & '$bundle' exec ruby bin/pemk_server.rb *> '$($serverLog.Replace("'", "''"))'"
)
@{ server = $server.Id } | ConvertTo-Json | Set-Content -LiteralPath $stateFile -Encoding utf8

$ready = $false
for ($i = 0; $i -lt 30; $i++) {
    if ($server.HasExited) { break }
    $newListener = Get-NetTCPConnection -LocalPort 9998 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($newListener) { $ready = $true; break }
    Start-Sleep -Milliseconds 500
}
if (-not $ready) { throw "Le serveur Hoenn n'a pas démarré. Consultez $serverLog" }

$env:RUBY_THREAD_VM_STACK_SIZE = '16777216'
if ($Guest) { $env:PEMK_INSTANCE = 'guest' } else { Remove-Item Env:PEMK_INSTANCE -ErrorAction SilentlyContinue }
Start-Process -FilePath (Join-Path $root 'Game.exe') -ArgumentList 'debug' -WorkingDirectory $root
Write-Host 'Pokemon MMO Hoenn est lancé.' -ForegroundColor Green
Write-Host 'Serveur : 127.0.0.1:9998'
Write-Host "Projet : $root"
