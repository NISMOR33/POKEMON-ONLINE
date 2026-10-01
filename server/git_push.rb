# frozen_string_literal: true

puts "================================================="
puts "🚀 Génération des Guides & Publication GitHub..."
puts "================================================="

# 1. Clean root structure
system("ruby server/clean_root_structure.rb") rescue nil
system("ruby server/clean_root_ultimate.rb") rescue nil

# 2. Generate complete HTML A-to-Z Pokemon guide
system("ruby server/generate_complete_html_guide.rb") rescue nil

ps_script = "server/do_git_push.ps1"

ps1_code = <<~'POWERSHELL'
Write-Host "--> Indexation de tous les sous-dossiers (web/pokemon_guide.html, docs/, launchers/, server/)..."
git add -A

Write-Host "--> Création du commit..."
git commit -m "feat: complete black & white HTML Pokemon A-to-Z obtention guide web/pokemon_guide.html"

Write-Host "--> Push vers GitHub..."
git push origin main
if ($LASTEXITCODE -ne 0) {
    git push origin master
}
POWERSHELL

File.write(ps_script, ps1_code)

system("powershell -ExecutionPolicy Bypass -File #{ps_script}")

puts "================================================="
puts "✨ Publication et Génération du Guide terminées !"
puts "================================================="

