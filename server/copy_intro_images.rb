# frozen_string_literal: true

require "fileutils"

intro_dir = "INTRO"
target_dir = "Graphics/Pictures"

puts "================================================="
puts "🖼️ Remplacement des images d'introduction..."
puts "================================================="

unless Dir.exist?(intro_dir)
  puts "❌ Le dossier INTRO n'existe pas !"
  exit 1
end

FileUtils.mkdir_p(target_dir)

files_in_intro = Dir.glob("#{intro_dir}/*.{png,jpg,jpeg,webp}").sort

puts "Fichiers trouvés dans INTRO/ :"
files_in_intro.each { |f| puts "  - #{File.basename(f)}" }

# Search target images in Graphics/
existing_intro_pictures = Dir.glob("Graphics/**/{intro,introbg,intro_bg,boy,girl}*").reject { |f| File.directory?(f) }

puts "\nImages d'intro existantes dans Graphics/ :"
existing_intro_pictures.each { |f| puts "  - #{f}" }

# Mapping logic
# introbg, introbg_1, introbg_male, introbg_female
files_in_intro.each do |source_path|
  filename = File.basename(source_path)
  
  # Standardize name for Essentials
  target_name = case filename
                when /male|boy|homme|garcon/i
                  "introbg_male.png"
                when /female|girl|femme|fille/i
                  "introbg_female.png"
                when /1|one/i
                  "introbg_1.png"
                when /bg|background|intro/i
                  "introbg.png"
                else
                  filename
                end

  dest_path = File.join(target_dir, target_name)
  
  # Backup existing file if present
  if File.exist?(dest_path)
    backup_path = "#{dest_path}.bak"
    FileUtils.cp(dest_path, backup_path) rescue nil
    puts "  [Backup] #{dest_path} -> #{backup_path}"
  end

  FileUtils.cp(source_path, dest_path)
  puts "  ✅ Copié : #{filename} -> #{dest_path}"
  
  # Also copy exact filename if user named it specifically (e.g. introbg.png, introbg_1.png, introbg_male.png, introbg_female.png)
  exact_dest = File.join(target_dir, filename)
  if exact_dest != dest_path
    FileUtils.cp(source_path, exact_dest)
    puts "  ✅ Copié également sous le nom d'origine : #{exact_dest}"
  end
end

puts "================================================="
puts "✨ Remplacement des images d'introduction terminé !"
puts "================================================="

