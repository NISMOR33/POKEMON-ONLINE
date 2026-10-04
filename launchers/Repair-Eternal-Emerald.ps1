[CmdletBinding()]
param([switch]$Repair)

$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent
$runtime = Join-Path $root '.runtime'
$server = Join-Path $root 'server'
New-Item -ItemType Directory -Path $runtime -Force | Out-Null
$checks = [System.Collections.Generic.List[object]]::new()

function Add-Check([string]$Name, [bool]$Ok, [string]$Detail, [bool]$Required = $true) {
    $checks.Add([pscustomobject]@{ name = $Name; ok = $Ok; required = $Required; detail = $Detail })
}

$core = @('Game.exe', 'Game.rxdata', 'mkxp.json', 'Plugins', 'Graphics', 'server')
foreach ($item in $core) {
    $path = Join-Path $root $item
    Add-Check "Fichier $item" (Test-Path -LiteralPath $path) ($(if (Test-Path -LiteralPath $path) { 'présent' } else { 'introuvable' }))
}

$ruby = Get-Command ruby.exe -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $ruby) { $ruby = Get-ChildItem 'C:\Ruby*\bin\ruby.exe' -ErrorAction SilentlyContinue | Select-Object -First 1 }
$rubyPath = if ($ruby) { if ($ruby.Source) { $ruby.Source } else { $ruby.FullName } } else { $null }
Add-Check 'Ruby' ($null -ne $ruby) ($(if ($ruby) { $rubyPath } else { 'Ruby 3.1 ou plus récent est requis pour le serveur local.' }))

$bundle = Get-Command bundle.bat, bundle -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $bundle -and $ruby) {
    $candidate = Join-Path (Split-Path $rubyPath -Parent) 'bundle.bat'
    if (Test-Path -LiteralPath $candidate) { $bundle = Get-Item -LiteralPath $candidate }
}
$bundlePath = if ($bundle) { if ($bundle.Source) { $bundle.Source } else { $bundle.FullName } } else { $null }
Add-Check 'Bundler' ($null -ne $bundle) ($(if ($bundle) { $bundlePath } else { 'Bundler est introuvable.' }))

$postgres = Get-Command postgres.exe -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $postgres) { $postgres = Get-ChildItem 'C:\Program Files\PostgreSQL\*\bin\postgres.exe', 'C:\PostgreSQL\*\bin\postgres.exe' -ErrorAction SilentlyContinue | Select-Object -First 1 }
$postgresPath = if ($postgres) { if ($postgres.Source) { $postgres.Source } else { $postgres.FullName } } else { $null }
Add-Check 'PostgreSQL' ($null -ne $postgres) ($(if ($postgres) { $postgresPath } else { 'PostgreSQL est introuvable.' }))

if ($bundle -and (Test-Path -LiteralPath (Join-Path $server 'Gemfile'))) {
    Push-Location $server
    try {
        & $bundlePath check *> (Join-Path $runtime 'bundle-check.log')
        $bundleOk = ($LASTEXITCODE -eq 0)
        if (-not $bundleOk -and $Repair) {
            & $bundlePath install *> (Join-Path $runtime 'bundle-install.log')
            $bundleOk = ($LASTEXITCODE -eq 0)
        }
        Add-Check 'Composants serveur' $bundleOk ($(if ($bundleOk) { 'toutes les bibliothèques sont installées' } else { 'bibliothèques manquantes ; consultez bundle-check.log' }))
    } finally { Pop-Location }
}

$serverOnline = [bool](Get-NetTCPConnection -LocalPort 9998 -State Listen -ErrorAction SilentlyContinue)
Add-Check 'Serveur de jeu' $serverOnline ($(if ($serverOnline) { 'en ligne sur le port 9998' } else { 'arrêté ; il démarrera avec le jeu' })) $false
$dbOnline = [bool](Get-NetTCPConnection -LocalPort 55433 -State Listen -ErrorAction SilentlyContinue)
Add-Check 'Base locale' $dbOnline ($(if ($dbOnline) { 'en ligne sur le port 55433' } else { 'arrêtée ; elle démarrera avec le jeu' })) $false

$drive = Get-PSDrive -Name ([IO.Path]::GetPathRoot($root).TrimEnd(':\')) -ErrorAction SilentlyContinue
$freeGb = if ($drive) { [math]::Round($drive.Free / 1GB, 1) } else { 0 }
Add-Check 'Espace disque' ($freeGb -ge 2) "$freeGb Go disponibles"

$requiredOk = -not ($checks | Where-Object { $_.required -and -not $_.ok })
$report = [pscustomobject]@{
    product = 'Pokémon Eternal Emerald Online'
    checked_at = (Get-Date).ToString('o')
    healthy = $requiredOk
    checks = $checks
}
$report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $runtime 'health.json') -Encoding utf8
$checks | ForEach-Object { ('[{0}] {1} — {2}' -f $(if ($_.ok) { 'OK' } else { 'ERREUR' }), $_.name, $_.detail) } | Set-Content -LiteralPath (Join-Path $runtime 'diagnostic.txt') -Encoding utf8
$checks | Format-Table -AutoSize
if ($requiredOk) { Write-Host 'Installation prête.' -ForegroundColor Green; exit 0 }
Write-Host "L'installation nécessite une réparation." -ForegroundColor Yellow
exit 2

