#===============================================================================
# PEMK_Housing :: 002 Net
#-------------------------------------------------------------------------------
# Network send helpers + state holder for pending server replies.
# All outbound messages use PEMK.client.send_message (same as Chat, Trade).
# Uses PEMK::HousingJSON parser (standalone, pure-Ruby, no stdlib json dependency).
#===============================================================================
module PEMK
  module Housing
    # ---- State (reset on disconnect / re-enter) ----
    @state       = nil   # last house_state received from server
    @catalog     = nil   # array of catalog hashes
    @pending     = {}    # :op => callback

    class << self
      attr_reader :state, :catalog

      def reset
        @state   = nil
        @catalog = nil
        @pending = {}
      end

      def connected?
        c = PEMK.client
        c && c.respond_to?(:connected?) && c.connected?
      end

      # ---- Outbound frames ----
      def send_enter
        PEMK.client.send_message(type: :house_enter)
      end

      def send_catalog
        PEMK.client.send_message(type: :house_catalog)
      end

      def send_buy(catalog_id, qty)
        PEMK.client.send_message(type: :house_buy, catalog_id: catalog_id, qty: qty)
      end

      def send_place(uid, x, y, rot)
        return unless @state
        PEMK.client.send_message(type: :house_place, furniture_uid: uid,
                                  x: x, y: y, rot: rot, base_version: @state[:version])
      end

      def send_move(uid, x, y, rot)
        return unless @state
        PEMK.client.send_message(type: :house_move, furniture_uid: uid,
                                  x: x, y: y, rot: rot, base_version: @state[:version])
      end

      def send_remove(uid)
        return unless @state
        PEMK.client.send_message(type: :house_remove, furniture_uid: uid,
                                  base_version: @state[:version])
      end

      # ---- Inbound message handlers (called from Dispatch) ----
      def on_house_state(msg)
        placed = begin HousingJSON.parse(msg[:placed_json], symbolize_names: true) || [] rescue [] end
        inv    = begin HousingJSON.parse(msg[:inventory_json], symbolize_names: true) || [] rescue [] end

        # Auto-request catalog if not fetched yet
        send_catalog if @catalog.nil? || @catalog.empty?

        [placed, inv].each do |list|
          list.each do |i|
            i[:name] = furniture_name(i) if i[:name].nil? || i[:name].to_s.strip.empty?
          end
        end

        appearance  = begin HousingJSON.parse(msg[:appearance_json], symbolize_names: false) || {} rescue {} end
        floor_tiles = appearance["floor_tiles"] || (@state ? @state[:floor_tiles] : {}) || {}

        @state = {
          house_id:    msg[:house_id],
          name:        msg[:name],
          size_tier:   msg[:size_tier],
          visibility:  msg[:visibility],
          version:     msg[:version],
          grid_w:      msg[:grid_w],
          grid_h:      msg[:grid_h],
          placed:      placed,
          inventory:   inv,
          appearance:  appearance,
          floor_tiles: floor_tiles
        }
        HousingRenderer.refresh if defined?(HousingRenderer)
        HousingEditor.on_state_refreshed if defined?(HousingEditor) && HousingEditor.active?
      end

      def send_floor_paint(floor_tiles)
        return unless @state
        if connected?
          PEMK.client.send_message(type: :house_floor_paint, floor_tiles_json: HousingJSON.generate(floor_tiles), base_version: @state[:version])
        end
      end

      def on_house_catalog_ok(msg)
        @catalog = begin HousingJSON.parse(msg[:catalog_json], symbolize_names: true) || [] rescue [] end
        if @state
          [@state[:placed], @state[:inventory]].compact.each do |list|
            list.each do |i|
              if i[:name].nil? || i[:name].to_s.strip.empty?
                i[:name] = furniture_name(i)
              end
            end
          end
        end
        HousingShop.on_catalog_received if defined?(HousingShop) && HousingShop.waiting?
      end

      def on_house_buy_ok(msg)
        # Update inventory: add new uids from server
        new_uids = begin HousingJSON.parse(msg[:uids_json]) || [] rescue [] end
        HousingShop.on_buy_ok(new_uids) if defined?(HousingShop)
        # Refresh state from server (version changed)
        send_enter
      end

      def on_house_place_ok(msg)
        # Optimistic update: move piece from inventory to placed in local state
        if @state
          uid = msg[:furniture_uid]
          item = @state[:inventory].find { |i| i[:uid] == uid }
          if item
            @state[:inventory].delete(item)
            @state[:placed] << item.merge(x: msg[:x], y: msg[:y], rot: msg[:rot])
          end
          @state[:version] = msg[:version]
        end
        HousingRenderer.refresh if defined?(HousingRenderer)
        HousingEditor.on_place_ok(msg) if defined?(HousingEditor)
      end

      def on_house_move_ok(msg)
        if @state
          uid = msg[:furniture_uid]
          p = @state[:placed].find { |i| i[:uid] == uid }
          if p
            p[:x] = msg[:x]; p[:y] = msg[:y]; p[:rot] = msg[:rot]
          end
          @state[:version] = msg[:version]
        end
        HousingRenderer.refresh if defined?(HousingRenderer)
        HousingEditor.on_move_ok(msg) if defined?(HousingEditor)
      end

      def on_house_remove_ok(msg)
        if @state
          uid = msg[:furniture_uid]
          removed = @state[:placed].find { |i| i[:uid] == uid }
          if removed
            @state[:placed].delete(removed)
            inv_item = removed.reject { |k, _| [:x, :y, :rot].include?(k) }
            if (inv_item[:name].nil? || inv_item[:name].to_s.strip.empty?) && @catalog
              c_match = @catalog.find { |c| c[:id] == inv_item[:catalog_id] || c[:key] == inv_item[:key] }
              inv_item[:name] = c_match[:name] if c_match
            end
            @state[:inventory] << inv_item
          end
          @state[:version] = msg[:version]
        end
        HousingRenderer.refresh if defined?(HousingRenderer)
        HousingEditor.on_remove_ok(msg) if defined?(HousingEditor)
      end

      def on_house_error(msg)
        PEMK.log("housing: server error code=#{msg[:code]} req=#{msg[:req]}")
        HousingEditor.on_error(msg) if defined?(HousingEditor) && HousingEditor.active?
        HousingShop.on_error(msg)   if defined?(HousingShop)   && HousingShop.waiting?
      end
    end
  end
end

