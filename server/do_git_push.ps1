Write-Host "--> Indexation de tous les sous-dossiers (launchers/, docs/, web/, tools/, server/)..."
git add -A

Write-Host "--> Création du commit..."
git commit -m "refactor: ultimate root folder cleanup (launchers, protocol, docs, web, tools)"

Write-Host "--> Push vers GitHub..."
git push origin main
if ($LASTEXITCODE -ne 0) {
    git push origin master
}
