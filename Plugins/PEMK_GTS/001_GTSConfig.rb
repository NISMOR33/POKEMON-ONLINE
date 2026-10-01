#===============================================================================
# PEMK_GTS :: 001 Config
#-------------------------------------------------------------------------------
# Configuration and constants for the Global Trade System (Hôtel des Ventes).
# Allows players to buy and sell Pokémon and Items via fixed price or auctions.
#===============================================================================
module PEMK
  module GTS
    TAX_RATE           = 0.05    # 5% tax on sales to control economy inflation
    MIN_LISTING_FEE    = 100     # Minimum deposit fee to list an item/Pokémon (PokéDollars)
    MAX_ACTIVE_LISTINGS = 10     # Max active listings per player at a time
    DEFAULT_DURATION   = 48      # Default listing duration in hours (24h, 48h, 72h)

    # Search categories for Pokémon
    POKEMON_CATEGORIES = [
      { id: "all",      name: "Tous les Pokémon" },
      { id: "shiny",    name: "✨ Chromatique (Shiny)" },
      { id: "legend",   name: "👑 Légendaire & Fabuleux" },
      { id: "mega",     name: "💎 Méga-Évolution / Forme Z" },
      { id: "starter",  name: "⭐ Pokémon de Départ" },
    ].freeze

    # Search categories for Items
    ITEM_CATEGORIES = [
      { id: "all",        name: "Tous les Objets" },
      { id: "pokeball",   name: "🔴 Poké Balls" },
      { id: "medicine",   name: "💊 Soins & Médicaments" },
      { id: "held_item",  name: "⚔️ Objets Tenus & Combat" },
      { id: "evolution",  name: "✨ Pierres & Évolution" },
      { id: "mega_stone", name: "💎 Méga-Gemmes & Cristaux Z" },
      { id: "housing",    name: "🏠 Meubles & Housing" },
    ].freeze

    # Sorting options
    SORT_OPTIONS = [
      { id: "recent",     name: "Plus récents" },
      { id: "price_asc",  name: "Prix croissant" },
      { id: "price_desc", name: "Prix décroissant" },
      { id: "expiring",   name: "Fin prochaine" },
    ].freeze

    def self.player_party
      return $player.party if defined?($player) && $player && $player.respond_to?(:party)
      return $Trainer.party if defined?($Trainer) && $Trainer && $Trainer.respond_to?(:party)
      []
    end

    def self.player_money
      return $player.money if defined?($player) && $player && $player.respond_to?(:money)
      return $Trainer.money if defined?($Trainer) && $Trainer && $Trainer.respond_to?(:money)
      0
    end

    def self.add_player_money(amt)
      if defined?($player) && $player && $player.respond_to?(:money=)
        $player.money = ($player.money || 0) + amt rescue nil
      elsif defined?($Trainer) && $Trainer && $Trainer.respond_to?(:money=)
        $Trainer.money = ($Trainer.money || 0) + amt rescue nil
      end
    end

    # Helper method to open the GTS UI from NPC or pause menu
    def self.open_menu
      return unless defined?(PEMK::GTSMenu)
      if defined?(pbConfirmMessage) && (player_party.size < 6 || player_money < 10000)
        if pbConfirmMessage(_INTL("Voulez-vous ajouter le pack de test GTS (6 Légendaires + 100 000 $ + Objets) ?"))
          give_test_data
        end
      end
      PEMK::GTSMenu.open
    end

    # Test Helper: Give 6 Legendary Pokémon, 100,000 $ PokéDollars and rare items to Bag
    def self.give_test_data
      # 1. Give 6 Legendary Pokémon (Lvl 70)
      legends = [:RAYQUAZA, :KYOGRE, :GROUDON, :MEWTWO, :DIALGA, :PALKIA]
      legends.each do |species|
        begin
          if defined?(pbAddPokemon)
            pbAddPokemon(species, 70)
          elsif defined?(Pokemon)
            pkmn = Pokemon.new(species, 70)
            party = player_party
            party << pkmn if party.size < 6
          end
        rescue => e
        end
      end

      # 2. Give 100,000 $ PokéDollars
      add_player_money(100_000)

      # 3. Give Rare Items to Bag
      items = [:MASTERBALL, :RARECANDY, :MAXREVIVE, :ABILITYPATCH, :EXPSHARE]
      items.each do |item|
        begin
          if defined?($bag) && $bag
            $bag.add(item, 10) rescue nil
          elsif defined?($PokemonBag) && $PokemonBag
            $PokemonBag.pbStoreItem(item, 10) rescue nil
          end
        rescue => e
        end
      end

      if defined?(pbMessage)
        pbMessage(_INTL("🎁 Pack de test GTS ajouté avec succès !\n\n• 6 Pokémon Légendaires (Niv. 70)\n• +100 000 $\n• Objets rares ajoutés au Sac"))
      end
    end

    def self.sync_to_file
      begin
        root = File.expand_path("../../", __dir__)
        gts_path = File.join(root, "gts_listings.json")
        list = (defined?(listings) ? listings : (defined?(PEMK::GTS.listings) ? PEMK::GTS.listings : [])) || []
        json_data = (defined?(PEMK::HousingJSON) ? PEMK::HousingJSON.generate(list) : (defined?(HousingJSON) ? HousingJSON.generate(list) : list.to_json) rescue "[]")
        File.write(gts_path, json_data)
      rescue => e
      end

      begin
        root = File.expand_path("../../", __dir__)
        p_path = File.join(root, "online_players.json")
        p_name = defined?($player) && $player ? $player.name : (defined?($Trainer) && $Trainer ? $Trainer.name : "Unnamed")
        p_map = defined?($game_map) && $game_map ? ($game_map.name rescue "Bourg-en-Vol") : "Bourg-en-Vol"
        p_party = player_party
        p_lvl = p_party.first ? (p_party.first.level rescue 50) : 50

        p_data = [{
          name: p_name,
          level: p_lvl,
          location: p_map,
          online: true,
          updated_at: Time.now.strftime("%H:%M:%S")
        }]
        File.write(p_path, p_data.to_json)
      rescue => e
      end
    end

    def self.auto_save
      sync_to_file
      if defined?(SaveData) && SaveData.respond_to?(:save)
        SaveData.save rescue nil
      elsif defined?(pbSave)
        pbSave(true) rescue nil
      end
    end
  end
end

# Raccourci Touche F8 en jeu + Pulse de synchronisation
class Scene_Map
  alias_method :pemk_gts_shortcut_orig_update, :update

  def update
    if defined?(Input::F8) && Input.trigger?(Input::F8)
      PEMK::GTS.give_test_data
    end
    if (Graphics.frame_count % 120 == 0 rescue false)
      PEMK::GTS.sync_to_file rescue nil
    end
    pemk_gts_shortcut_orig_update
  end
end

