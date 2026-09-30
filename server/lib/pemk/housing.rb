# frozen_string_literal: true

require "json"
require "securerandom"

module PEMK
  # Server-authoritative player housing — Phase A.
  #
  # All public methods are designed to run INSIDE the per-player mailbox
  # (@mailbox.submit(account_id) { ... }) and return a result that the caller
  # posts back to the reactor thread via @reactor.post { reply(...) }.
  #
  # Security model (matching trades.rb / monsters.rb):
  #  - character_id is resolved from account_id by the caller (never trusted
  #    from the client).
  #  - Every placement mutation takes a FOR UPDATE lock on the house row and
  #    checks base_version == houses.version, rolling back on mismatch.
  #  - Money flows through Ledger#adjust (append-only economy_ledger).
  #  - uid is server-generated ("f_" + SecureRandom.hex(8)), never client-supplied.
  #
  # Grid constants (tuiles 32 px, même convention que le plugin client) :
  HOUSE_GRID = {
    1 => { w: 11, h: 7 },   # S – Petite (11x7)
    2 => { w: 12, h: 9 },   # M – Moyenne
    3 => { w: 16, h: 12 },   # L – Grande
    4 => { w: 16, h: 12 },   # XL – Étage (même grille, étage géré côté client)
  }.freeze

  # Tile inside the grid reserved for the entry warp — always kept passable.
  HOUSE_ENTRY_X = 3
  HOUSE_ENTRY_Y = 6

  MAX_PLACED    = 150
  MAX_OWNED     = 300
  MAX_BUY_QTY   = 10

  class Housing
    def initialize(db, ledger, logger: nil)
      @db     = db
      @ledger = ledger
      @log    = logger || ->(_m) {}
    end

    # ----------------------------------------------------------------- enter --
    # Returns { house:, placed:, inventory:, version:, grid_w:, grid_h: } or
    # [:error, code, detail].
    # Creates the house row on first visit (INSERT ... ON CONFLICT DO NOTHING).
    def enter(character_id)
      # Upsert the house — one per character, auto-created on first touch.
      @db[:houses].insert_conflict(target: :owner_character_id).insert(
        owner_character_id: character_id,
        name:               "Maison",
        size_tier:          1,
        visibility:         "private",
        version:            0,
        created_at:         Sequel::CURRENT_TIMESTAMP,
        updated_at:         Sequel::CURRENT_TIMESTAMP
      )
      house = @db[:houses].where(owner_character_id: character_id).first
      return [:error, "NOT_FOUND", "house missing after upsert"] unless house

      snapshot(house, character_id)
    rescue StandardError => e
      @log.call("housing: enter failed for char #{character_id}: #{e.class}: #{e.message}")
      [:error, "NOT_FOUND", e.message]
    end

    # --------------------------------------------------------------- catalog --
    # Returns the full furniture catalog as an array of hashes.
    def catalog
      ds = @db[:furniture_catalog]
      ds = ds.where(enabled: true) if ds.columns.include?(:enabled)
      ds.order(:category, :price).map do |row|
        { id: row[:id], key: row[:key], name: row[:name],
          category: row[:category],
          footprint_w: row[:footprint_w], footprint_h: row[:footprint_h],
          blocking: row[:blocking], price: row[:price],
          currency: row[:currency], min_tier: row[:min_tier],
          rotatable: row[:rotatable] || false,
          sprite: row[:sprite],
          image_w: row[:image_w] || 32,
          image_h: row[:image_h] || 32,
          interactive_type: row[:interactive_type] }
      end
    end

    # ------------------------------------------------------------------- buy --
    # account_id required for ledger (economy is per-account).
    # Returns [:ok, new_balance, [uid, ...]] or [:error, code, detail].
    def buy(character_id, account_id, catalog_id, qty)
      unless qty.is_a?(Integer) && qty.between?(1, MAX_BUY_QTY)
        return [:error, "INVALID_INPUT", "qty must be 1..#{MAX_BUY_QTY}"]
      end

      item = @db[:furniture_catalog].where(id: catalog_id).first
      return [:error, "NOT_FOUND", "catalog_id #{catalog_id} unknown"] unless item

      total_cost = item[:price] * qty
      new_uids   = Array.new(qty) { "f_#{SecureRandom.hex(8)}" }
      new_balance = nil

      @db.transaction do
        # Deduct money through the ledger (append-only, atomic, auditable).
        st, val_or_cur, reason = @ledger.adjust(account_id, :money, -total_cost,
                                                 reason: "house_buy_furniture")
        case st
        when :rej
          raise Sequel::Rollback # propagates -> :error below
        when :ack
          new_balance = val_or_cur
        end

        # Check total owned cap.
        owned_count = @db[:furniture_owned]
                        .where(owner_character_id: character_id).count
        if owned_count + qty > MAX_OWNED
          @log.call("housing: char #{character_id} LIMIT_REACHED owned=#{owned_count}+#{qty}>#{MAX_OWNED}")
          raise Sequel::Rollback
        end

        now = Time.now
        new_uids.each do |uid|
          @db[:furniture_owned].insert(
            uid: uid, owner_character_id: character_id,
            catalog_id: catalog_id,
            created_at: now, updated_at: now
          )
        end
      end

      if new_balance.nil?
        @log.call("housing: buy INSUFFICIENT_FUNDS char #{character_id} needs #{total_cost}")
        return [:error, "INSUFFICIENT_FUNDS", "need #{total_cost}"]
      end

      @log.call("housing: char #{character_id} bought #{qty}x #{item[:key]} for #{total_cost} (bal=#{new_balance})")
      [:ok, new_balance, new_uids]
    rescue StandardError => e
      @log.call("housing: buy failed char #{character_id}: #{e.class}: #{e.message}")
      [:error, "INSUFFICIENT_FUNDS", e.message]
    end

    # ----------------------------------------------------------------- place --
    def place(character_id, furniture_uid, x, y, rot, base_version)
      mutate(character_id, furniture_uid, base_version, :place) do |house, item|
        grid = HOUSE_GRID[house[:size_tier]]
        fw, fh = effective_footprint(item[:footprint_w], item[:footprint_h], rot)

        unless position_valid?(x, y, fw, fh, grid[:w], grid[:h])
          next [:error, "INVALID_POSITION", "out of grid"]
        end
        if entry_blocked?(x, y, fw, fh)
          next [:error, "INVALID_POSITION", "entry tile must stay free"]
        end

        placed = placed_furniture(house[:id])
        if placed.count >= MAX_PLACED
          next [:error, "LIMIT_REACHED", "max #{MAX_PLACED} placed"]
        end
        if collides?(item, x, y, rot, placed, exclude_uid: furniture_uid)
          next [:error, "COLLISION", "overlaps existing furniture"]
        end

        now = Time.now
        @db[:furniture_owned]
          .where(uid: furniture_uid, owner_character_id: character_id)
          .update(placed_in_house_id: house[:id], x: x, y: y, rot: rot, updated_at: now)
        :ok
      end
    end

    # ------------------------------------------------------------------ move --
    def move(character_id, furniture_uid, x, y, rot, base_version)
      mutate(character_id, furniture_uid, base_version, :move) do |house, item|
        grid = HOUSE_GRID[house[:size_tier]]
        fw, fh = effective_footprint(item[:footprint_w], item[:footprint_h], rot)

        unless position_valid?(x, y, fw, fh, grid[:w], grid[:h])
          next [:error, "INVALID_POSITION", "out of grid"]
        end
        if entry_blocked?(x, y, fw, fh)
          next [:error, "INVALID_POSITION", "entry tile must stay free"]
        end

        placed = placed_furniture(house[:id])
        if collides?(item, x, y, rot, placed, exclude_uid: furniture_uid)
          next [:error, "COLLISION", "overlaps existing furniture"]
        end

        now = Time.now
        @db[:furniture_owned]
          .where(uid: furniture_uid, owner_character_id: character_id)
          .update(x: x, y: y, rot: rot, updated_at: now)
        :ok
      end
    end

    # ----------------------------------------------------------- floor_paint --
    def floor_paint(character_id, floor_tiles_json, base_version)
      result = nil
      @db.transaction do
        house = @db[:houses]
                  .where(owner_character_id: character_id)
                  .for_update.first
        unless house
          result = [:error, "NOT_FOUND", "house not found for char #{character_id}"]
          raise Sequel::Rollback
        end

        unless base_version == house[:version]
          @log.call("housing: floor_paint VERSION_CONFLICT char #{character_id} base=#{base_version} actual=#{house[:version]}")
          result = [:error, "VERSION_CONFLICT", "expected #{house[:version]}"]
          raise Sequel::Rollback
        end

        parsed_tiles = begin JSON.parse(floor_tiles_json.to_s) rescue {} end
        appearance = begin JSON.parse(house[:appearance_json].to_s) rescue {} end
        appearance["floor_tiles"] = parsed_tiles

        now = Time.now
        @db[:houses].where(id: house[:id]).update(
          appearance_json: JSON.generate(appearance),
          version: Sequel[:version] + 1,
          updated_at: now
        )

        new_version = house[:version] + 1
        result = [:ok, new_version]
      end

      result
    rescue StandardError => e
      @log.call("housing: floor_paint failed char #{character_id}: #{e.class}: #{e.message}")
      result || [:error, "NOT_FOUND", e.message]
    end

    private

    # ---------------------------------------------------------- core mutator --
    # Locks the house row FOR UPDATE, checks base_version, validates ownership,
    # yields to the block with (house_row, catalog_row), increments version on
    # success, rolls back on :error.
    # Returns [:ok, new_version] or [:error, code, detail].
    def mutate(character_id, furniture_uid, base_version, op)
      result = nil

      @db.transaction do
        # Resolve character's own house.
        house = @db[:houses]
                  .where(owner_character_id: character_id)
                  .for_update.first
        unless house
          result = [:error, "NOT_FOUND", "house not found for char #{character_id}"]
          raise Sequel::Rollback
        end

        unless base_version == house[:version]
          @log.call("housing: #{op} VERSION_CONFLICT char #{character_id} " \
                    "base=#{base_version} actual=#{house[:version]}")
          result = [:error, "VERSION_CONFLICT", "expected #{house[:version]}"]
          raise Sequel::Rollback
        end

        # Ownership check.
        fo = @db[:furniture_owned]
               .where(uid: furniture_uid, owner_character_id: character_id)
               .first
        unless fo
          @log.call("housing: #{op} NOT_ALLOWED char #{character_id} uid #{furniture_uid}")
          result = [:error, "NOT_ALLOWED", "furniture not owned"]
          raise Sequel::Rollback
        end

        # For place/move: must either be unplaced or placed in THIS house.
        if %i[place move].include?(op) && fo[:placed_in_house_id] && fo[:placed_in_house_id] != house[:id]
          result = [:error, "NOT_ALLOWED", "furniture is in another house"]
          raise Sequel::Rollback
        end

        catalog_item = @db[:furniture_catalog].where(id: fo[:catalog_id]).first
        unless catalog_item
          result = [:error, "NOT_FOUND", "catalog item missing"]
          raise Sequel::Rollback
        end

        # Delegate to block.
        block_result = yield(house, catalog_item)

        if block_result.is_a?(Array) && block_result.first == :error
          result = block_result
          @log.call("housing: #{op} #{block_result[1]} char #{character_id} uid #{furniture_uid}: #{block_result[2]}")
          raise Sequel::Rollback
        end

        # Increment version.
        @db[:houses]
          .where(id: house[:id])
          .update(version: Sequel[:version] + 1, updated_at: Time.now)

        new_version = house[:version] + 1
        result = [:ok, new_version]
      end

      result
    rescue StandardError => e
      @log.call("housing: mutate (#{op}) raised #{e.class}: #{e.message}")
      result || [:error, "NOT_FOUND", e.message]
    end

    # ---------------------------------------------------------------- helpers --
    def snapshot(house, character_id)
      placed = placed_furniture(house[:id])
      inventory = @db[:furniture_owned]
                    .join(:furniture_catalog, id: :catalog_id)
                    .where(Sequel.qualify(:furniture_owned, :owner_character_id) => character_id,
                           placed_in_house_id: nil)
                    .select(
                      Sequel.qualify(:furniture_owned, :uid),
                      Sequel.qualify(:furniture_catalog, :id).as(:catalog_id),
                      Sequel.qualify(:furniture_catalog, :key),
                      Sequel.qualify(:furniture_catalog, :name),
                      Sequel.qualify(:furniture_catalog, :category),
                      Sequel.qualify(:furniture_catalog, :footprint_w),
                      Sequel.qualify(:furniture_catalog, :footprint_h),
                      Sequel.qualify(:furniture_catalog, :blocking),
                      Sequel.qualify(:furniture_catalog, :rotatable),
                      Sequel.qualify(:furniture_catalog, :sprite),
                      Sequel.qualify(:furniture_catalog, :image_w),
                      Sequel.qualify(:furniture_catalog, :image_h),
                      Sequel.qualify(:furniture_catalog, :interactive_type)
                    )
                    .map { |r| r }
      grid = HOUSE_GRID[house[:size_tier]]
      { house: house, placed: placed, inventory: inventory,
        version: house[:version], grid_w: grid[:w], grid_h: grid[:h] }
    end

    def placed_furniture(house_id)
      @db[:furniture_owned]
        .join(:furniture_catalog, id: :catalog_id)
        .where(placed_in_house_id: house_id)
        .select(
          Sequel.qualify(:furniture_owned, :uid),
          Sequel.qualify(:furniture_owned, :x),
          Sequel.qualify(:furniture_owned, :y),
          Sequel.qualify(:furniture_owned, :rot),
          Sequel.qualify(:furniture_catalog, :id).as(:catalog_id),
          Sequel.qualify(:furniture_catalog, :key),
          Sequel.qualify(:furniture_catalog, :name),
          Sequel.qualify(:furniture_catalog, :category),
          Sequel.qualify(:furniture_catalog, :footprint_w),
          Sequel.qualify(:furniture_catalog, :footprint_h),
          Sequel.qualify(:furniture_catalog, :blocking),
          Sequel.qualify(:furniture_catalog, :rotatable),
          Sequel.qualify(:furniture_catalog, :sprite),
          Sequel.qualify(:furniture_catalog, :image_w),
          Sequel.qualify(:furniture_catalog, :image_h),
          Sequel.qualify(:furniture_catalog, :interactive_type)
        )
        .map { |r| r }
    end

    def effective_footprint(w, h, rot)
      (rot == 90 || rot == 270) ? [h, w] : [w, h]
    end

    def position_valid?(x, y, fw, fh, grid_w, grid_h)
      x >= 0 && y >= 0 && x + fw <= grid_w && y + fh <= grid_h
    end

    # The entry tile (HOUSE_ENTRY_X, HOUSE_ENTRY_Y) must never be covered.
    def entry_blocked?(x, y, fw, fh)
      ex, ey = HOUSE_ENTRY_X, HOUSE_ENTRY_Y
      ex >= x && ex < x + fw && ey >= y && ey < y + fh
    end

    # Collision detection with two layers:
    #  - "floor" category only collides with other "floor"
    #  - everything else ("solid") collides with other solid
    # +exclude_uid+ skips the piece being moved/placed (itself).
    def collides?(new_item, nx, ny, nrot, placed, exclude_uid: nil)
      nfw, nfh = effective_footprint(new_item[:footprint_w], new_item[:footprint_h], nrot)
      new_layer = new_item[:category] == "floor" ? :floor : :solid

      placed.each do |p|
        next if p[:uid] == exclude_uid

        other_layer = p[:category] == "floor" ? :floor : :solid
        next if new_layer != other_layer   # different layers never collide

        ofw, ofh = effective_footprint(p[:footprint_w], p[:footprint_h], p[:rot].to_i)
        # AABB overlap
        next if nx + nfw <= p[:x] || p[:x] + ofw <= nx
        next if ny + nfh <= p[:y] || p[:y] + ofh <= ny

        return true
      end
      false
    end
  end
end

