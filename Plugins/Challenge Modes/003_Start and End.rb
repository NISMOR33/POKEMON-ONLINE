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

#-------------------------------------------------------------------------------
# Reload challenge data upon save reload
#-------------------------------------------------------------------------------
class PokemonLoadScreen
  alias __challenge__pbStartLoadScreen pbStartLoadScreen unless method_defined?(:__challenge__pbStartLoadScreen)
  def pbStartLoadScreen
    ret = __challenge__pbStartLoadScreen
    ChallengeModes.toggle(true) if ChallengeModes.running?
    return ret
  end
end

alias __challenge__pbTrainerName pbTrainerName unless defined?(__challenge__pbTrainerName)
def pbTrainerName(*args)
  ret = __challenge__pbTrainerName(*args)
  ChallengeModes.reset
  $PokemonGlobal.challenge_state = {}
  return ret
end

#-------------------------------------------------------------------------------
# Starts challenge only after obtaining a Pokeball
#-------------------------------------------------------------------------------
class PokemonBag
  alias __challenge__add add unless method_defined?(:__challenge__add)
  def add(*args)
    ret = __challenge__add(*args)
    item = args[0]
    return ret if !$PokemonGlobal || !$PokemonGlobal.challenge_qued || !GameData::Item.get(item).is_poke_ball?
    ChallengeModes.begin_challenge
    pbMessage(_INTL("Your Challenge has begun! Good Luck!"))
    return ret
  end
end


#-------------------------------------------------------------------------------
# Add Game Over methods
#-------------------------------------------------------------------------------
alias __challenge__pbStartOver pbStartOver unless defined?(__challenge__pbStartOver)
def pbStartOver(*args)
  return __challenge__pbStartOver(*args) if !ChallengeModes.on?
  resume = false
  pbEachPokemon do |pkmn, _|
    next if pkmn.fainted? || pkmn.egg?
    resume = true
    break
  end
  if resume && !ChallengeModes.on?(:GAME_OVER_WHITEOUT)
    loop do
      pbMessage("\\w[]\\wm\\c[8]\\l[3]" + 
        _INTL("All your Pokémon have fainted. But you still have Pokémon in your PC which you can continue the challenge with."))
      pbFadeOutIn(99999) {
        scene = PokemonStorageScene.new
        screen = PokemonStorageScreen.new(scene, $PokemonStorage)
        screen.pbStartScreen(0)
      }
      break if $player.able_pokemon_count != 0
    end
  else
    pbMessage("\\w[]\\wm\\c[8]\\l[3]" + 
      _INTL("All your Pokémon have fainted. You have lost the challenge! All challenge modifiers will now be turned off."))
    ChallengeModes.set_loss
  end
  return __challenge__pbStartOver(*args)
end