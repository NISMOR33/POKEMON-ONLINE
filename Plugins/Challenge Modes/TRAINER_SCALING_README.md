# Challenge Mode Trainer Scaling

This automatically makes trainers harder when challenge modes are active, just like Luka's system!

## What It Does

When ANY challenge mode is active:

- ✅ **+2 Level Boost** - All trainer Pokemon are 2 levels higher
- ✅ **40% Chance** - Trainers get an extra Pokemon (if they have < 6)
- ✅ **30% Chance** - Pokemon evolve to their next form
- ✅ **Better Items** - Potions → Super Potions → Hyper Potions → Full Restores
- ✅ **Better IVs** - Trainer Pokemon get 25 IVs instead of random
- ✅ **Held Items** - Pokemon get type-boosting items (Charcoal, Mystic Water, etc.)

## Configuration

Edit `TRAINER_SCALING` in `013_Trainer_Scaling.rb`:

```ruby
TRAINER_SCALING = {
  :level_boost => 2,              # How many levels to add
  :extra_pokemon_chance => 40,    # % chance to add extra Pokemon
  :evolution_upgrade_chance => 30, # % chance to evolve Pokemon
  :better_items => true,           # Upgrade trainer items
  :improved_ivs => true,           # Better IVs (25 instead of random)
  :held_items => true              # Add held items to Pokemon
}
```

## Examples

### Normal Mode

```ruby
register 14, :LASS, 'Marie' do |trainer|
  trainer.party << Pokemon.new(:POLIWAG, 4)
end
```

**Result:** Poliwag Level 4, no held item

### Challenge Mode Active

**Result:**

- Poliwag Level 6 (+2)
- Holding Mystic Water
- IVs: 25/25/25/25/25/25
- 40% chance trainer gets a 2nd Pokemon
- 30% chance Poliwag → Poliwhirl

## Advanced: Custom Scaling per Trainer

You can also check challenge mode in your trainer definitions:

```ruby
register 14, :LASS, 'Marie' do |trainer|
  if Settings.game.challenge_mode?
    # Manual hard mode
    trainer.party << Pokemon.new(:POLIWHIRL, 8)
    trainer.items << :FULLRESTORE
  else
    # Normal mode
    trainer.party << Pokemon.new(:POLIWAG, 4)
  end
end
```

This gives you FULL control over challenge mode differences!

## How It Works

The system hooks into `GameData::MapTrainer.get_trainer()` and automatically scales trainers before battles start. No manual work needed!
