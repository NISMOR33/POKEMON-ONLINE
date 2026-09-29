#===============================================================================
# Raid Battle Storage Fix
# Ensures captured Pokemon in raids go to party first, then PC if party is full
#===============================================================================

class Battle
  # Override storage specifically for raid battles
  alias raid_fix_pbStorePokemon pbStorePokemon if method_defined?(:pbStorePokemon)
  def pbStorePokemon(pkmn)
    # In raid battles, force normal storage behavior
    if @raid
      # Check if party has space
      if $player.party.length < Settings::MAX_PARTY_SIZE
        return true  # Allow storage in party
      else
        return false # Party full, will go to PC
      end
    end
    
    # For non-raid battles, use the original method
    if respond_to?(:raid_fix_pbStorePokemon)
      return raid_fix_pbStorePokemon(pkmn)
    else
      return $player.party.length < Settings::MAX_PARTY_SIZE
    end
  end
end
