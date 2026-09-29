#===============================================================================
# Early Randomizer Activation Fix
# Automatically activates RANDOMIZER_MODE immediately when selected
# while other rules (Permafaint, One Capture, etc.) activate when getting first Pokéball
#===============================================================================

# Add new attribute to PokemonGlobalMetadata
class PokemonGlobalMetadata
  attr_accessor :challenge_randomizer_active
end

module ChallengeModes
  # Store the original methods
  class << self
    alias early_randomizer_on? on?
    alias early_randomizer_start start
    alias early_randomizer_begin_challenge begin_challenge
    alias early_randomizer_reset reset
  end
  
  # Override start to automatically activate randomizer immediately if selected
  def self.start
    early_randomizer_start
    
    # If RANDOMIZER_MODE was selected, activate it immediately (before first Pokéball)
    if $PokemonGlobal&.challenge_rules&.include?(:RANDOMIZER_MODE)
      if !$PokemonGlobal.challenge_randomizer_seed
        initialize_randomizer
        echoln ">>> Randomizer mode activated immediately (will work on starters)"
      end
      $PokemonGlobal.challenge_randomizer_active = true
      echoln "  challenge_randomizer_active set to TRUE"
      echoln "  ChallengeModes.on?(:RANDOMIZER_MODE) = #{on?(:RANDOMIZER_MODE)}"
    end
  end
  
  # Override the on? method to handle early randomizer activation
  def self.on?(rule = nil)
    # If asking about randomizer specifically and it's been activated early
    if rule == :RANDOMIZER_MODE && $PokemonGlobal&.challenge_randomizer_active
      return true
    end
    
    # Otherwise use normal logic
    return early_randomizer_on?(rule)
  end
  
  # Override begin_challenge to not re-initialize randomizer if already done
  def self.begin_challenge
    # Check if randomizer was already initialized early
    randomizer_already_active = $PokemonGlobal&.challenge_randomizer_active
    
    early_randomizer_begin_challenge
    
    if randomizer_already_active
      echoln ">>> Full challenge started (Randomizer was already active)"
    end
  end
  
  # Override reset to also reset the early randomizer flag
  def self.reset
    $PokemonGlobal.challenge_randomizer_active = nil if $PokemonGlobal
    early_randomizer_reset
  end
end

#===============================================================================
# No manual setup needed! Randomizer activates automatically when you select it
# Other rules (Permafaint, One Capture, etc.) still activate when you get your first Pokéball
#===============================================================================
