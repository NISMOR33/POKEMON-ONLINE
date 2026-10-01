# frozen_string_literal: true

puts "================================================="
puts "📦 Préparation du commit et push sur GitHub..."
puts "================================================="

# Create a clean .ps1 script to execute git commands
git_ps1 = "server/do_git_push.ps1"

ps1_code = <<~'POWERSHELL'
$status = git status --porcelain
if (-not $status) {
    Write-Host "ℹ️ Aucun changement à commiter."
    exit 0
}

Write-Host "--> Ajout des fichiers modifiés et nouveaux..."
git add .

Write-Host "--> Création du commit..."
git commit -m "feat: GTS enhancements, Delete Save button UI, intro graphics & server scripts"

Write-Host "--> Push vers le dépôt distant GitHub..."
git push origin main
if ($LASTEXITCODE -ne 0) {
    git push origin master
}

Write-Host "✅ Modifications publiées avec succès sur GitHub !"
POWERSHELL

File.write(git_ps1, ps1_code)

puts "Script git généré dans server/do_git_push.ps1."
puts "Pour exécuter le push sur GitHub, lancez la commande suivante dans PowerShell :"
puts "   ruby server/git_push.rb"

