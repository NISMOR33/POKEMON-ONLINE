# frozen_string_literal: true

puts "================================================="
puts "🚀 Publication des modifications sur GitHub..."
puts "================================================="

ps_script = "server/do_git_push.ps1"

ps1_code = <<~'POWERSHELL'
Write-Host "--> Indexation des fichiers modifiés..."
git add -A

Write-Host "--> Création du commit..."
git commit -m "feat: GTS enhancements, Delete Save button UI, intro graphics & professional README"

Write-Host "--> Push vers GitHub..."
git push origin main
if ($LASTEXITCODE -ne 0) {
    git push origin master
}
POWERSHELL

File.write(ps_script, ps1_code)

system("powershell -ExecutionPolicy Bypass -File #{ps_script}")

puts "================================================="
puts "✨ Publication terminée !"
puts "================================================="

