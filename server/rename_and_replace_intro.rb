# frozen_string_literal: true

require "fileutils"

puts "================================================="
puts "🏷️ Renommage et remplacement automatique des images d'intro"
puts "================================================="

target_dir = "Graphics/Pictures"
search_dirs = ["INTRO", "Graphics/Pictures", "."]

found_files = {}

search_dirs.each do |dir|
  next unless Dir.exist?(dir)
  Dir.glob("#{dir}/Gemini_Generated_Image_*").each do |file|
    filename = File.basename(file)
    if filename.include?("jubrqoj") # Female (May)
      found_files[:female] = file
    elsif filename.include?("v8mpw") # Male (Brendan)
      found_files[:male] = file
    elsif filename.include?("re6ho9") # Background empty field
      found_files[:bg] = file
    elsif filename.include?("xti8vg") # Professor Birch
      found_files[:prof] = file
    end
  end
end

puts "Fichiers identifiés :"
puts "  - Fond neutre (introbg.png) : #{found_files[:bg] || 'Non trouvé'}"
puts "  - Professeur (introbg_1.png) : #{found_files[:prof] || 'Non trouvé'}"
puts "  - Héros masculin (introbg_male.png) : #{found_files[:male] || 'Non trouvé'}"
puts "  - Héroïne féminine (introbg_female.png) : #{found_files[:female] || 'Non trouvé'}"

# Perform copying & replacement
mappings = {
  bg: "introbg.png",
  prof: "introbg_1.png",
  male: "introbg_male.png",
  female: "introbg_female.png"
}

mappings.each do |key, target_filename|
  source = found_files[key]
  next unless source && File.exist?(source)

  dest = File.join(target_dir, target_filename)

  # Backup old if present
  if File.exist?(dest)
    FileUtils.cp(dest, "#{dest}.bak") rescue nil
  end

  FileUtils.cp(source, dest)
  puts "✅ Remplacé : #{File.basename(source)} -> #{dest}"
  
  # Remove the raw Gemini_Generated_Image file if desired
  # File.delete(source) rescue nil
end

puts "================================================="
puts "✨ Opération terminée avec succès !"
puts "================================================="

