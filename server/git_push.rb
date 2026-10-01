# frozen_string_literal: true

puts "================================================="
puts "🚀 Organisation & Publication sur GitHub en cours..."
puts "================================================="

# Run workspace organizer first
system("ruby server/organize_workspace.rb") rescue nil

ps_script = "server/do_git_push.ps1"

ps1_code = <<~'POWERSHELL'
Write-Host "--> Indexation des fichiers modifiés et rangés..."
git add -A

Write-Host "--> Création du commit..."
git commit -m "refactor: workspace clean architecture, server scripts, intro graphics & ultra-pro README"

Write-Host "--> Push vers GitHub..."
git push origin main
if ($LASTEXITCODE -ne 0) {
    git push origin master
}
POWERSHELL

File.write(ps_script, ps1_code)

system("powershell -ExecutionPolicy Bypass -File #{ps_script}")

puts "================================================="
puts "✨ Publication et rangement terminés !"
puts "================================================="

