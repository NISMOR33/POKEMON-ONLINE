# frozen_string_literal: true

require "zlib"

puts "================================================="
puts "🛠️ Modification DIRECTE du code de l'écran d'accueil"
puts "================================================="

# 1. Clear compiled plugin cache
if File.exist?("Data/PluginScripts.rxdata")
  File.delete("Data/PluginScripts.rxdata")
  puts "✅ Data/PluginScripts.rxdata supprimé."
end

# Helper ruby code for save deletion
save_helper_code = <<~'RUBY'
module SaveDeletionHelper
  def self.delete_all_saves
    if defined?(SaveData) && SaveData.respond_to?(:delete)
      SaveData.delete rescue nil
    end

    user_home = ENV["USERPROFILE"] || "C:/Users/admin"
    search_dirs = [
      ENV["APPDATA"],
      ENV["LOCALAPPDATA"],
      File.join(user_home, "Saved Games")
    ].compact

    search_dirs.each do |base|
      next unless File.directory?(base)
      Dir.glob("#{base}/**/*").each do |path|
        next if File.directory?(path)
        filename = File.basename(path)
        dirname = File.dirname(path)

        if dirname.match?(/Pokemon|Emerald|Save/i) || filename.match?(/Save|Game.*\.dat|Game.*\.sav|System\.dat|\.rxdata|\.dat/i)
          if filename.match?(/\.(rxdata|dat|sav|bak)$/i)
            File.delete(path) rescue nil
          end
        end
      end
    end
  end

  def self.start_new_game
    if defined?(Game) && Game.respond_to?(:start_new)
      Game.start_new
    elsif defined?(pbStartNewGame)
      pbStartNewGame
    else
      $scene = Scene_Map.new rescue nil
    end
  end

  def self.confirm_and_delete(scene = nil)
    if pbConfirmMessage(_INTL("⚠️ Voulez-vous vraiment SUPPRIMER votre sauvegarde et démarrer une nouvelle partie ?"))
      delete_all_saves
      pbMessage(_INTL("✅ Sauvegarde supprimée avec succès ! Lancement d'une nouvelle partie..."))
      scene.pbEndScene if scene && scene.respond_to?(:pbEndScene)
      start_new_game
      return true
    end
    return false
  end
end
RUBY

# 2. Update Plugins directory files directly
Dir.glob("Plugins/**/*.rb").each do |file|
  content = File.read(file, encoding: "UTF-8") rescue ""
  if content.include?("cmd_continue") || content.include?("pbStartLoadScreen")
    puts "--> Modification du fichier plugin : #{file}"
    
    # Inject SaveDeletionHelper if not present
    unless content.include?("SaveDeletionHelper")
      content = save_helper_code + "\n" + content
    end

    # Replace commands[cmd_continue = commands.length] = _INTL("Continuer") or similar
    content.gsub!(/commands\[cmd_continue\s*=\s*commands\.length\]\s*=\s*_INTL\("Continuer"\)/) do |match|
      "#{match}\n    commands[cmd_delete_save = commands.length] = _INTL(\"Supprimer la save\")"
    end
    
    content.gsub!(/commands\[cmd_continue\s*=\s*commands\.length\]\s*=\s*_INTL\("CONTINUE"\)/) do |match|
      "#{match}\n    commands[cmd_delete_save = commands.length] = _INTL(\"Supprimer la save\")"
    end

    File.write(file, content)
    puts "✅ #{file} mis à jour !"
  end
end

# 3. Direct modification of Data/Scripts.rxdata
rxdata_path = "Data/Scripts.rxdata"
if File.exist?(rxdata_path)
  scripts = File.open(rxdata_path, "rb") { |f| Marshal.load(f) }
  modified = false

  scripts.each_with_index do |script, idx|
    id, name, compress_code = script
    code = Zlib::Inflate.inflate(compress_code).force_encoding("UTF-8") rescue ""

    if code.include?("def pbStartLoadScreen") || code.include?("cmd_continue")
      puts "--> Script trouvé dans Scripts.rxdata : ##{idx} (#{name})"

      unless code.include?("SaveDeletionHelper")
        code = save_helper_code + "\n" + code
      end

      if code.include?("commands[cmd_continue = commands.length]") && !code.include?("cmd_delete_save")
        code.gsub!("commands[cmd_continue = commands.length] = _INTL(\"CONTINUE\")",
                   "commands[cmd_continue = commands.length] = _INTL(\"CONTINUE\")\n    commands[cmd_delete_save = commands.length] = _INTL(\"Supprimer la save\")")
        code.gsub!("commands[cmd_continue = commands.length] = _INTL(\"Continuer\")",
                   "commands[cmd_continue = commands.length] = _INTL(\"Continuer\")\n    commands[cmd_delete_save = commands.length] = _INTL(\"Supprimer la save\")")
        
        # Add handling loop
        code.gsub!("elsif cmd_options >= 0 && command == cmd_options",
                   "elsif cmd_delete_save >= 0 && command == cmd_delete_save\n        if SaveDeletionHelper.confirm_and_delete(@scene)\n          return\n        end\n      elsif cmd_options >= 0 && command == cmd_options")

        scripts[idx][2] = Zlib::Deflate.deflate(code)
        modified = true
        puts "✅ Script.rxdata ##{idx} (#{name}) modifié directement !"
      end
    end
  end

  if modified
    File.open(rxdata_path, "wb") { |f| Marshal.dump(scripts, f) }
    puts "✅ Data/Scripts.rxdata sauvegardé !"
  end
end

puts "================================================="
puts "✨ Modification terminée ! Relance ton jeu !"
puts "================================================="

