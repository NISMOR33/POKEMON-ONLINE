# Challenge Modes - Changelog

## Version 2.1 - Major Update (November 2025)

### New Challenge Rules (5 Added)

**No Pokémon Centers (Rule 15)**
- Completely blocks all Pokémon Center healing
- Forces players to rely on items and healing moves
- Shows clear rejection messages when attempting to heal

**No Legendaries (Rule 16)**
- Prevents catching Legendary and Mythical Pokémon
- Blocks Poké Ball usage on legendaries in battle
- Automatically detects Pokémon with "Legendary" or "Mythical" flags
- Legendary encounters still occur but cannot be captured

**Limited Healing (Rule 17)**
- Limits Pokémon Center visits to 3 per town/area
- Tracks healing counter per map ID
- Shows remaining heals after each visit
- Configurable limit via LIMITED_HEALING_COUNT constant

**Species Clause (Rule 18)**
- Only allows one Pokémon of each species in party
- Blocks catching duplicate species
- Automatically sends duplicates to PC
- Checks base species (ignores forms)

**Item Restrictions (Rule 19)**
- Bans all X-Items in battle (X Attack, X Defense, X Speed, etc.)
- Limits Revive usage to 3 per battle
- Limits Max Revive usage to 3 per battle
- Limits Full Restore usage to 3 per battle
- Counter resets at start of each battle
- Shows remaining uses when items are used

### Rule Count
- Total rules increased from 14 to 19
- All new rules fully documented in COMPLETE_GUIDE.md

### Compatibility Improvements

**Level Caps EX Integration**
- Added runtime detection for Level Caps EX plugin
- LEVEL_CAP rule only visible when plugin is installed
- Challenge Modes works standalone without Level Caps EX
- Level Caps EX works standalone without Challenge Modes
- No conflicts between plugins

**Helper Methods Added**
- `ChallengeModes.level_caps_available?` - Checks if Level Caps EX installed
- `ChallengeModes.level_cap_active?` - Checks if LEVEL_CAP rule active
- Runtime filtering in rule selector prevents errors

### Bug Fixes

**001_Main Module.rb**
- Fixed duplicate `end` statement causing syntax error
- Corrected module closing structure

**012_Hardcore_Mode.rb**
- Removed non-existent `ItemHandlers::CanHold` handlers
- EV-training items now blocked via `UseOnPokemon` only
- Fixed compatibility with Essentials v21.1 item system

**013_Trainer_Scaling.rb**
- Removed duplicate incomplete code at end of file
- Fixed unfinished `suggest_held_item` method
- Cleaned up 80+ lines of redundant code

**014_No_Pokemon_Center.rb**
- Removed non-existent `pbTrainerEnd` hook
- Simplified to use only `pbPokeCenterPC` hook

### Documentation Updates

**COMPLETE_GUIDE.md**
- Updated from 14 to 19 rules
- Added comprehensive documentation for all 5 new rules
- Included usage examples, script commands, and configuration options
- Updated key features section

**LEVEL_CAPS_COMPATIBILITY.md**
- New comprehensive compatibility guide
- Covers standalone vs integrated usage
- Installation scenarios explained
- FAQ and troubleshooting section

### Configuration Changes

**000_Config.rb**
- Added 5 new rule entries (Orders 14-18)
- Added LIMITED_HEALING_COUNT constant (default: 3)
- Added ITEM_RESTRICTIONS_CONFIG hash with banned/limited items
- All new rules include name, description, and order

### Technical Improvements

**Code Quality**
- All syntax errors fixed and tested
- Removed duplicate code sections
- Improved error handling
- Better compatibility with Essentials v21.1

**Performance**
- Runtime detection instead of compile-time dependencies
- Graceful degradation when optional plugins missing
- Optimized rule checking

### Files Added
- `014_No_Pokemon_Center.rb` - No Pokémon Center rule implementation
- `015_No_Legendaries.rb` - No Legendaries rule implementation
- `016_Limited_Healing.rb` - Limited Healing counter system
- `017_Species_Clause.rb` - Species uniqueness enforcement
- `018_Item_Restrictions.rb` - Battle item restrictions
- `LEVEL_CAPS_COMPATIBILITY.md` - Compatibility documentation

### Files Modified
- `000_Config.rb` - Added 5 new rules and configuration constants
- `001_Main Module.rb` - Added Level Caps EX helper methods, fixed syntax
- `002_Rule Select.rb` - Added runtime filtering for LEVEL_CAP rule
- `012_Hardcore_Mode.rb` - Fixed item handler compatibility
- `013_Trainer_Scaling.rb` - Removed duplicate code, fixed syntax
- `COMPLETE_GUIDE.md` - Updated with 5 new rules documentation

---

## Version 2.0 - Previous Release

### Initial Features
- 14 base challenge rules
- Level Cap integration
- Trainer Scaling system
- Hardcore Mode
- Monotype and Randomizer modes
- Advanced AI integration
- Comprehensive documentation

---

## Compatibility Notes

**Essentials Version:** v21.1
**Hotfixes:** 1.0.9
**Optional Plugins:**
- Level Caps EX (for LEVEL_CAP rule)
- Advanced AI System (for enhanced trainer AI)
- Voltseon's Pause Menu (for level cap HUD)

All plugins work independently and detect each other at runtime.
