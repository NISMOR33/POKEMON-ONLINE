#===============================================================================
# Item Restrictions Rule for Challenge Modes
# Bans X-Items and limits Revive/Full Restore usage per battle
#===============================================================================

module ChallengeModes
  # Initialize item usage counter
  @battle_item_usage ||= {}
  
  # Check if Item Restrictions rule is active
  def self.item_restrictions?
    return on?(:ITEM_RESTRICTIONS)
  end
  
  # Reset item usage counter (called at battle start)
  def self.reset_battle_items
    @battle_item_usage = {}
  end
  
  # Get item usage count for current battle
  def self.get_item_usage(item_id)
    @battle_item_usage ||= {}
    return @battle_item_usage[item_id] || 0
  end
  
  # Increment item usage count
  def self.increment_item_usage(item_id)
    @battle_item_usage ||= {}
    @battle_item_usage[item_id] ||= 0
    @battle_item_usage[item_id] += 1
  end
  
  # Check if item is allowed
  def self.can_use_item?(item_id)
    return true if !item_restrictions?
    
    item_data = GameData::Item.get(item_id)
    item_symbol = item_data.id
    
    # Check if item is banned
    if ITEM_RESTRICTIONS_CONFIG[:banned_items].include?(item_symbol)
      return false
    end
    
    # Check if item is limited
    if ITEM_RESTRICTIONS_CONFIG[:limited_items].include?(item_symbol)
      limit = ITEM_RESTRICTIONS_CONFIG[:item_limits][item_symbol] || 3
      usage = get_item_usage(item_symbol)
      return usage < limit
    end
    
    return true
  end
  
  # Get remaining uses for limited item
  def self.remaining_uses(item_id)
    return -1 if !item_restrictions?
    
    item_data = GameData::Item.get(item_id)
    item_symbol = item_data.id
    
    return -1 if !ITEM_RESTRICTIONS_CONFIG[:limited_items].include?(item_symbol)
    
    limit = ITEM_RESTRICTIONS_CONFIG[:item_limits][item_symbol] || 3
    usage = get_item_usage(item_symbol)
    return limit - usage
  end
end

#===============================================================================
# Hook into battle item usage
#===============================================================================
class Battle
  alias __challengemodes_itemrestrict__pbUseItemOnPokemon pbUseItemOnPokemon unless method_defined?(:__challengemodes_itemrestrict__pbUseItemOnPokemon)
  
  def pbUseItemOnPokemon(item, battler, scene)
    # Check if Item Restrictions rule is active
    if ChallengeModes.item_restrictions?
      item_data = GameData::Item.get(item)
      item_symbol = item_data.id
      
      # Check if item is allowed
      if !ChallengeModes.can_use_item?(item_symbol)
        # Check if banned
        if ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:banned_items].include?(item_symbol)
          scene.pbDisplay(_INTL("{1} is banned in Challenge Mode!", item_data.name))
          return false
        end
        
        # Check if limit reached
        if ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:limited_items].include?(item_symbol)
          limit = ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:item_limits][item_symbol] || 3
          scene.pbDisplay(_INTL("You've already used {1} this battle!", item_data.name))
          scene.pbDisplay(_INTL("Limit: {1} per battle", limit))
          return false
        end
      end
      
      # Track usage for limited items
      if ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:limited_items].include?(item_symbol)
        ChallengeModes.increment_item_usage(item_symbol)
        
        # Show remaining uses
        remaining = ChallengeModes.remaining_uses(item_symbol)
        if remaining == 0
          scene.pbDisplay(_INTL("(That was your last {1} for this battle)", item_data.name))
        elsif remaining > 0
          scene.pbDisplay(_INTL("({1} {2} remaining this battle)", remaining, item_data.name))
        end
      end
    end
    
    # Normal item usage
    return __challengemodes_itemrestrict__pbUseItemOnPokemon(item, battler, scene)
  end
  
  # Reset item counter at battle start
  alias __challengemodes_itemrestrict__pbStartBattle pbStartBattle unless method_defined?(:__challengemodes_itemrestrict__pbStartBattle)
  
  def pbStartBattle
    ChallengeModes.reset_battle_items if ChallengeModes.item_restrictions?
    return __challengemodes_itemrestrict__pbStartBattle
  end
end

#===============================================================================
# Block banned items in ItemHandlers
#===============================================================================
ItemHandlers::CanUseInBattle.add(:battle_items,
  proc { |item, pokemon, battler, move, firstAction, battle, scene, showMessages|
    next true if !ChallengeModes.item_restrictions?
    
    item_data = GameData::Item.get(item)
    item_symbol = item_data.id
    
    # Check if item is banned
    if ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:banned_items].include?(item_symbol)
      scene.pbDisplay(_INTL("{1} is banned in Challenge Mode!", item_data.name)) if showMessages
      next false
    end
    
    # Check if item limit reached
    if ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:limited_items].include?(item_symbol)
      if !ChallengeModes.can_use_item?(item_symbol)
        limit = ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:item_limits][item_symbol] || 3
        scene.pbDisplay(_INTL("You've already used {1} {2} this battle!", limit, item_data.name)) if showMessages
        next false
      end
    end
    
    next true
  }
)

#===============================================================================
# Block X-Items specifically (Battle stat boosters)
#===============================================================================
ItemHandlers::CanUseInBattle.copy(:battle_items, :XATTACK)
ItemHandlers::CanUseInBattle.copy(:battle_items, :XDEFEND)
ItemHandlers::CanUseInBattle.copy(:battle_items, :XSPATK)
ItemHandlers::CanUseInBattle.copy(:battle_items, :XSPDEF)
ItemHandlers::CanUseInBattle.copy(:battle_items, :XSPEED)
ItemHandlers::CanUseInBattle.copy(:battle_items, :XACCURACY)
ItemHandlers::CanUseInBattle.copy(:battle_items, :DIREHIT)
ItemHandlers::CanUseInBattle.copy(:battle_items, :GUARDSPEC)

# Revives and Full Restores
ItemHandlers::CanUseInBattle.copy(:battle_items, :REVIVE)
ItemHandlers::CanUseInBattle.copy(:battle_items, :MAXREVIVE)
ItemHandlers::CanUseInBattle.copy(:battle_items, :FULLRESTORE)

#===============================================================================
# Script command to check item usage
#===============================================================================
def pbCheckItemUsage
  if !ChallengeModes.item_restrictions?
    pbMessage(_INTL("Item Restrictions is not active."))
    return
  end
  
  text = "Battle Item Usage:\\n"
  used_any = false
  
  ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:limited_items].each do |item_symbol|
    usage = ChallengeModes.get_item_usage(item_symbol)
    if usage > 0
      item_name = GameData::Item.get(item_symbol).name
      limit = ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:item_limits][item_symbol] || 3
      text += "#{item_name}: #{usage}/#{limit}\\n"
      used_any = true
    end
  end
  
  if !used_any
    text += "No limited items used yet."
  end
  
  pbMessage(_INTL(text))
end

#===============================================================================
# Console logging for debugging
#===============================================================================
if ChallengeModes.running?
  puts "Challenge Modes: Item Restrictions rule loaded"
  #puts "  - Banned items: #{ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:banned_items].join(', ')}"
  puts "  - Banned items: #{(ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:banned_items] || []).join(', ')}"
  #puts "  - Limited items: #{ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:limited_items].join(', ')}"
  puts "  - Limited items: #{(ChallengeModes::ITEM_RESTRICTIONS_CONFIG[:limited_items] || []).join(', ')}"
  puts "  - Tracks usage per battle"
end
