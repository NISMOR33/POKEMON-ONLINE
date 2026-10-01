# frozen_string_literal: true

if File.exist?("Data/PluginScripts.rxdata")
  File.delete("Data/PluginScripts.rxdata")
  puts "✅ Data/PluginScripts.rxdata supprimé pour forcer la recompilation !"
end

puts "================================================="
puts "✨ Correction de la freeze / écran noir terminée !"
puts "================================================="

