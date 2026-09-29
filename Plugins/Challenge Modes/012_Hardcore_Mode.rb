#===============================================================================
# Hardcore Mode - No EVs, Perfect IVs
# Removes EV mechanics entirely and gives all Pokemon perfect 31 IVs
# This creates a balanced competitive environment for hardcore challenges
#===============================================================================

#===============================================================================
# Add HARDCORE_MODE to the challenge rules
#===============================================================================
module ChallengeModes
  RULES[:HARDCORE_MODE] = {
    :name  => _INTL("Hardcore Mode"),
    :desc  => _INTL("All Pokémon have perfect IVs (31) and EVs are disabled entirely. Creates a balanced competitive experience."),
    :order => 19
  }
end

#===============================================================================
# Hook into Pokemon creation to set perfect IVs and zero EVs
#===============================================================================
EventHandlers.add(:on_wild_pokemon_created, :hardcore_ivs,
  proc { |pkmn|
    next if !ChallengeModes.on?(:HARDCORE_MODE)
    
    echoln ">>> Hardcore Mode: Setting perfect IVs for wild #{pkmn.name}"
    # Set all IVs to 31 (perfect)
    GameData::Stat.each_main do |s|
      pkmn.iv[s.id] = 31
    end
    
    # Zero out all EVs
    GameData::Stat.each_main do |s|
      pkmn.ev[s.id] = 0
    end
    
    pkmn.calc_stats
  }
)

#===============================================================================
# Hook into gifted/received Pokemon
#===============================================================================
EventHandlers.add(:on_pokemon_received, :hardcore_ivs,
  proc { |sender, e|
    pkmn = e[0]
    next if !pkmn
    next if !ChallengeModes.on?(:HARDCORE_MODE)
    
    echoln ">>> Hardcore Mode: Setting perfect IVs for received #{pkmn.name}"
    # Set all IVs to 31 (perfect)
    GameData::Stat.each_main do |s|
      pkmn.iv[s.id] = 31
    end
    
    # Zero out all EVs
    GameData::Stat.each_main do |s|
      pkmn.ev[s.id] = 0
    end
    
    pkmn.calc_stats
  }
)

#===============================================================================
# Prevent EVs from being gained in battle
#===============================================================================
class Battle
  alias hardcore_pbGainEVsOne pbGainEVsOne
  def pbGainEVsOne(idxParty, defeatedBattler)
    return if ChallengeModes.on?(:HARDCORE_MODE)
    hardcore_pbGainEVsOne(idxParty, defeatedBattler)
  end
end

#===============================================================================
# Block EV-raising items (Vitamins, Wings, etc.)
#===============================================================================
# ItemHandlers::UseOnPokemon.add(:HPUP, proc { |item, qty, pkmn, scene|
#   if ChallengeModes.on?(:HARDCORE_MODE)
#     scene.pbDisplay(_INTL("Hardcore Mode prevents the use of EV-raising items!"))
#     next false
#   end
#   # Normal behavior continues if not in hardcore mode
#   ItemHandlers.triggerUseOnPokemon(:VITAMIN, item, qty, pkmn, scene)
# })


# Add handlers for all vitamins
# [:HPUP, :PROTEIN, :IRON, :CALCIUM, :ZINC, :CARBOS].each do |vitamin|
#   ItemHandlers::UseOnPokemon.add(vitamin, proc { |item, qty, pkmn, scene|
#     if ChallengeModes.on?(:HARDCORE_MODE)
#       scene.pbDisplay(_INTL("Hardcore Mode prevents the use of EV-raising items!"))
#       next false
#     end
#     ItemHandlers.triggerUseOnPokemon(:VITAMIN, item, qty, pkmn, scene)
#   })
# end
#Crashes Game once used a vitamin item

# Add handlers for all wings (Gen 5+)
# [:HEALTHWING, :MUSCLEWING, :RESISTWING, :GENIUSWING, :CLEVERWING, :SWIFTWING].each do |wing|
#   next unless GameData::Item.exists?(wing)
#   ItemHandlers::UseOnPokemon.add(wing, proc { |item, qty, pkmn, scene|
#     if ChallengeModes.on?(:HARDCORE_MODE)
#       scene.pbDisplay(_INTL("Hardcore Mode prevents the use of EV-raising items!"))
#       next false
#     end
#     # Call original wing handler if it exists
#     if ItemHandlers.hasUseOnPokemon(:WING)
#       ItemHandlers.triggerUseOnPokemon(:WING, item, qty, pkmn, scene)
#     else
#       # Fallback: Wings give +1 EV (blocked anyway in hardcore mode)
#       scene.pbDisplay(_INTL("It won't have any effect."))
#       next false
#     end
#   })
# end
#
# # Add handlers for feathers (Gen 8+)
# [:HEALTHFEATHER, :MUSCLEFEATHER, :RESISTFEATHER, :GENIUSFEATHER, :CLEVERFEATHER, :SWIFTFEATHER].each do |feather|
#   next unless GameData::Item.exists?(feather)
#   ItemHandlers::UseOnPokemon.add(feather, proc { |item, qty, pkmn, scene|
#     if ChallengeModes.on?(:HARDCORE_MODE)
#       scene.pbDisplay(_INTL("Hardcore Mode prevents the use of EV-raising items!"))
#       next false
#     end
#     scene.pbDisplay(_INTL("It won't have any effect."))
#     next false
#   })
# end
#
# # Block Pomeg Berry and other EV-reducing berries
# [:POMEGBERRY, :KELPSYBERRY, :QUALOTBERRY, :HONDEWBERRY, :GREPABERRY, :TAMATOMBERRY].each do |berry|
#   next unless GameData::Item.exists?(berry)
#   ItemHandlers::UseOnPokemon.add(berry, proc { |item, qty, pkmn, scene|
#     if ChallengeModes.on?(:HARDCORE_MODE)
#       scene.pbDisplay(_INTL("Hardcore Mode keeps all EVs at 0. This berry has no effect!"))
#       next false
#     end
#     # Allow normal usage outside hardcore mode
#     ItemHandlers.triggerUseOnPokemon(:EVREDUCEBERRY, item, qty, pkmn, scene) if ItemHandlers.hasUseOnPokemon(:EVREDUCEBERRY)
#   })
# end

#===============================================================================
# Ensure EVs stay at 0 even if somehow gained
#===============================================================================
class Pokemon
  alias hardcore_calc_stats calc_stats
  def calc_stats
    if ChallengeModes.on?(:HARDCORE_MODE)
      # Force all EVs to 0 before calculating stats
      GameData::Stat.each_main do |s|
        @ev[s.id] = 0
      end
    end
    hardcore_calc_stats
  end
end

#===============================================================================
# Prevent player from giving EV training items to Pokemon
# (Power items, Macho Brace - blocked via UseOnPokemon handler)
#===============================================================================
# ItemHandlers::UseOnPokemon.add(:MACHOBRACE, proc { |item, qty, pkmn, scene|
#   if ChallengeModes.on?(:HARDCORE_MODE)
#     scene.pbDisplay(_INTL("Hardcore Mode prevents the use of EV-training items!"))
#     next false
#   end
#   # Normal behavior
#   if pkmn.hasItem?
#     scene.pbDisplay(_INTL("{1} is already holding an item.", pkmn.name))
#     next false
#   end
#   pkmn.item = item
#   scene.pbRefresh
#   scene.pbDisplay(_INTL("{1} is now holding {2}.", pkmn.name, GameData::Item.get(item).name))
#   next true
# })
#
# [:POWERWEIGHT, :POWERBRACER, :POWERBELT, :POWERLENS, :POWERBAND, :POWERANKLET].each do |power_item|
#   next unless GameData::Item.exists?(power_item)
#   ItemHandlers::UseOnPokemon.add(power_item, proc { |item, qty, pkmn, scene|
#     if ChallengeModes.on?(:HARDCORE_MODE)
#       scene.pbDisplay(_INTL("Hardcore Mode prevents the use of EV-training items!"))
#       next false
#     end
#     # Normal behavior
#     if pkmn.hasItem?
#       scene.pbDisplay(_INTL("{1} is already holding an item.", pkmn.name))
#       next false
#     end
#     pkmn.item = item
#     scene.pbRefresh
#     scene.pbDisplay(_INTL("{1} is now holding {2}.", pkmn.name, GameData::Item.get(item).name))
#     next true
#   })
# end


#===============================================================================
# Apply hardcore mode to trainer Pokemon as well
#===============================================================================
alias __hardcore__pbLoadTrainer pbLoadTrainer unless defined?(__hardcore__pbLoadTrainer)
def pbLoadTrainer(tr_type, tr_name, tr_version = 0)
  trainer = __hardcore__pbLoadTrainer(tr_type, tr_name, tr_version)
  
  if ChallengeModes.on?(:HARDCORE_MODE)
    echoln ">>> Hardcore Mode: Applying to trainer #{tr_name}'s Pokemon"
    trainer.party.each do |pkmn|
      # Set all IVs to 31 (perfect)
      GameData::Stat.each_main do |s|
        pkmn.iv[s.id] = 31
      end
      
      # Zero out all EVs
      GameData::Stat.each_main do |s|
        pkmn.ev[s.id] = 0
      end
      
      pkmn.calc_stats
    end
  end
  
  return trainer
end

#===============================================================================
# Display message when Hardcore Mode is activated
#===============================================================================
module ChallengeModes
  class << self
    alias hardcore_begin_challenge begin_challenge
  end
  
  def self.begin_challenge
    hardcore_begin_challenge
    
    if on?(:HARDCORE_MODE)
      pbMessage(_INTL("Hardcore Mode activated!"))
      pbMessage(_INTL("All Pokémon will have perfect IVs (31) and EVs are completely disabled."))
      pbMessage(_INTL("This creates a fair and balanced competitive environment!"))
    end
  end
end
