# frozen_string_literal: true

require "zlib"

rxdata_path = "Data/Scripts.rxdata"

unless File.exist?(rxdata_path)
  puts "❌ Data/Scripts.rxdata introuvable !"
  exit 1
end

scripts = File.open(rxdata_path, "rb") { |f| Marshal.load(f) }

puts "Total des scripts dans Scripts.rxdata : #{scripts.size}"

load_script_index = nil
main_script_index = nil

scripts.each_with_index do |script, idx|
  id, name, compress_code = script
  code = Zlib::Inflate.inflate(compress_code).force_encoding("UTF-8") rescue ""

  if name.match?(/^Main$/i)
    main_script_index = idx
  end

  if code.include?("class PokemonLoadScreen") || code.include?("cmd_continue")
    puts "--> Trouvé script de chargement : ##{idx} (#{name})"
    load_script_index = idx
  end
end

puts "Index Main : #{main_script_index}"

delete_save_ruby_code = <<~'RUBY'
#===============================================================================
# Integrated Plugin: Bouton Supprimer la save
#===============================================================================
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

class PokemonLoad_Scene
  if method_defined?(:pbStartScene)
    alias __delete_save_pbStartScene pbStartScene rescue nil
    def pbStartScene(commands, show_continue, trainer, frame_count, map_id, *extra)
      res = nil
      begin
        res = __delete_save_pbStartScene(commands, show_continue, trainer, frame_count, map_id, *extra)
      rescue ArgumentError
        res = __delete_save_pbStartScene(commands, show_continue, trainer, frame_count, map_id) rescue nil
      end

      if show_continue && @sprites && commands.length > 4
        start_y = 176
        spacing = 38
        (1...commands.length).each do |i|
          sprite = @sprites["panel_#{i}"] || @sprites["button_#{i}"] || @sprites["cmd_#{i}"]
          if sprite
            sprite.y = start_y + (i - 1) * spacing rescue nil
          end
        end
      end

      return res
    end
  end
end

class PokemonLoadScreen
  def pbStartLoadScreen
    commands = []
    cmd_continue     = -1
    cmd_delete_save  = -1
    cmd_new_game     = -1
    cmd_options      = -1
    cmd_debug        = -1
    cmd_quit         = -1

    show_continue = SaveData.exists? rescue false

    if show_continue
      commands[cmd_continue = commands.length] = _INTL("Continuer")
      commands[cmd_delete_save = commands.length] = _INTL("Supprimer la save")
    end

    commands[cmd_new_game = commands.length] = _INTL("Nouvelle Partie")
    commands[cmd_options = commands.length] = _INTL("Options")

    if $DEBUG
      commands[cmd_debug = commands.length] = _INTL("Debug")
    end

    commands[cmd_quit = commands.length] = _INTL("Quitter le jeu")

    map_id = 0
    trainer = nil
    frame_count = 0
    save_data = nil

    if show_continue
      save_data = SaveData.read_from_file rescue nil
      if save_data
        trainer = save_data[:player] rescue nil
        frame_count = save_data[:frame_count] rescue 0
        map_id = save_data[:map_factory].map.map_id rescue 0
      end
    end

    begin
      @scene.pbStartScene(commands, show_continue, trainer, frame_count, map_id, 0)
    rescue => e
      begin
        @scene.pbStartScene(commands, show_continue, trainer, frame_count, map_id)
      rescue => e2
        @scene.pbStartScene(commands, show_continue, trainer, frame_count) rescue nil
      end
    end

    loop do
      command = @scene.pbChoose(commands)
      if cmd_continue >= 0 && command == cmd_continue
        @scene.pbEndScene
        if defined?(Game) && Game.respond_to?(:load)
          Game.load(save_data)
        elsif defined?(pbLoad)
          pbLoad
        end
        return
      elsif cmd_delete_save >= 0 && command == cmd_delete_save
        if SaveDeletionHelper.confirm_and_delete(@scene)
          return
        end
      elsif cmd_new_game >= 0 && command == cmd_new_game
        @scene.pbEndScene
        SaveDeletionHelper.start_new_game
        return
      elsif cmd_options >= 0 && command == cmd_options
        pbFadeOutIn do
          scene = PokemonOption_Scene.new rescue nil
          screen = PokemonOptionScreen.new(scene) rescue nil
          screen.pbStartScreen rescue nil
        end
      elsif cmd_debug >= 0 && command == cmd_debug
        pbFadeOutIn do
          pbDebugMenu rescue nil
        end
      elsif cmd_quit >= 0 && command == cmd_quit
        @scene.pbEndScene
        $scene = nil
        return
      end
    end
  end
end
RUBY

compressed_patch = Zlib::Deflate.deflate(delete_save_ruby_code)
patch_script_entry = [rand(100_000..999_999), "Plugin_DeleteSave", compressed_patch]

# Remove any existing Plugin_DeleteSave script
scripts.reject! { |s| s[1] == "Plugin_DeleteSave" }

# Insert right before Main
insert_pos = scripts.size
scripts.each_with_index do |s, idx|
  if s[1].match?(/^Main$/i)
    insert_pos = idx
    break
  end
end

scripts.insert(insert_pos, patch_script_entry)

File.open(rxdata_path, "wb") do |f|
  Marshal.dump(scripts, f)
end

puts "✅ Patch injecté avec succès dans Data/Scripts.rxdata juste avant Main !"

