#===============================================================================
# PEMK_GTS :: 002 Net
#-------------------------------------------------------------------------------
# Network communication for the Global Trade System.
# Handles fetching listings, creating listings, buying, bidding, and claiming rewards.
#===============================================================================
class PokemonGlobalMetadata
  attr_accessor :gts_listings
  attr_accessor :gts_my_listings
  attr_accessor :gts_claims
end

module PEMK
  module GTS
    @listings      = []
    @my_listings   = []
    @pending_claim = []
    @is_loading    = false

    class << self
      attr_reader :is_loading

      def listings
        if defined?($PokemonGlobal) && $PokemonGlobal
          $PokemonGlobal.gts_listings ||= []
        else
          @listings ||= []
        end
      end

      def my_listings
        if defined?($PokemonGlobal) && $PokemonGlobal
          $PokemonGlobal.gts_my_listings ||= []
        else
          @my_listings ||= []
        end
      end

      def pending_claim
        if defined?($PokemonGlobal) && $PokemonGlobal
          $PokemonGlobal.gts_claims ||= []
        else
          @pending_claim ||= []
        end
      end

      def connected?
        c = PEMK.client rescue nil
        c && c.respond_to?(:connected?) && c.connected?
      end

      def sync_to_file
        begin
          root = defined?(Dir.pwd) ? Dir.pwd : "."
          gts_path1 = File.join(root, "gts_listings.json")
          gts_path2 = File.join(root, "server", "gts_listings.json")

          all_items = ((listings || []) + (my_listings || [])).uniq { |x| (x[:listing_uid] || x["listing_uid"]) rescue rand }
          json_data = (defined?(PEMK::HousingJSON) ? PEMK::HousingJSON.generate(all_items) : (defined?(HousingJSON) ? HousingJSON.generate(all_items) : all_items.to_json) rescue "[]")
          File.write(gts_path1, json_data) rescue nil
          File.write(gts_path2, json_data) rescue nil
        rescue => e
        end

        begin
          root = defined?(Dir.pwd) ? Dir.pwd : "."
          p_path1 = File.join(root, "online_players.json")
          p_path2 = File.join(root, "server", "online_players.json")

          p_name = defined?($player) && $player ? $player.name : (defined?($Trainer) && $Trainer ? $Trainer.name : "Unnamed")
          p_map = defined?($game_map) && $game_map ? ($game_map.name rescue "Bourg-en-Vol") : "Bourg-en-Vol"
          p_party = (defined?(player_party) ? player_party : (defined?(PEMK::GTS.player_party) ? PEMK::GTS.player_party : []))
          p_lvl = p_party.first ? (p_party.first.level rescue 50) : 50

          p_data = [{
            name: p_name,
            level: p_lvl,
            location: p_map,
            online: true,
            updated_at: Time.now.strftime("%H:%M:%S")
          }]
          File.write(p_path1, p_data.to_json) rescue nil
          File.write(p_path2, p_data.to_json) rescue nil
        rescue => e
        end
      end

      # ---- Outbound Client Messages ----

      # Fetch active listings with optional filters & search query
      def send_fetch_listings(type = "all", category = "all", query = "", sort_by = "recent", page = 1)
        if connected?
          @is_loading = true
          PEMK.client.send_message(
            type: :gts_fetch,
            listing_type: type,
            category: category,
            query: query,
            sort_by: sort_by,
            page: page
          )
        else
          @is_loading = false
          sync_to_file
          GTSMenu.on_data_received if defined?(GTSMenu) && GTSMenu.active?
        end
      end

      # Fetch player's own active listings and claimable items/money
      def send_fetch_my_listings
        if connected?
          @is_loading = true
          PEMK.client.send_message(type: :gts_fetch_mine)
        else
          @is_loading = false
          sync_to_file
          GTSMenu.on_data_received if defined?(GTSMenu) && GTSMenu.active?
        end
      end

      # Create a new listing (Pokémon or Item)
      def send_create_listing(listing_type, data, title, price_type, price, duration_hours = 48)
        json_str = (defined?(PEMK::HousingJSON) ? PEMK::HousingJSON.generate(data) : (defined?(HousingJSON) ? HousingJSON.generate(data) : "{}"))
        
        uid = "gts_#{rand(100000..999999)}"
        seller_name = defined?($player) && $player ? $player.name : (defined?($Trainer) && $Trainer ? $Trainer.name : "Joueur")
        new_listing = {
          listing_uid: uid,
          seller_name: seller_name,
          listing_type: listing_type.to_s,
          category: "all",
          title: title,
          data_json: json_str,
          price_type: price_type.to_s,
          price: price.to_i,
          current_bid: 0,
          expires_at: (Time.now + duration_hours * 3600).to_s
        }
        listings.unshift(new_listing)
        my_listings.unshift(new_listing)
        @is_loading = false
        PEMK::GTS.auto_save

        if connected?
          PEMK.client.send_message(
            type: :gts_create,
            listing_type: listing_type,
            data_json: json_str,
            title: title,
            price_type: price_type,
            price: price,
            duration_hours: duration_hours
          )
        end
        GTSMenu.on_data_received if defined?(GTSMenu) && GTSMenu.active?
      end

      # Buy a fixed price listing
      def send_buy_fixed(listing_uid)
        if connected?
          PEMK.client.send_message(type: :gts_buy_fixed, listing_uid: listing_uid)
        else
          idx = listings.find_index { |x| (x[:listing_uid] || x["listing_uid"]) == listing_uid }
          if idx
            item = listings.delete_at(idx)
            my_listings.delete_if { |x| (x[:listing_uid] || x["listing_uid"]) == listing_uid }
            PEMK::GTS.auto_save
            GTSMenu.on_data_received if defined?(GTSMenu) && GTSMenu.active?
          end
        end
      end

      # Place a bid on an auction listing
      def send_place_bid(listing_uid, bid_amount)
        return unless connected?
        PEMK.client.send_message(type: :gts_place_bid, listing_uid: listing_uid, bid_amount: bid_amount)
      end

      # Cancel an active listing
      def send_cancel_listing(listing_uid)
        if connected?
          PEMK.client.send_message(type: :gts_cancel, listing_uid: listing_uid)
        end

        idx = listings.find_index { |x| (x[:listing_uid] || x["listing_uid"]) == listing_uid }
        if idx
          item = listings.delete_at(idx)
          my_listings.delete_if { |x| (x[:listing_uid] || x["listing_uid"]) == listing_uid }

          kind = (item[:listing_type] || item["listing_type"]).to_s.downcase
          json_parser = (defined?(PEMK::HousingJSON) ? PEMK::HousingJSON : (defined?(HousingJSON) ? HousingJSON : nil))
          data_str = item[:data_json] || item["data_json"] || "{}"
          data = begin json_parser ? json_parser.parse(data_str, symbolize_names: true) : {} rescue {} end

          if kind.include?("poke")
            serialized = data[:serialized] || data["serialized"]
            restored = nil
            if serialized
              begin
                restored = Marshal.load(serialized.unpack1("m0"))
              rescue => e
              end
            end
            if restored
              party = player_party
              party << restored if party.size < 6
            else
              sp = (data[:species] || :PIKACHU).to_sym
              lvl = (data[:level] || 50).to_i
              pbAddPokemon(sp, lvl) rescue nil
            end
          else
            itm = (data[:item_id] || :POTION).to_sym
            q = (data[:qty] || 1).to_i
            if defined?($bag) && $bag
              $bag.add(itm, q) rescue nil
            elsif defined?($PokemonBag) && $PokemonBag
              $PokemonBag.pbStoreItem(itm, q) rescue nil
            end
          end

          PEMK::GTS.auto_save
          GTSMenu.on_data_received if defined?(GTSMenu) && GTSMenu.active?
        end
      end

      # Claim earnings or items from sold/expired/bought listings
      def send_claim(claim_id)
        return unless connected?
        PEMK.client.send_message(type: :gts_claim, claim_id: claim_id)
      end

      # ---- Inbound Message Handlers (Called by Dispatch) ----

      def on_gts_listings(msg)
        @is_loading = false
        json_parser = (defined?(PEMK::HousingJSON) ? PEMK::HousingJSON : (defined?(HousingJSON) ? HousingJSON : nil))
        raw_list = begin json_parser ? json_parser.parse(msg[:listings_json], symbolize_names: true) : [] rescue [] end
        if defined?($PokemonGlobal) && $PokemonGlobal
          $PokemonGlobal.gts_listings = raw_list || []
        else
          @listings = raw_list || []
        end
        GTSMenu.on_data_received if defined?(GTSMenu) && GTSMenu.active?
      end

      def on_gts_my_listings(msg)
        @is_loading = false
        json_parser = (defined?(PEMK::HousingJSON) ? PEMK::HousingJSON : (defined?(HousingJSON) ? HousingJSON : nil))
        mine = begin json_parser ? json_parser.parse(msg[:my_listings_json], symbolize_names: true) : [] rescue [] end
        clms = begin json_parser ? json_parser.parse(msg[:claims_json], symbolize_names: true) : [] rescue [] end
        if defined?($PokemonGlobal) && $PokemonGlobal
          $PokemonGlobal.gts_my_listings = mine || []
          $PokemonGlobal.gts_claims = clms || []
        else
          @my_listings = mine || []
          @pending_claim = clms || []
        end
        GTSMenu.on_data_received if defined?(GTSMenu) && GTSMenu.active?
      end

      def on_gts_action_result(msg)
        @is_loading = false
        if msg[:success]
          pbMessage(_INTL("GTS : {1}", msg[:message] || "Opération réussie !")) if defined?(pbMessage)
          send_fetch_my_listings
        else
          pbMessage(_INTL("Erreur GTS : {1}", msg[:message] || "Action impossible.")) if defined?(pbMessage)
        end
        GTSMenu.on_data_received if defined?(GTSMenu) && GTSMenu.active?
      end
    end
  end
end

