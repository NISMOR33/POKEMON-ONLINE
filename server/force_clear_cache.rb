# frozen_string_literal: true

cache_file = "Data/PluginScripts.rxdata"
if File.exist?(cache_file)
  File.delete(cache_file)
  puts "✅ Cache Data/PluginScripts.rxdata supprimé avec succès !"
else
  puts "ℹ️ Le cache était déjà vide."
end

puts "Prêt ! Tu peux relancer ton jeu."

