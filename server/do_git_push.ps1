Write-Host "--> Indexation des fichiers modifiés..."
git add -A

Write-Host "--> Création du commit..."
git commit -m "feat: GTS enhancements, Delete Save button UI, intro graphics & professional README"

Write-Host "--> Push vers GitHub..."
git push origin main
if ($LASTEXITCODE -ne 0) {
    git push origin master
}
