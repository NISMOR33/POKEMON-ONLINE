# frozen_string_literal: true

require "fileutils"

puts "================================================="
puts "🔍 Recherche approfondie et suppression de la sauvegarde..."
puts "================================================="

user_home = ENV["USERPROFILE"] || "C:/Users/admin"
appdata_roaming = ENV["APPDATA"] || File.join(user_home, "AppData", "Roaming")
appdata_local = ENV["LOCALAPPDATA"] || File.join(user_home, "AppData", "Local")
saved_games = File.join(user_home, "Saved Games")

search_dirs = [
  appdata_roaming,
  appdata_local,
  saved_games
]

found_files = []

# Scan for any directory containing Pokemon or Eternal Emerald or Emerald
search_dirs.each do |base|
  next unless File.directory?(base)
  
  # Search all subdirectories matching Pokemon/Emerald/Save
  Dir.glob("#{base}/**/*").each do |path|
    next if File.directory?(path)
    filename = File.basename(path)
    dirname = File.dirname(path)

    # Check if file is inside a game folder or is a save file
    if dirname.match?(/Pokemon|Emerald|Save/i) || filename.match?(/Save|Game.*\.dat|Game.*\.sav|System\.dat|\.rxdata|\.dat/i)
      # Match save extension files (.rxdata, .dat, .sav, .bak)
      if filename.match?(/\.(rxdata|dat|sav|bak)$/i)
        found_files << path
      end
    end
  end
end

found_files.uniq!

if found_files.empty?
  puts "⚠️ Aucune sauvegarde trouvée."
else
  puts "Fichiers de sauvegarde trouvés :"
  found_files.each do |f|
    begin
      File.delete(f)
      puts "✅ Supprimé : #{f}"
    rescue => e
      puts "❌ Impossible de supprimer #{f} : #{e.message}"
    end
  end
end

puts "================================================="


