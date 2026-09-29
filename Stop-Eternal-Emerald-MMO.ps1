$stateFile = Join-Path $PSScriptRoot '.runtime\server.json'
if (Test-Path -LiteralPath $stateFile) {
    $state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
    if ($state.server -and (Get-Process -Id $state.server -ErrorAction SilentlyContinue)) {
        & taskkill.exe /PID $state.server /T /F | Out-Null
    }
    Remove-Item -LiteralPath $stateFile -Force
}
Write-Host 'Serveur Pokemon MMO Hoenn arrêté.' -ForegroundColor Green
