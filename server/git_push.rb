# frozen_string_literal: true

puts "================================================="
puts "🚀 Rangement Ultime & Publication sur GitHub..."
puts "================================================="

# Execute ultimate clean script first
system("ruby server/clean_root_structure.rb") rescue nil
system("ruby server/clean_root_ultimate.rb") rescue nil

ps_script = "server/do_git_push.ps1"

ps1_code = <<~'POWERSHELL'
Write-Host "--> Indexation de tous les sous-dossiers (launchers/, docs/, web/, tools/, server/)..."
git add -A

Write-Host "--> Création du commit..."
git commit -m "refactor: ultimate root folder cleanup (launchers, protocol, docs, web, tools)"

Write-Host "--> Push vers GitHub..."
git push origin main
if ($LASTEXITCODE -ne 0) {
    git push origin master
}
POWERSHELL

File.write(ps_script, ps1_code)

system("powershell -ExecutionPolicy Bypass -File #{ps_script}")

puts "================================================="
puts "✨ Rangement Ultime et Publication GitHub terminés !"
puts "================================================="

