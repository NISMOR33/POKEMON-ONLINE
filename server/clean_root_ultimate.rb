# frozen_string_literal: true

require "fileutils"

puts "================================================="
puts "🧹 Rangement Ultime de la Racine (Finitions Pro)"
puts "================================================="

# 1. Create subdirectories
FileUtils.mkdir_p("launchers")
FileUtils.mkdir_p("server/protocol")
FileUtils.mkdir_p("server/data")

# 2. Move extra launcher batch and ps1 scripts to launchers/
launchers = [
  "0_Restart_Serveur.bat",
  "1_Lancer_Joueur_1.bat",
  "2_Lancer_Joueur_2.bat",
  "Lancer-Eternal-Emerald-Invite.bat",
  "Lancer-Eternal-Emerald-MMO.bat",
  "Lancer-Pokemon-Eternal-Emerald.lnk",
  "Start-Eternal-Emerald-MMO.ps1",
  "Stop-Eternal-Emerald-MMO.ps1"
]

launchers.each do |f|
  if File.exist?(f)
    FileUtils.mv(f, File.join("launchers", File.basename(f))) rescue nil
    puts "  [launchers/] <- #{f}"
  end
end

# 3. Move protocol folder to server/protocol
if Dir.exist?("protocol")
  Dir.glob("protocol/*").each do |f|
    dest = File.join("server/protocol", File.basename(f))
    FileUtils.mv(f, dest) rescue nil
  end
  FileUtils.rm_rf("protocol") rescue nil
  puts "  [server/protocol/] <- Dossier protocol"
end

# 4. Move loose mmo files to server/data
["mmo", "mmo_guest"].each do |f|
  if File.exist?(f)
    FileUtils.mv(f, File.join("server/data", File.basename(f))) rescue nil
    puts "  [server/data/] <- #{f}"
  end
end

# Create a clean single entry point shortcut in root if needed
main_launcher = "Lancer_le_Jeu.bat"
unless File.exist?(main_launcher)
  File.write(main_launcher, "@echo off\r\nstart Game.exe\r\n")
  puts "  ✅ Créé à la racine : Lancer_le_Jeu.bat"
end

puts "================================================="
puts "✨ Rangement Ultime Terminé !"
puts "================================================="

