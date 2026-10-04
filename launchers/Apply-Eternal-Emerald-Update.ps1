[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Plan,
    [Parameter(Mandatory = $true)][int]$LauncherPid
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$log = Join-Path $root '.runtime\update.log'
New-Item -ItemType Directory -Path (Split-Path $log -Parent) -Force | Out-Null

try {
    "[$(Get-Date -Format o)] Attente de la fermeture du launcher PID $LauncherPid" | Add-Content -LiteralPath $log -Encoding utf8
    try { Wait-Process -Id $LauncherPid -Timeout 30 -ErrorAction Stop } catch { Start-Sleep -Seconds 1 }
    $entries = @(Get-Content -LiteralPath $Plan -Raw | ConvertFrom-Json)
    $backup = Join-Path $root ('.runtime\update-backup\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    $launcher = $null
    foreach ($entry in $entries) {
        $stage = [IO.Path]::GetFullPath([string]$entry.stage)
        $target = [IO.Path]::GetFullPath([string]$entry.target)
        $rootPrefix = [IO.Path]::GetFullPath($root).TrimEnd('\') + '\'
        if (-not $target.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw "Destination interdite : $target" }
        if (-not (Test-Path -LiteralPath $stage)) { throw "Téléchargement introuvable : $stage" }
        $hash = (Get-FileHash -LiteralPath $stage -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($hash -ne ([string]$entry.sha256).ToLowerInvariant()) { throw "Empreinte incorrecte : $target" }
        if (Test-Path -LiteralPath $target) {
            $relative = $target.Substring($rootPrefix.Length)
            $saved = Join-Path $backup $relative
            New-Item -ItemType Directory -Path (Split-Path $saved -Parent) -Force | Out-Null
            Copy-Item -LiteralPath $target -Destination $saved -Force
        }
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
        $swap = "$target.updating"
        Copy-Item -LiteralPath $stage -Destination $swap -Force
        Move-Item -LiteralPath $swap -Destination $target -Force
        if ([IO.Path]::GetFileName($target) -eq 'Eternal Emerald Launcher.exe') { $launcher = $target }
        "[$(Get-Date -Format o)] Installé : $target" | Add-Content -LiteralPath $log -Encoding utf8
    }
    if (-not $launcher) { $launcher = Join-Path $root 'Eternal Emerald Launcher.exe' }
    Start-Process -FilePath $launcher -WorkingDirectory $root
} catch {
    "[$(Get-Date -Format o)] ERREUR : $($_.Exception)" | Add-Content -LiteralPath $log -Encoding utf8
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show("La mise à jour a échoué.`n`n$($_.Exception.Message)`n`nConsultez .runtime\update.log.", 'Eternal Emerald') | Out-Null
    exit 1
}

