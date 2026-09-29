#===============================================================================
# Limited Healing Rule for Challenge Modes
# Limits the number of Pokémon Center visits per area/town
#===============================================================================

module ChallengeModes
  # Initialize healing counter hash if not exists
  @healing_counter ||= {}
  
  # Check if Limited Healing rule is active
  def self.limited_healing?
    return on?(:LIMITED_HEALING)
  end
  
  # Get healing count for current map
  def self.get_healing_count(map_id = nil)
    map_id ||= $game_map.map_id
    @healing_counter ||= {}
    return @healing_counter[map_id] || 0
  end
  
  # Increment healing count for current map
  def self.increment_healing_count(map_id = nil)
    map_id ||= $game_map.map_id
    @healing_counter ||= {}
    @healing_counter[map_id] ||= 0
    @healing_counter[map_id] += 1
  end
  
  # Check if healing is allowed on current map
  def self.can_heal_on_map?(map_id = nil)
    return true if !limited_healing?
    map_id ||= $game_map.map_id
    count = get_healing_count(map_id)
    return count < LIMITED_HEALING_COUNT
  end
  
  # Get remaining heals for current map
  def self.remaining_heals(map_id = nil)
    return -1 if !limited_healing?
    map_id ||= $game_map.map_id
    count = get_healing_count(map_id)
    return LIMITED_HEALING_COUNT - count
  end
  
  # Reset healing counter (for new runs or debugging)
  def self.reset_healing_counter
    @healing_counter = {}
  end
end

#===============================================================================
# Hook into Pokémon Center PC function to track healing
#===============================================================================
alias __challengemodes_limitheal__pbPokeCenterPC pbPokeCenterPC unless defined?(__challengemodes_limitheal__pbPokeCenterPC)

def pbPokeCenterPC(*args)
  # Check if Limited Healing rule is active
  if ChallengeModes.limited_healing?
    map_id = $game_map.map_id
    
    # Check if healing is allowed
    if !ChallengeModes.can_heal_on_map?(map_id)
      map_name = pbGetMapNameFromId(map_id)
      pbMessage(_INTL("The Pokémon Center is closed for you!"))
      pbMessage(_INTL("You've already used your {1} healing visits in {2}.", 
                      ChallengeModes::LIMITED_HEALING_COUNT, map_name))
      return false
    end
    
    # Increment counter BEFORE healing
    ChallengeModes.increment_healing_count(map_id)
    
    # Show remaining heals
    remaining = ChallengeModes.remaining_heals(map_id)
    map_name = pbGetMapNameFromId(map_id)
    
    # Perform normal healing
    result = __challengemodes_limitheal__pbPokeCenterPC(*args)
    
    # Show message after healing
    if remaining == 0
      pbMessage(_INTL("This was your last healing visit in {1}!", map_name))
    elsif remaining == 1
      pbMessage(_INTL("You have 1 healing visit left in {1}.", map_name))
    else
      pbMessage(_INTL("You have {1} healing visits left in {2}.", remaining, map_name))
    end
    
    return result
  end
  
  # Normal Pokémon Center functionality
  return __challengemodes_limitheal__pbPokeCenterPC(*args)
end

#===============================================================================
# Add healing counter to reset function
#===============================================================================
module ChallengeModes
  class << self
    alias __limitheal__reset reset unless method_defined?(:__limitheal__reset)
    
    def reset
      __limitheal__reset
      reset_healing_counter
      puts "Challenge Modes: Healing counter reset"
    end
  end
end

#===============================================================================
# Script command to check healing status
#===============================================================================
def pbCheckHealingStatus
  if !ChallengeModes.limited_healing?
    pbMessage(_INTL("Limited Healing is not active."))
    return
  end
  
  map_id = $game_map.map_id
  map_name = pbGetMapNameFromId(map_id)
  count = ChallengeModes.get_healing_count(map_id)
  remaining = ChallengeModes.remaining_heals(map_id)
  
  if remaining > 0
    pbMessage(_INTL("Healing visits in {1}:\\n{2} used, {3} remaining", 
                    map_name, count, remaining))
  else
    pbMessage(_INTL("You've used all {1} healing visits in {2}!", 
                    ChallengeModes::LIMITED_HEALING_COUNT, map_name))
  end
end

#===============================================================================
# Console logging for debugging
#===============================================================================
if ChallengeModes.running?
  puts "Challenge Modes: Limited Healing rule loaded"
  puts "  - Max heals per area: #{ChallengeModes::LIMITED_HEALING_COUNT}"
  puts "  - Tracks healing by map ID"
  puts "  - Shows remaining heals after each visit"
end
