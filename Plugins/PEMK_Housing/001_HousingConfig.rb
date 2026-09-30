#===============================================================================
# PEMK_Housing :: 001 Config
#-------------------------------------------------------------------------------
# Constants for the housing system.
# Tier 1 (Petite maison):
#   - Model Map ID: 927
#   - Grid origin: (1, 3) on the map (columns 1..8, lines 3..7 -> 8x5 grid)
#   - Arrival spawn: map (3, 7) -> grid (2, 4)
#   - Exit door mat threshold: line y=8, columns x=2..4
#===============================================================================
module PEMK
  module Housing
    # ---- Map IDs ----
    HOUSE_MAP_S  = 927  # Maison Joueur Modèle (dupliquée)
    HOUSE_MAP_M  = 927
    HOUSE_MAP_L  = 927
    HOUSE_MAP_XL = 927

    MAP_FOR_TIER = { 1 => HOUSE_MAP_S, 2 => HOUSE_MAP_M,
                     3 => HOUSE_MAP_L, 4 => HOUSE_MAP_XL }.freeze

    # Grid origin within the model map (tile offset from top-left corner)
    GRID_ORIGIN_X = 0
    GRID_ORIGIN_Y = 2

    # Entry tile within the grid per tier (0-indexed, matches server HOUSE_ENTRY)
    ENTRY_GRID = {
      1 => [3, 6],    # S (11x7): map (3, 8) with origin (0, 2) -> grid (3, 6)
      2 => [6, 8],    # M (12x9)
      3 => [8, 11],   # L (16x12)
      4 => [8, 11],   # XL (16x12)
    }.freeze

    # Helper method for entry tile
    def self.entry_grid_for(tier)
      ENTRY_GRID.fetch(tier, [3, 6])
    end

    # Helper method to resolve furniture name gracefully
    def self.furniture_name(item)
      return "" unless item
      name = item[:name] || item["name"]
      if name && !name.to_s.strip.empty?
        return name.to_s
      end

      cat = @catalog || []
      if !cat.empty?
        cat_id = item[:catalog_id] || item["catalog_id"]
        key = item[:key] || item["key"]
        c_match = cat.find { |c| (cat_id && c[:id] == cat_id) || (key && c[:key] == key) }
        if c_match && c_match[:name] && !c_match[:name].to_s.strip.empty?
          return c_match[:name].to_s
        end
      end

      key = item[:key] || item["key"]
      if key && !key.to_s.strip.empty?
        return key.to_s.tr("_", " ").capitalize
      end

      "Meuble"
    end

    # Exit door mat tiles on the map (y=9, x=2..4 for Tier 1)
    EXIT_TILES = {
      1 => { y: 9, x_range: (2..4) }
    }.freeze

    # NPC hotel receptionist map / event ID (Map 33 = Littleroot Town)
    HOTEL_NPC_MAP   = 33
    HOTEL_NPC_SPAWN = [33, 12, 16, 2].freeze   # [map_id, x, y, direction] in front of hotel receptionist
    HOTEL_NPC_EVENTS = [1].freeze              # Event ID(s) of the receptionist NPC

    TILE_SIZE = 32  # pixels per tile

    # Grid sizes per tier (matches server HOUSE_GRID)
    GRID_SIZES = {
      1 => [11, 7], 2 => [12, 9], 3 => [16, 12], 4 => [16, 12]
    }.freeze

    # Furniture sprite directory (Graphics/Pictures/Housing/)
    SPRITE_DIR = "Housing/"

    # ---- Floor Painting Styles & Helpers ----
    FLOOR_STYLES = [
      { id: 0,  name: "Par défaut (Carte)" },
      { id: 1,  name: "Parquet Clair" },
      { id: 2,  name: "Parquet Sombre" },
      { id: 3,  name: "Moquette Bleue" },
      { id: 4,  name: "Moquette Rouge" },
      { id: 5,  name: "Carrelage Blanc" },
      { id: 6,  name: "Carrelage Damier" },
      { id: 7,  name: "Tatami Paille" },
      { id: 8,  name: "Pavé de Pierre" },
      { id: 9,  name: "Moquette Violette" },
      { id: 10, name: "Gazon Synthétique" },
    ].freeze

    def self.floor_styles; FLOOR_STYLES; end

    def self.get_floor_tile(gx, gy)
      return 0 unless @state && @state[:floor_tiles]
      @state[:floor_tiles]["#{gx},#{gy}"].to_i
    end

    def self.set_floor_tile(gx, gy, style_id)
      return unless @state
      @state[:floor_tiles] ||= {}
      if style_id.to_i == 0
        @state[:floor_tiles].delete("#{gx},#{gy}")
      else
        @state[:floor_tiles]["#{gx},#{gy}"] = style_id.to_i
      end
    end

    def self.fill_floor(style_id)
      return unless @state
      @state[:floor_tiles] ||= {}
      gw = @state[:grid_w] || 11
      gh = @state[:grid_h] || 7
      gh.times do |j|
        gw.times do |i|
          if style_id.to_i == 0
            @state[:floor_tiles].delete("#{i},#{j}")
          else
            @state[:floor_tiles]["#{i},#{j}"] = style_id.to_i
          end
        end
      end
    end

    def self.build_floor_tile_bitmap(style_id)
      bm = Bitmap.new(32, 32)
      case style_id.to_i
      when 1 # Parquet Clair
        bm.fill_rect(0, 0, 32, 32, Color.new(218, 178, 128))
        bm.fill_rect(0, 0, 32, 1, Color.new(180, 140, 95))
        bm.fill_rect(0, 8, 32, 1, Color.new(180, 140, 95))
        bm.fill_rect(0, 16, 32, 1, Color.new(180, 140, 95))
        bm.fill_rect(0, 24, 32, 1, Color.new(180, 140, 95))
        bm.fill_rect(12, 0, 1, 8, Color.new(180, 140, 95))
        bm.fill_rect(24, 8, 1, 8, Color.new(180, 140, 95))
        bm.fill_rect(6, 16, 1, 8, Color.new(180, 140, 95))
        bm.fill_rect(18, 24, 1, 8, Color.new(180, 140, 95))
        bm.fill_rect(2, 3, 20, 1, Color.new(230, 192, 142))
        bm.fill_rect(10, 11, 18, 1, Color.new(230, 192, 142))

      when 2 # Parquet Sombre
        bm.fill_rect(0, 0, 32, 32, Color.new(90, 55, 35))
        bm.fill_rect(0, 0, 32, 1, Color.new(60, 35, 20))
        bm.fill_rect(0, 8, 32, 1, Color.new(60, 35, 20))
        bm.fill_rect(0, 16, 32, 1, Color.new(60, 35, 20))
        bm.fill_rect(0, 24, 32, 1, Color.new(60, 35, 20))
        bm.fill_rect(16, 0, 1, 8, Color.new(60, 35, 20))
        bm.fill_rect(8, 8, 1, 8, Color.new(60, 35, 20))
        bm.fill_rect(22, 16, 1, 8, Color.new(60, 35, 20))
        bm.fill_rect(12, 24, 1, 8, Color.new(60, 35, 20))

      when 3 # Moquette Bleue
        bm.fill_rect(0, 0, 32, 32, Color.new(50, 90, 170))
        bm.fill_rect(1, 1, 30, 30, Color.new(65, 110, 195))
        4.times do |i|
          4.times do |j|
            bm.fill_rect(i * 8 + 2, j * 8 + 2, 2, 2, Color.new(80, 125, 215))
          end
        end

      when 4 # Moquette Rouge
        bm.fill_rect(0, 0, 32, 32, Color.new(160, 40, 50))
        bm.fill_rect(1, 1, 30, 30, Color.new(190, 55, 68))
        4.times do |i|
          4.times do |j|
            bm.fill_rect(i * 8 + 2, j * 8 + 2, 2, 2, Color.new(210, 70, 85))
          end
        end

      when 5 # Carrelage Blanc
        bm.fill_rect(0, 0, 32, 32, Color.new(200, 205, 215))
        bm.fill_rect(1, 1, 14, 14, Color.new(245, 248, 252))
        bm.fill_rect(17, 1, 14, 14, Color.new(245, 248, 252))
        bm.fill_rect(1, 17, 14, 14, Color.new(245, 248, 252))
        bm.fill_rect(17, 17, 14, 14, Color.new(245, 248, 252))

      when 6 # Carrelage Damier
        bm.fill_rect(0, 0, 32, 32, Color.new(30, 35, 45))
        bm.fill_rect(0, 0, 16, 16, Color.new(240, 240, 245))
        bm.fill_rect(16, 16, 16, 16, Color.new(240, 240, 245))

      when 7 # Tatami Paille
        bm.fill_rect(0, 0, 32, 32, Color.new(195, 180, 120))
        bm.fill_rect(0, 0, 32, 2, Color.new(50, 100, 60))
        bm.fill_rect(0, 30, 32, 2, Color.new(50, 100, 60))
        15.times { |k| bm.fill_rect(0, 2 + k * 2, 32, 1, Color.new(215, 200, 135)) }

      when 8 # Pavé de Pierre
        bm.fill_rect(0, 0, 32, 32, Color.new(90, 95, 105))
        bm.fill_rect(1, 1, 14, 14, Color.new(130, 135, 145))
        bm.fill_rect(17, 1, 14, 14, Color.new(115, 120, 130))
        bm.fill_rect(1, 17, 14, 14, Color.new(120, 125, 135))
        bm.fill_rect(17, 17, 14, 14, Color.new(140, 145, 155))

      when 9 # Moquette Violette
        bm.fill_rect(0, 0, 32, 32, Color.new(120, 60, 150))
        bm.fill_rect(1, 1, 30, 30, Color.new(145, 75, 180))
        4.times do |i|
          4.times do |j|
            bm.fill_rect(i * 8 + 2, j * 8 + 2, 2, 2, Color.new(165, 95, 200))
          end
        end

      when 10 # Gazon Synthétique
        bm.fill_rect(0, 0, 32, 32, Color.new(75, 160, 60))
        8.times do |n|
          rx = (n * 7 + 3) % 28
          ry = (n * 11 + 5) % 28
          bm.fill_rect(rx, ry, 2, 3, Color.new(105, 195, 80))
        end
        bm.fill_rect(12, 14, 2, 2, Color.new(255, 220, 60))
        bm.fill_rect(24, 22, 2, 2, Color.new(255, 255, 255))
      end
      bm
    end

    # Fallback sprite drawn when a PNG is absent: coloured 32x32 blocks by category
    CATEGORY_COLORS = {
      "functional" => Color.new(80,  140, 200),
      "decor"      => Color.new(200, 160,  80),
      "wall"       => Color.new(120, 120, 120),
      "floor"      => Color.new(180, 200, 100),
      "partition"  => Color.new(160, 110,  60),
    }.freeze
    DEFAULT_COLOR = Color.new(200, 200, 200)

    # Check if a map ID belongs to the housing system
    def self.is_house_map?(map_id)
      MAP_FOR_TIER.values.include?(map_id)
    end

    # ---- Coordinate conversion helpers ----
    def self.grid_to_map(gx, gy)
      [GRID_ORIGIN_X + gx.to_i, GRID_ORIGIN_Y + gy.to_i]
    end

    def self.grid_to_screen(gx, gy)
      mx, my = grid_to_map(gx, gy)
      dx = $game_map ? ($game_map.display_x / 4) : 0
      dy = $game_map ? ($game_map.display_y / 4) : 0
      [(mx * TILE_SIZE) - dx, (my * TILE_SIZE) - dy]
    end

    def self.screen_to_grid(sx, sy)
      dx = $game_map ? ($game_map.display_x / 4) : 0
      dy = $game_map ? ($game_map.display_y / 4) : 0
      mx = ((sx + dx) / TILE_SIZE).to_i
      my = ((sy + dy) / TILE_SIZE).to_i
      [mx - GRID_ORIGIN_X, my - GRID_ORIGIN_Y]
    end

    # Apply pivot and angle for rotated furniture sprite to keep top-left corner anchored
    def self.apply_sprite_rotation(sprite, rot, bitmap_w, bitmap_h)
      return unless sprite && !sprite.disposed?
      case rot.to_i % 360
      when 0
        sprite.ox = 0; sprite.oy = 0; sprite.angle = 0
      when 90
        sprite.ox = 0; sprite.oy = bitmap_h; sprite.angle = 90
      when 180
        sprite.ox = bitmap_w; sprite.oy = bitmap_h; sprite.angle = 180
      when 270
        sprite.ox = bitmap_w; sprite.oy = 0; sprite.angle = 270
      end
    end
  end
end

