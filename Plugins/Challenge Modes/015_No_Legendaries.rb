#===============================================================================
# No Legendaries Rule for Challenge Modes
# Blocks catching and using Legendary/Mythical Pokémon when this rule is active
#===============================================================================

module ChallengeModes
  # Check if a Pokémon is legendary or mythical
  def self.is_legendary?(pokemon)
    species_data = pokemon.is_a?(Pokemon) ? pokemon.species_data : GameData::Species.get(pokemon)
    return species_data.has_flag?("Legendary") || species_data.has_flag?("Mythical")
  end
  
  # Check if No Legendaries rule is active
  def self.no_legendaries?
    return on?(:NO_LEGENDARIES)
  end
end

#===============================================================================
# Block catching legendaries in battle
#===============================================================================
class Battle
  alias __challengemodes_nolegend__pbThrowPokeBall pbThrowPokeBall unless method_defined?(:__challengemodes_nolegend__pbThrowPokeBall)
  
  def pbThrowPokeBall(*args)
    # Only check if No Legendaries rule is active
    if ChallengeModes.no_legendaries?
      battler = nil
      if opposes?(args[0])
        battler = @battlers[args[0]]
      else
        battler = @battlers[args[0]].pbDirectOpposing(true)
      end
      battler = battler.allAllies.first if battler.fainted?
      
      # Check if target is legendary/mythical
      if battler && ChallengeModes.is_legendary?(battler.pokemon)
        pbDisplay(_INTL("The Poké Ball won't work!"))
        pbDisplay(_INTL("Legendary and Mythical Pokémon cannot be caught in Challenge Mode!"))
        return
      end
    end
    
    # Normal catch attempt
    return __challengemodes_nolegend__pbThrowPokeBall(*args)
  end
end

#===============================================================================
# Block using legendaries in battle
#===============================================================================
module Battle::BattlePeer
  alias __challengemodes_nolegend__pbStorePokemon pbStorePokemon unless method_defined?(:__challengemodes_nolegend__pbStorePokemon)
  
  def pbStorePokemon(pkmn)
    # Check if caught Pokémon is legendary and rule is active
    if ChallengeModes.no_legendaries? && ChallengeModes.is_legendary?(pkmn)
      pbMessage(_INTL("The Legendary Pokémon broke free and fled!"))
      pbMessage(_INTL("(Legendary Pokémon cannot be caught in Challenge Mode)"))
      return
    end
    
    # Normal storage
    return __challengemodes_nolegend__pbStorePokemon(pkmn)
  end
end

#===============================================================================
# Block legendaries from being sent into battle
#===============================================================================
EventHandlers.add(:on_player_step_taken, :no_legendaries_check,
  proc {
    next if !ChallengeModes.no_legendaries?
    
    # Remove any legendaries from party (safety check)
    $player.party.each_with_index do |pokemon, i|
      if ChallengeModes.is_legendary?(pokemon)
        pbMessage(_INTL("{1} cannot be used in Challenge Mode!", pokemon.name))
        pbMessage(_INTL("Legendary and Mythical Pokémon are banned!"))
        pbStorePokemon(pokemon)
        $player.party[i] = nil
      end
    end
    $player.party.compact!
  }
)

#===============================================================================
# Block adding legendaries via script/event
#===============================================================================
alias __challengemodes_nolegend__pbAddPokemon pbAddPokemon unless defined?(__challengemodes_nolegend__pbAddPokemon)

def pbAddPokemon(*args)
  # Check if No Legendaries rule is active
  if ChallengeModes.no_legendaries?
    # Get species from first argument
    species = args[0]
    species = GameData::Species.get(species) if !species.is_a?(Pokemon)
    
    # Block if legendary
    if ChallengeModes.is_legendary?(species)
      pbMessage(_INTL("Legendary and Mythical Pokémon cannot be obtained in Challenge Mode!"))
      return false
    end
  end
  
  # Normal add
  return __challengemodes_nolegend__pbAddPokemon(*args)
end

#===============================================================================
# Console logging for debugging
#===============================================================================
if ChallengeModes.running?
  puts "Challenge Modes: No Legendaries rule loaded"
  puts "  - Blocks catching legendary/mythical Pokémon"
  puts "  - Prevents using legendaries in battle"
  puts "  - Checks Legendary and Mythical flags"
end
