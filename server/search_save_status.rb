# frozen_string_literal: true

rxdata_plugin = "Data/PluginScripts.rxdata"
if File.exist?(rxdata_plugin)
  puts "⚠️ Data/PluginScripts.rxdata existe ! Suppression pour forcer la recompilation des plugins..."
  File.delete(rxdata_plugin) rescue nil
  puts "✅ Data/PluginScripts.rxdata supprimé !"
end

puts "\n--- RECHERCHE DES PLUGINS DE MENU DE CHARGEMENT ---"
Dir.glob("Plugins/**/*.rb").each do |file|
  content = File.read(file, encoding: "UTF-8") rescue ""
  if content.match?(/Save Status|PokemonLoadScreen|pbStartLoadScreen|cmd_continue|Continuer/i)
    puts "Plugin trouvé : #{file}"
    content.each_line.with_index(1) do |line, lnum|
      if line.match?(/commands\[|commands\s*=|cmd_continue|cmd_options|cmd_debug|cmd_quit/i)
        puts "  Ligne #{lnum}: #{line.strip}"
      end
    end
  end
end

