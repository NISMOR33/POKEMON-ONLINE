#===============================================================================
# No Pokémon Center Rule for Challenge Modes
# Blocks all Pokémon Center healing when this rule is active
#===============================================================================

module ChallengeModes
  # Check if Pokémon Center healing is blocked
  def self.no_pokemon_center?
    return on?(:NO_POKEMON_CENTER)
  end
end

#===============================================================================
# Hook into Pokémon Center PC function to block healing
#===============================================================================
alias __challengemodes_nopc__pbPokeCenterPC pbPokeCenterPC unless defined?(__challengemodes_nopc__pbPokeCenterPC)

def pbPokeCenterPC(*args)
  # Check if No Pokémon Center rule is active
  if ChallengeModes.no_pokemon_center?
    pbMessage(_INTL("Pokémon Center healing is blocked by Challenge Mode rules!"))
    pbMessage(_INTL("You'll need to find other ways to heal your Pokémon."))
    return false
  end
  
  # Normal Pokémon Center functionality
  return __challengemodes_nopc__pbPokeCenterPC(*args)
end

#===============================================================================
# Console logging for debugging
#===============================================================================
if ChallengeModes.running?
  puts "Challenge Modes: No Pokémon Center rule loaded"
  puts "  - Blocks pbPokeCenterPC healing"
  puts "  - Shows rejection message when attempted"
end
