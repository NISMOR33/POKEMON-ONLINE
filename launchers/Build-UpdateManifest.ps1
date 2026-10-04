[CmdletBinding()]
param(
    [string]$Version = '3.1.0',
    [string[]]$Files = @('Eternal Emerald Launcher.exe'),
    [switch]$Optional
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$base = 'https://raw.githubusercontent.com/NISMOR33/POKEMON-ONLINE/main/'
$items = foreach ($relative in $Files) {
    $path = Join-Path $root $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Fichier introuvable : $relative" }
    $normalized = $relative.Replace('\', '/')
    $encoded = ($normalized.Split('/') | ForEach-Object { [Uri]::EscapeDataString($_) }) -join '/'
    $item = Get-Item -LiteralPath $path
    [ordered]@{
        path = $normalized
        url = $base + $encoded
        sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
        bytes = $item.Length
    }
}
[ordered]@{
    version = $Version
    mandatory = -not $Optional
    published_at = (Get-Date).ToUniversalTime().ToString('o')
    files = @($items)
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $root 'update-manifest.json') -Encoding utf8
Write-Output (Join-Path $root 'update-manifest.json')

