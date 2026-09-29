#===============================================================================
# Species Clause Rule for Challenge Modes
# Only allows unique species in the party (no duplicates)
#===============================================================================

module ChallengeModes
  # Check if Species Clause rule is active
  def self.species_clause?
    return on?(:SPECIES_CLAUSE)
  end
  
  # Check if species already exists in party
  def self.species_in_party?(species)
    species_data = species.is_a?(Symbol) ? species : GameData::Species.get(species).species
    
    $player.party.each do |pokemon|
      next if !pokemon
      # Check base species (not form)
      party_species = pokemon.species_data.species
      return true if party_species == species_data
    end
    
    return false
  end
  
  # Get party species list (for debugging)
  def self.get_party_species
    species_list = []
    $player.party.each do |pokemon|
      next if !pokemon
      species_list.push(pokemon.species_data.species)
    end
    return species_list
  end
end

#===============================================================================
# Hook into pbAddPokemon to block duplicate species
#===============================================================================
alias __challengemodes_speciesclause__pbAddPokemon pbAddPokemon unless defined?(__challengemodes_speciesclause__pbAddPokemon)

def pbAddPokemon(*args)
  # Check if Species Clause rule is active
  if ChallengeModes.species_clause?
    # Get species from arguments
    species = args[0]
    
    # Convert to Pokemon if needed
    if species.is_a?(Pokemon)
      pokemon = species
      species_data = pokemon.species_data.species
    else
      species_data = GameData::Species.get(species).species
    end
    
    # Check if species already in party
    if ChallengeModes.species_in_party?(species_data)
      species_name = GameData::Species.get(species_data).name
      pbMessage(_INTL("You already have a {1} in your party!", species_name))
      pbMessage(_INTL("Species Clause: Only one of each species allowed!"))
      
      # Send to PC instead
      if species.is_a?(Pokemon)
        pbStorePokemon(species)
        pbMessage(_INTL("{1} was sent to the PC.", species_name))
      end
      
      return false
    end
  end
  
  # Normal add
  return __challengemodes_speciesclause__pbAddPokemon(*args)
end

#===============================================================================
# Block duplicate species in battle catches (post-catch check)
#===============================================================================
class Battle
  alias __challengemodes_speciesclause__pbThrowPokeBall pbThrowPokeBall unless method_defined?(:__challengemodes_speciesclause__pbThrowPokeBall)
  
  def pbThrowPokeBall(*args)
    # Only check if Species Clause rule is active
    if ChallengeModes.species_clause?
      battler = nil
      if opposes?(args[0])
        battler = @battlers[args[0]]
      else
        battler = @battlers[args[0]].pbDirectOpposing(true)
      end
      battler = battler.allAllies.first if battler.fainted?
      
      # Check if species already in party
      if battler && ChallengeModes.species_in_party?(battler.pokemon.species_data.species)
        species_name = battler.pokemon.species_data.name
        pbDisplay(_INTL("Wait! You already have a {1}!", species_name))
        pbDisplay(_INTL("Species Clause: Only one of each species allowed!"))
        pbDisplay(_INTL("The Poké Ball cannot be used."))
        return
      end
    end
    
    # Normal catch attempt
    return __challengemodes_speciesclause__pbThrowPokeBall(*args)
  end
end

#===============================================================================
# Block trading for duplicate species
#===============================================================================
module Battle::BattlePeer
  alias __challengemodes_speciesclause__pbStorePokemon pbStorePokemon unless method_defined?(:__challengemodes_speciesclause__pbStorePokemon)
  
  def pbStorePokemon(pkmn)
    # Check if caught Pokémon violates species clause
    if ChallengeModes.species_clause? && ChallengeModes.species_in_party?(pkmn.species_data.species)
      species_name = pkmn.species_data.name
      pbMessage(_INTL("You already have a {1} in your party!", species_name))
      pbMessage(_INTL("The duplicate was sent to the PC instead."))
    end
    
    # Normal storage (will send to PC if party full or duplicate)
    return __challengemodes_speciesclause__pbStorePokemon(pkmn)
  end
end

#===============================================================================
# Script command to check party species
#===============================================================================
def pbCheckPartySpecies
  if !ChallengeModes.species_clause?
    pbMessage(_INTL("Species Clause is not active."))
    return
  end
  
  species_list = ChallengeModes.get_party_species
  
  if species_list.empty?
    pbMessage(_INTL("Your party is empty."))
    return
  end
  
  text = "Party Species:\\n"
  species_list.each_with_index do |species, i|
    species_name = GameData::Species.get(species).name
    text += "#{i + 1}. #{species_name}\\n"
  end
  
  pbMessage(_INTL(text))
end

#===============================================================================
# Console logging for debugging
#===============================================================================
if ChallengeModes.running?
  puts "Challenge Modes: Species Clause rule loaded"
  puts "  - Blocks duplicate species in party"
  puts "  - Checks base species (ignores forms)"
  puts "  - Sends duplicates to PC automatically"
end
