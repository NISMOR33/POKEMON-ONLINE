#===============================================================================
# Challenge Modes - Trainer Scaling Integration
# Automatically makes trainers harder when challenge modes are active
#===============================================================================

module ChallengeModes
  # Configuration for trainer scaling
  TRAINER_SCALING = {
    # Level boost when challenge modes are active
    :level_boost => 2,
    
    # Chance to add extra Pokemon to trainer parties (0-100)
    :extra_pokemon_chance => 0,
    
    # Chance to upgrade Pokemon to evolved forms (0-100)
    :evolution_upgrade_chance => 0,
    
    # Give trainers better items
    :better_items => false,
    
    # Improve IVs for trainer Pokemon
    :improved_ivs => true,
    
    # Add held items to trainer Pokemon
    :held_items => false
  }
  
  # Apply challenge scaling to a trainer
  def self.scale_trainer(trainer_data)
    return trainer_data unless active_rules.any?
    
    scaled_data = trainer_data.dup
    scaled_party = []
    
    trainer_data[:party].each do |pkmn|
      scaled_pkmn = scale_pokemon(pkmn)
      scaled_party << scaled_pkmn
    end
    
    # Chance to add extra Pokemon
    if rand(100) < TRAINER_SCALING[:extra_pokemon_chance] && scaled_party.length < 6
      extra_pkmn = generate_extra_pokemon(scaled_party)
      scaled_party << extra_pkmn if extra_pkmn
    end
    
    # Better items for trainer
    if TRAINER_SCALING[:better_items]
      scaled_data[:items] = upgrade_trainer_items(trainer_data[:items])
    end
    
    scaled_data[:party] = scaled_party
    scaled_data
  end
  
  # Scale a single Pokemon
  def self.scale_pokemon(pkmn_data)
    scaled = pkmn_data.dup
    
    # Boost level
    if TRAINER_SCALING[:level_boost] > 0
      scaled[:level] = (pkmn_data[:level] + TRAINER_SCALING[:level_boost]).clamp(1, 100)
    end
    
    # Try to evolve Pokemon
    if rand(100) < TRAINER_SCALING[:evolution_upgrade_chance]
      evolved_species = try_evolve_species(pkmn_data[:species])
      scaled[:species] = evolved_species if evolved_species
    end
    
    # Improve IVs
    if TRAINER_SCALING[:improved_ivs]
      scaled[:iv] = [25, 25, 25, 25, 25, 25] unless pkmn_data[:iv]
    end
    
    # Add held item
    if TRAINER_SCALING[:held_items] && !pkmn_data[:item]
      scaled[:item] = suggest_held_item(pkmn_data[:species])
    end
    
    scaled
  end
  
  # Try to evolve a species to its next form
  def self.try_evolve_species(species)
    return species unless defined?(GameData::Species)
    
    species_data = GameData::Species.try_get(species)
    return species unless species_data
    
    # Get evolution data
    evolutions = species_data.get_evolutions
    return species if evolutions.empty?
    
    # Return first evolution
    evolutions.first[0]
  end
  
  # Suggest a held item based on species
  def self.suggest_held_item(species)
    return nil unless defined?(GameData::Species)
    
    species_data = GameData::Species.try_get(species)
    return nil unless species_data
    
    # Simple type-based items
    case species_data.types.first
    when :FIRE then :CHARCOAL
    when :WATER then :MYSTICWATER
    when :GRASS then :MIRACLESEED
    when :ELECTRIC then :MAGNET
    when :PSYCHIC then :TWISTEDSPOON
    when :FIGHTING then :BLACKBELT
    when :DARK then :BLACKGLASSES
    when :DRAGON then :DRAGONFANG
    when :GHOST then :SPELLTAG
    when :POISON then :POISONBARB
    when :ICE then :NEVERMELTICE
    when :BUG then :SILVERPOWDER
    when :ROCK then :HARDSTONE
    when :GROUND then :SOFTSAND
    when :STEEL then :METALCOAT
    when :FLYING then :SHARPBEAK
    when :FAIRY then :PIXIEPLATE
    else :SITRUSBERRY
    end
  end
  
  # Generate an extra Pokemon for trainer
  def self.generate_extra_pokemon(existing_party)
    return nil if existing_party.empty?
    
    # Base it on the strongest Pokemon in party
    strongest = existing_party.max_by { |p| p[:level] }
    return nil unless strongest
    
    # Create similar level Pokemon
    {
      species: random_similar_species(strongest[:species]),
      level: strongest[:level] - rand(1..3),
      moves: [],
      ability_index: nil,
      gender: nil,
      form: nil,
      item: suggest_held_item(strongest[:species]),
      iv: [20, 20, 20, 20, 20, 20],
      ev: nil,
      happiness: nil,
      shiny: false,
      shadow: false,
      ball: nil,
      name: nil
    }
  end
  
  # Get a random species similar to given species (same type or stage)
  def self.random_similar_species(species)
    # Fallback - just return a common species
    common_species = [:PIDGEY, :RATTATA, :ZIGZAGOON, :BIDOOF, :PATRAT, :LILLIPUP]
    common_species[rand(common_species.length)]
  end
  
  # Upgrade trainer items (more potions/revives)
  def self.upgrade_trainer_items(items)
    return [:FULLRESTORE, :FULLRESTORE] if items.nil? || items.empty?
    
    upgraded = items.map do |item|
      case item
      when :POTION then :SUPERPOTION
      when :SUPERPOTION then :HYPERPOTION
      when :HYPERPOTION then :FULLRESTORE
      when :REVIVE then :MAXREVIVE
      else item
      end
    end
    
    # Add extra item if not full
    upgraded << :FULLRESTORE if upgraded.length < 2
    
    upgraded
  end
  
  # Helper to check if trainer scaling is active
  def self.active_rules
    return ChallengeModes.rules if ChallengeModes.on?(:TRAINER_SCALING)
    return []
  end
  
  # Check if trainer scaling should be applied
  def self.scaling_active?
    return ChallengeModes.on?(:TRAINER_SCALING)
  end
end

#===============================================================================
# Hook into Battle initialization to scale trainer parties
#Added some code to fix
#===============================================================================
class Battle
  alias challenge_scaling_initialize initialize unless method_defined?(:challenge_scaling_initialize)

  def initialize(*args)
    challenge_scaling_initialize(*args)

    # Only scale if TRAINER_SCALING rule is active
    return unless ChallengeModes.on?(:TRAINER_SCALING)

    # Apply scaling to opponent trainers
    if @opponent && @opponent.is_a?(Array)
      @opponent.each do |trainer|
        next unless trainer && trainer.party
        scale_trainer_party(trainer)
      end
    elsif @opponent
      scale_trainer_party(@opponent) if @opponent.party
    end
  end

  private

  def scale_trainer_party(trainer)
    return unless trainer

    echoln "[Challenge Modes] Scaling trainer: #{trainer.name}"

    scaled_party = []
    trainer.party.each do |pkmn|
      next unless pkmn

      # Apply level boost
      if ChallengeModes::TRAINER_SCALING[:level_boost] > 0
        old_level = pkmn.level
        new_level = (old_level + ChallengeModes::TRAINER_SCALING[:level_boost]).clamp(1, 100)
        pkmn.level = new_level
        pkmn.calc_stats
        echoln "[Challenge Modes]   #{pkmn.name}: Lv.#{old_level} -> Lv.#{new_level}"
      end #End of added code to fix
      
      # Try to evolve Pokemon
      if rand(100) < ChallengeModes::TRAINER_SCALING[:evolution_upgrade_chance]
        evolved = try_evolve_trainer_pokemon(pkmn)
        echoln "[Challenge Modes]   #{pkmn.name} evolved to #{evolved.name}" if evolved != pkmn
      end
      
      # Improve IVs
      if ChallengeModes::TRAINER_SCALING[:improved_ivs]
        GameData::Stat.each_main do |s|
          pkmn.iv[s.id] = 25 if pkmn.iv[s.id] < 25
        end
        pkmn.calc_stats
      end
      
      # Add held item if none
      if ChallengeModes::TRAINER_SCALING[:held_items] && !pkmn.item
        item = suggest_held_item_for_pokemon(pkmn)
        pkmn.item = item if item
        echoln "[Challenge Modes]   #{pkmn.name} given #{GameData::Item.get(item).name}" if item
      end
      
      scaled_party << pkmn
    end
    
    # Chance to add extra Pokemon
    if scaled_party.length < 6 && rand(100) < ChallengeModes::TRAINER_SCALING[:extra_pokemon_chance]
      extra_pkmn = generate_extra_trainer_pokemon(scaled_party)
      if extra_pkmn
        scaled_party << extra_pkmn
        echoln "[Challenge Modes]   Added extra Pokemon: #{extra_pkmn.name} Lv.#{extra_pkmn.level}"
      end
    end
    
    # Better items for trainer
    if ChallengeModes::TRAINER_SCALING[:better_items]
      upgrade_trainer_items(trainer)
    end
  end
  
  def try_evolve_trainer_pokemon(pkmn)
    species_data = GameData::Species.get(pkmn.species)
    evolutions = species_data.get_evolutions
    return pkmn if evolutions.empty?
    
    # Get first evolution that doesn't require special conditions
    evolutions.each do |evo|
      method = evo[1]
      # Only evolve via level-up methods
      if method == :Level || method == :LevelMale || method == :LevelFemale || 
         method == :Ninjask || method == :Shedinja
        pkmn.species = evo[0]
        pkmn.calc_stats
        return pkmn
      end
    end
    
    pkmn
  end
  
  def suggest_held_item_for_pokemon(pkmn)
    species_data = GameData::Species.get(pkmn.species)
    
    # Type-based items
    case species_data.types.first
    when :FIRE then :CHARCOAL
    when :WATER then :MYSTICWATER
    when :GRASS then :MIRACLESEED
    when :ELECTRIC then :MAGNET
    when :PSYCHIC then :TWISTEDSPOON
    when :FIGHTING then :BLACKBELT
    when :DARK then :BLACKGLASSES
    when :DRAGON then :DRAGONFANG
    when :GHOST then :SPELLTAG
    when :POISON then :POISONBARB
    when :ICE then :NEVERMELTICE
    when :BUG then :SILVERPOWDER
    when :ROCK then :HARDSTONE
    when :GROUND then :SOFTSAND
    when :STEEL then :METALCOAT
    when :FLYING then :SHARPBEAK
    when :FAIRY then :PIXIEPLATE
    else :SITRUSBERRY
    end
  end
  
  def generate_extra_trainer_pokemon(party)
    return nil if party.empty?
    
    # Base on strongest Pokemon in party
    strongest = party.max_by { |p| p.level }
    return nil unless strongest
    
    # Get a similar species (same type preferred)
    species_data = GameData::Species.get(strongest.species)
    possible_species = []
    
    GameData::Species.each do |sp|
      next if sp.form != 0
      next if sp.mega_stone || sp.mega_move
      next if sp.species == strongest.species
      
      # Prefer same type
      if (sp.types & species_data.types).any?
        possible_species << sp.species
      end
    end
    
    # Fallback to any species
    possible_species = [:PIDGEY, :RATTATA, :ZIGZAGOON, :LILLIPUP, :PATRAT] if possible_species.empty?
    
    new_species = possible_species.sample
    new_level = [strongest.level - rand(1..3), 1].max
    
    pkmn = Pokemon.new(new_species, new_level)
    pkmn.item = suggest_held_item_for_pokemon(pkmn)
    pkmn.reset_moves
    
    # Set IVs
    GameData::Stat.each_main { |s| pkmn.iv[s.id] = 20 }
    pkmn.calc_stats
    
    pkmn
  end
  
  def upgrade_trainer_items(trainer)
    return unless trainer.items
    
    upgraded_items = []
    trainer.items.each do |item|
      upgraded = case item
      when :POTION then :SUPERPOTION
      when :SUPERPOTION then :HYPERPOTION
      when :HYPERPOTION then :FULLRESTORE
      when :REVIVE then :MAXREVIVE
      else item
      end
      upgraded_items << upgraded
    end
    
    # Add extra Full Restore if they have less than 2 items
    upgraded_items << :FULLRESTORE if upgraded_items.length < 2
    
    trainer.items = upgraded_items
    echoln "[Challenge Modes]   Upgraded trainer items: #{upgraded_items.inspect}"
  end
end