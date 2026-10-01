# frozen_string_literal: true

require "fileutils"

puts "================================================="
puts "🧹 Grand Rangement Intégral de la Racine du Dépôt"
puts "================================================="

# 1. Create clean subdirectories
FileUtils.mkdir_p("docs")
FileUtils.mkdir_p("web")
FileUtils.mkdir_p("tools/dev_tools")
FileUtils.mkdir_p("server/data")

# 2. Move Documentation files to docs/
docs_files = [
  "DOCUMENTATION_COMPLETE_MODPACK.md",
  "GUIDE_RENCONTRES_ROUTES_POKEMON.md",
  "POKEMON_NON_OBTENABLES.md",
  "POKEMON_OBTENABILITE_COMPLETE.md",
  "Readme.txt",
  "Essentials Docs Wiki.URL"
]

docs_files.each do |f|
  if File.exist?(f)
    FileUtils.mv(f, File.join("docs", File.basename(f))) rescue nil
    puts "  [docs/] <- #{f}"
  end
end

# 3. Move Web App & Map files to web/
web_files = [
  "app.js",
  "styles.css",
  "map_data.js",
  "map_data_pro.js",
  "townmapgen.html",
  "vectors.js",
  "vectors_data.js"
]

web_files.each do |f|
  if File.exist?(f)
    FileUtils.mv(f, File.join("web", File.basename(f))) rescue nil
    puts "  [web/] <- #{f}"
  end
end

# Keep index.html in root or copy to web/ so web browsers can open it easily
if File.exist?("index.html") && !File.exist?("web/index.html")
  FileUtils.cp("index.html", "web/index.html") rescue nil
end

# 4. Move Dev Tools & Executables to tools/dev_tools
dev_tool_files = [
  "animmaker.exe",
  "animmaker.txt",
  "extendtext.exe",
  "extendtext.txt",
  "check_all_diff.rb",
  "check_diff.rb",
  "inspect_map.rb",
  "knownpoint.bmp",
  "selpoint.bmp",
  "4165220a-d2e2-49d3-8bea-383aa223aa84.png",
  "png-clipart-computer-icons-pokemon-emerald-emerald-gemstone-blue.png"
]

dev_tool_files.each do |f|
  if File.exist?(f)
    FileUtils.mv(f, File.join("tools/dev_tools", File.basename(f))) rescue nil
    puts "  [tools/dev_tools/] <- #{f}"
  end
end

# 5. Move loose INTRO / _outils / exports folders into tools/ if present
["INTRO", "_outils", "exports"].each do |dir|
  if Dir.exist?(dir) && dir != "tools"
    dest = File.join("tools", dir)
    FileUtils.rm_rf(dest) if Dir.exist?(dest)
    FileUtils.mv(dir, dest) rescue nil
    puts "  [tools/] <- Dossier #{dir}"
  end
end

# 6. Move loose session & json data to server/data
data_files = [
  "gts_listings.json",
  "online_players.json",
  "mmo_account.dat",
  "mmo_guest",
  "mmo_session.dat"
]

data_files.each do |f|
  if File.exist?(f)
    FileUtils.mv(f, File.join("server/data", File.basename(f))) rescue nil
    puts "  [server/data/] <- #{f}"
  end
end

puts "================================================="
puts "✨ Rangement de la racine terminé avec succès !"
puts "================================================="

