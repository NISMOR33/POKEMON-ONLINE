# frozen_string_literal: true

require "fileutils"

puts "================================================="
puts "🧹 Rangement & Organisation Pro du Répertoire"
puts "================================================="

# Create server subdirectories if not present
FileUtils.mkdir_p("server/tools")
FileUtils.mkdir_p("server/logs")

# Move diagnostic/inspection scripts to server/tools
temp_scripts = [
  "server/find_hud_plugin.rb",
  "server/find_exact_file.rb",
  "server/find_load_ui.rb",
  "server/find_load_ui_runner.rb",
  "server/search_save_status.rb",
  "server/inspect_scripts.rb",
  "server/read_load_code.rb",
  "server/extract_load_scene.rb",
  "server/extract_load_script.rb",
  "server/dump_all_load.rb",
  "server/locate_cutscenes.rb",
  "server/locate_save_hud.rb",
  "server/find_title_bg.rb",
  "server/check_intro_folder.rb",
  "server/check_image_resolutions.rb",
  "server/inspect_bak_dimensions.rb",
  "server/find_plugin_files.rb",
  "server/list_all_plugins.rb"
]

moved_count = 0
temp_scripts.each do |f|
  if File.exist?(f)
    dest = File.join("server/tools", File.basename(f))
    FileUtils.mv(f, dest)
    moved_count += 1
  end
end
puts "✅ #{moved_count} scripts de diagnostic déplacés vers server/tools/"

# Move text log files to server/logs
txt_files = Dir.glob("server/*.txt")
txt_count = 0
txt_files.each do |f|
  dest = File.join("server/logs", File.basename(f))
  FileUtils.mv(f, dest)
  txt_count += 1
end
puts "✅ #{txt_count} fichiers de logs déplacés vers server/logs/"

puts "================================================="
puts "✨ Rangement terminé ! Structure du dépôt propre."
puts "================================================="

