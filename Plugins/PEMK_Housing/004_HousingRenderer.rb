#===============================================================================
# PEMK_Housing :: 004 Renderer
#-------------------------------------------------------------------------------
# Draws furniture sprites on the house interior map.
# Uses Sprite objects positioned according to the layout received from the server.
# Rock-solid map viewport anchoring, exact dynamic Z-sorting, carpet passthrough.
#===============================================================================
module PEMK
  module HousingRenderer
    @sprites = []   # Array of [sprite, piece_hash]
    @active  = false

    class << self
      def active?
        if @active && $game_map && !Housing.is_house_map?($game_map.map_id)
          dispose
          return false
        end
        @active
      end

      # Called when the player teleports into their house (from Menu#enter_house).
      def setup
        unless $game_map && Housing.is_house_map?($game_map.map_id)
          dispose
          return
        end
        dispose_all
        @active = true
        refresh
      end

      def dispose
        dispose_all
        @active = false
      end

      # Rebuild all sprites & passability from current Housing state.
      def refresh
        unless $game_map && Housing.is_house_map?($game_map.map_id)
          dispose
          return
        end
        return unless @active && Housing.state
        dispose_all
        refresh_floor_sprite
        placed = Housing.state[:placed] || []
        placed.each { |p| add_furniture_sprite(p) }
        rebuild_passability
        update_sprite_positions
      end


      def refresh_floor_sprite
        @floor_sprite&.bitmap&.dispose
        @floor_sprite&.dispose unless @floor_sprite&.disposed?
        @floor_sprite = nil

        return unless Housing.state
        gw = Housing.state[:grid_w] || 11
        gh = Housing.state[:grid_h] || 7
        ts = Housing::TILE_SIZE

        bm = Bitmap.new(gw * ts, gh * ts)
        has_tiles = false

        gh.times do |j|
          gw.times do |i|
            style_id = Housing.get_floor_tile(i, j)
            next if style_id <= 0
            tile_bm = Housing.build_floor_tile_bitmap(style_id)
            bm.blt(i * ts, j * ts, tile_bm, Rect.new(0, 0, ts, ts))
            tile_bm.dispose
            has_tiles = true
          end
        end

        if has_tiles
          vp = get_map_viewport
          @floor_sprite = vp ? Sprite.new(vp) : Sprite.new
          @floor_sprite.bitmap = bm
          disp_x = ($game_map.display_x / 4.0).round rescue 0
          disp_y = ($game_map.display_y / 4.0).round rescue 0
          @floor_sprite.x = (Housing::GRID_ORIGIN_X * Housing::TILE_SIZE) - disp_x
          @floor_sprite.y = (Housing::GRID_ORIGIN_Y * Housing::TILE_SIZE) - disp_y
          @floor_sprite.z = 0
        else
          bm.dispose
        end
      end

      # Helper to retrieve Map Viewport1 (handles viewport binding with character sprites)
      def get_map_viewport
        return nil unless defined?(Scene_Map) && $scene.is_a?(Scene_Map)

        ss = nil
        if $scene.respond_to?(:spriteset) && $scene.spriteset
          ss = $scene.spriteset
        end
        if ss.nil?
          [:spriteset, :spriteset_map].each do |m|
            if $scene.respond_to?(m)
              ss = $scene.send(m) rescue nil
              break if ss
            end
          end
        end
        if ss.nil?
          [:@spriteset, :@spriteset_map].each do |ivar|
            if $scene.instance_variable_defined?(ivar)
              ss = $scene.instance_variable_get(ivar) rescue nil
              break if ss
            end
          end
        end
        if ss.nil?
          $scene.instance_variables.each do |ivar|
            val = $scene.instance_variable_get(ivar) rescue nil
            if val && val.class.to_s.include?("Spriteset")
              ss = val
              break
            end
          end
        end

        vp = nil
        vp ||= (Spriteset_Map.viewport rescue nil) if defined?(Spriteset_Map)
        vp ||= (ss.viewport1 rescue nil) if ss
        vp ||= (ss.viewport rescue nil) if ss
        vp ||= (ss.instance_variable_get(:@viewport1) rescue nil) if ss
        vp ||= (ss.instance_variable_get(:@viewport) rescue nil) if ss
        vp ||= (Spriteset_Map.class_variable_get(:@@viewport1) rescue nil) if defined?(Spriteset_Map) && Spriteset_Map.class_variable_defined?(:@@viewport1)
        vp ||= (Spriteset_Map.class_variable_get(:@@viewport) rescue nil) if defined?(Spriteset_Map) && Spriteset_Map.class_variable_defined?(:@@viewport)

        if vp.nil? && ss
          ss.instance_variables.each do |ivar|
            val = ss.instance_variable_get(ivar) rescue nil
            if val.is_a?(Viewport) && !val.disposed?
              vp = val
              break
            end
          end
        end

        vp
      end

      # Update screen positions & dynamic depth Z of placed furniture when camera scrolls or player moves
      def update_sprite_positions
        unless $game_map && Housing.is_house_map?($game_map.map_id)
          dispose
          return
        end
        return unless @active
        vp = get_map_viewport
        sub_x = (defined?(Game_Map::X_SUBPIXELS) ? Game_Map::X_SUBPIXELS.to_f : 4.0)
        sub_y = (defined?(Game_Map::Y_SUBPIXELS) ? Game_Map::Y_SUBPIXELS.to_f : 4.0)
        disp_x_px = ($game_map ? ($game_map.display_x / sub_x).round : 0) rescue 0
        disp_y_px = ($game_map ? ($game_map.display_y / sub_y).round : 0) rescue 0

        if @floor_sprite && !@floor_sprite.disposed?
          if vp && @floor_sprite.viewport != vp
            @floor_sprite.viewport = vp
          end
          map_x = Housing::GRID_ORIGIN_X
          map_y = Housing::GRID_ORIGIN_Y
          @floor_sprite.x = (map_x * Housing::TILE_SIZE) - disp_x_px
          @floor_sprite.y = (map_y * Housing::TILE_SIZE) - disp_y_px
          @floor_sprite.z = 1
        end

        @sprites.each do |item|
          sprite, piece = item
          next if sprite.nil? || sprite.disposed?

          if vp && sprite.viewport != vp
            sprite.viewport = vp
          end

          rot = piece[:rot].to_i
          fw, fh = effective_footprint(piece[:footprint_w].to_i, piece[:footprint_h].to_i, rot)
          bmp_h = (sprite.bitmap && !sprite.bitmap.disposed?) ? sprite.bitmap.height : (fh * Housing::TILE_SIZE)
          img_h = piece[:image_h] ? piece[:image_h].to_i : bmp_h

          map_x = Housing::GRID_ORIGIN_X + piece[:x].to_i
          map_y = Housing::GRID_ORIGIN_Y + piece[:y].to_i

          sprite.x = (map_x * Housing::TILE_SIZE) - disp_x_px
          sprite.y = ((map_y + fh) * Housing::TILE_SIZE) - img_h - disp_y_px

          cat = piece[:category].to_s
          if cat == "floor"
            sprite.z = 2  # Rugs/carpets always under player and under solid furniture
          elsif cat == "wall"
            # Wall items remain behind characters walking in front of the wall
            sprite.z = (map_y * Housing::TILE_SIZE) - disp_y_px + 2
          else
            footprint_bottom_map_y = map_y + fh - 1
            # Essentials v20/v21 screen_z alignment:
            # player.screen_z = (py * 32) - disp_y_px + 32
            # Setting furniture Z to (footprint_bottom_map_y * 32) - disp_y_px + 33 ensures:
            # - Player standing South (py > footprint_bottom_map_y): player.screen_z >= +64 > furniture.z (+33) -> Player in FRONT
            # - Player standing at/behind base (py <= footprint_bottom_map_y): player.screen_z <= +32 < furniture.z (+33) -> Player BEHIND
            sprite.z = (footprint_bottom_map_y * Housing::TILE_SIZE) - disp_y_px + 33
          end
        end
        debug_z
      end

      # Debug inspector helper (appeler toutes les 60 frames dans update_sprite_positions)
      def debug_z
        return unless @active && $game_player && defined?(Scene_Map) && $scene.is_a?(Scene_Map)
        @dbg_tick = (@dbg_tick || 0) + 1
        return unless @dbg_tick % 60 == 0

        ss = ($scene.spriteset rescue nil)
        vp = get_map_viewport

        msg_env = "scene=#{$scene.class} ss=#{ss.class} ivars=#{ss ? ss.instance_variables.inspect : 'nil'} | " +
                  "Spriteset_Map cvars=#{defined?(Spriteset_Map) ? Spriteset_Map.class_variables.inspect : 'nil'} | " +
                  "vp=#{vp.inspect}"
        if defined?(echoln)
          echoln(msg_env) rescue nil
        else
          puts(msg_env) rescue nil
        end

        char_sprites = ss ? (ss.instance_variable_get(:@character_sprites) rescue nil) : nil
        psp = char_sprites ? char_sprites.find { |s| s.character.equal?($game_player) } : nil

        sub_y = (defined?(Game_Map::Y_SUBPIXELS) ? Game_Map::Y_SUBPIXELS.to_f : 4.0)
        disp_y_px = ($game_map ? ($game_map.display_y / sub_y).round : 0) rescue 0

        @sprites.each do |item|
          spr, piece = item
          next if spr.nil? || spr.disposed?
          key = piece[:key]
          rot = piece[:rot].to_i
          fw, fh = effective_footprint(piece[:footprint_w].to_i, piece[:footprint_h].to_i, rot)
          map_y = Housing::GRID_ORIGIN_Y + piece[:y].to_i
          vp_same = (psp && psp.viewport && spr.viewport) ? psp.viewport.equal?(spr.viewport) : false

          msg = "player py=#{$game_player.y} sprite_z=#{psp&.z} vp=#{psp&.viewport.inspect} | " +
                "furn(#{key}) map_y=#{map_y} fh=#{fh} z=#{spr.z} vp=#{spr.viewport.inspect} vp_same=#{vp_same} | " +
                "disp_y_px=#{disp_y_px}"

          if defined?(echoln)
            echoln(msg) rescue nil
          else
            puts(msg) rescue nil
          end
        end
      end

      # Check passability for a map tile (used by Game_Map#passable? & Game_Character#passable? hooks)
      def housing_tile_passable?(map_x, map_y)
        return true unless @active && Housing.state
        tier = Housing.state[:size_tier] || 1
        return true unless $game_map && $game_map.map_id == Housing::MAP_FOR_TIER[tier]

        gw = Housing.state[:grid_w] || 11
        gh = Housing.state[:grid_h] || 7
        grid_x_range = Housing::GRID_ORIGIN_X...(Housing::GRID_ORIGIN_X + gw)
        grid_y_range = Housing::GRID_ORIGIN_Y...(Housing::GRID_ORIGIN_Y + gh)
        exit_info = Housing::EXIT_TILES[tier]

        in_grid = grid_x_range.include?(map_x) && grid_y_range.include?(map_y)
        is_exit = exit_info && map_y == exit_info[:y] && exit_info[:x_range].include?(map_x)

        return false unless in_grid || is_exit

        # Check blocking furniture
        placed = Housing.state[:placed] || []
        placed.each do |p|
          # Carpets / floor items are never blocking
          next if p[:category].to_s == "floor"

          is_blocking = p[:blocking]
          next if is_blocking == false || is_blocking == 0 || is_blocking == "false"

          gx = p[:x].to_i
          gy = p[:y].to_i
          fw, fh = effective_footprint(p[:footprint_w].to_i, p[:footprint_h].to_i, p[:rot].to_i)

          top_left_map_x = Housing::GRID_ORIGIN_X + gx
          top_left_map_y = Housing::GRID_ORIGIN_Y + gy

          if map_x >= top_left_map_x && map_x < top_left_map_x + fw &&
             map_y >= top_left_map_y && map_y < top_left_map_y + fh
            return false
          end
        end
        true
      end

      private

      def dispose_all
        @floor_sprite&.bitmap&.dispose
        @floor_sprite&.dispose unless @floor_sprite&.disposed?
        @floor_sprite = nil
        @sprites.each { |item| sprite = item.is_a?(Array) ? item[0] : item; sprite.dispose if sprite && !sprite.disposed? }
        @sprites.clear
      end

      def add_furniture_sprite(piece)
        vp = get_map_viewport
        bmp = load_furniture_bitmap(piece)
        sprite = vp ? Sprite.new(vp) : Sprite.new
        sprite.bitmap = bmp

        rot = piece[:rot].to_i
        fw, fh = effective_footprint(piece[:footprint_w].to_i, piece[:footprint_h].to_i, rot)
        img_h = piece[:image_h] ? piece[:image_h].to_i : bmp.height

        map_x = Housing::GRID_ORIGIN_X + piece[:x].to_i
        map_y = Housing::GRID_ORIGIN_Y + piece[:y].to_i

        sub_x = (defined?(Game_Map::X_SUBPIXELS) ? Game_Map::X_SUBPIXELS.to_f : 4.0)
        sub_y = (defined?(Game_Map::Y_SUBPIXELS) ? Game_Map::Y_SUBPIXELS.to_f : 4.0)
        disp_x_px = ($game_map ? ($game_map.display_x / sub_x).round : 0) rescue 0
        disp_y_px = ($game_map ? ($game_map.display_y / sub_y).round : 0) rescue 0

        sprite.x = (map_x * Housing::TILE_SIZE) - disp_x_px
        sprite.y = ((map_y + fh) * Housing::TILE_SIZE) - img_h - disp_y_px

        cat = piece[:category].to_s
        if cat == "floor"
          sprite.z = 2
        elsif cat == "wall"
          sprite.z = (map_y * Housing::TILE_SIZE) - disp_y_px + 2
        else
          footprint_bottom_map_y = map_y + fh - 1
          sprite.z = (footprint_bottom_map_y * Housing::TILE_SIZE) - disp_y_px + 33
        end

        Housing.apply_sprite_rotation(sprite, rot, bmp.width, bmp.height)

        @sprites << [sprite, piece]
      end

      def load_furniture_bitmap(piece)
        key = piece[:key].to_s
        sprite_path = piece[:sprite].to_s

        candidates = []
        candidates << sprite_path unless sprite_path.empty?
        candidates << "#{sprite_path}.png" unless sprite_path.empty?
        candidates << "Graphics/Pictures/#{Housing::SPRITE_DIR}#{key}"
        candidates << "Graphics/Pictures/#{Housing::SPRITE_DIR}#{key}.png"
        candidates << "Graphics/Pictures/#{key}"
        candidates << "Graphics/Pictures/#{key}.png"

        resolved = nil
        candidates.each do |c|
          if defined?(pbResolveBitmap)
            r = pbResolveBitmap(c)
            if r
              resolved = r
              break
            end
          end
          if FileTest.exist?(c)
            resolved = c
            break
          end
        end

        bm = nil
        if resolved
          begin
            bm = Bitmap.new(resolved)
          rescue => e
            PEMK.log("housing: Bitmap.new failed for '#{resolved}': #{e.message}") rescue nil
          end
        end

        if bm
          bm
        else
          PEMK.log("housing: missing furniture sprite image for item '#{key}' (sprite='#{sprite_path}')") if defined?(PEMK.log)
          # Fallback: colored 32x32 block
          fw = piece[:footprint_w].to_i.clamp(1, 16)
          fh = piece[:footprint_h].to_i.clamp(1, 16)
          w  = [fw * Housing::TILE_SIZE, 1].max
          h  = [fh * Housing::TILE_SIZE, 1].max
          bm = Bitmap.new(w, h)
          cat = piece[:category].to_s
          color = Housing::CATEGORY_COLORS.fetch(cat, Housing::DEFAULT_COLOR)
          bm.fill_rect(0, 0, w, h, color)
          # Draw border
          if w >= 4 && h >= 4
            border = Color.new((color.red * 0.6).to_i, (color.green * 0.6).to_i, (color.blue * 0.6).to_i)
            bm.fill_rect(0, 0, w, 2, border)
            bm.fill_rect(0, h - 2, w, 2, border)
            bm.fill_rect(0, 0, 2, h, border)
            bm.fill_rect(w - 2, 0, 2, h, border)
          end
          bm
        end
      end

      # Override $game_map passage data for Map 927
      def rebuild_passability
        return unless $game_map && Housing.state
        tier = Housing.state[:size_tier] || 1
        current_map = Housing::MAP_FOR_TIER[tier]
        return unless $game_map.map_id == current_map
        return unless $game_map.respond_to?(:set_passage)

        gw = Housing.state[:grid_w] || 11
        gh = Housing.state[:grid_h] || 7
        grid_x_range = Housing::GRID_ORIGIN_X...(Housing::GRID_ORIGIN_X + gw)
        grid_y_range = Housing::GRID_ORIGIN_Y...(Housing::GRID_ORIGIN_Y + gh)

        exit_info = Housing::EXIT_TILES[tier]

        map_w = $game_map.width
        map_h = $game_map.height

        map_w.times do |tx|
          map_h.times do |ty|
            in_grid = grid_x_range.include?(tx) && grid_y_range.include?(ty)
            is_exit = exit_info && ty == exit_info[:y] && exit_info[:x_range].include?(tx)

            unless in_grid || is_exit
              $game_map.set_passage(tx, ty, 15)
            end
          end
        end

        # Block tiles occupied by blocking furniture inside the grid
        placed = Housing.state[:placed] || []
        placed.each do |p|
          next if p[:category].to_s == "floor"
          is_blocking = p[:blocking]
          next if is_blocking == false || is_blocking == 0 || is_blocking == "false"
          fw, fh = effective_footprint(p[:footprint_w].to_i, p[:footprint_h].to_i, p[:rot].to_i)
          fw.times do |dx|
            fh.times do |dy|
              tx = Housing::GRID_ORIGIN_X + p[:x].to_i + dx
              ty = Housing::GRID_ORIGIN_Y + p[:y].to_i + dy
              $game_map.set_passage(tx, ty, 15)
            end
          end
        end
      end

      def effective_footprint(w, h, rot)
        (rot == 90 || rot == 270) ? [h, w] : [w, h]
      end
    end
  end
end

# Keep sprite positions & depth sorting in sync with map scrolling
class Scene_Map
  alias_method :pemk_housing_renderer_orig_update, :update

  def update
    if $game_map && !PEMK::Housing.is_house_map?($game_map.map_id)
      PEMK::HousingRenderer.dispose if PEMK::HousingRenderer.active?
    elsif PEMK::HousingRenderer.active?
      PEMK::HousingRenderer.update_sprite_positions
    end
    pemk_housing_renderer_orig_update
  end
end

# Hook Game_Character#passable? to prevent player from stepping onto blocking furniture
class Game_Character
  alias_method :pemk_housing_char_orig_passable?, :passable?

  def passable?(x, y, d = 0, *args)
    if self.is_a?(Game_Player) && PEMK::Housing.state && $game_map && PEMK::Housing.is_house_map?($game_map.map_id)
      return false unless PEMK::HousingRenderer.housing_tile_passable?(x, y)
      if d && d > 0
        nx = x + (d == 6 ? 1 : d == 4 ? -1 : 0)
        ny = y + (d == 2 ? 1 : d == 8 ? -1 : 0)
        return false unless PEMK::HousingRenderer.housing_tile_passable?(nx, ny)
      end
    end
    pemk_housing_char_orig_passable?(x, y, d, *args)
  end
end

# Hook Game_Map#passable? to block movement onto blocking furniture or out of grid
class Game_Map
  alias_method :pemk_housing_orig_passable?, :passable?

  def passable?(x, y, d = 0, *args)
    if PEMK::Housing.state && PEMK::Housing.is_house_map?(@map_id)
      return false unless PEMK::HousingRenderer.housing_tile_passable?(x, y)
      if d && d > 0
        nx = x + (d == 6 ? 1 : d == 4 ? -1 : 0)
        ny = y + (d == 2 ? 1 : d == 8 ? -1 : 0)
        return false unless PEMK::HousingRenderer.housing_tile_passable?(nx, ny)
      end
    end
    pemk_housing_orig_passable?(x, y, d, *args)
  end
end

# Cleanup sprites when leaving Scene_Map
module PEMKHousingSceneCleanup
  def update(*args)
    PEMK::HousingRenderer.dispose if PEMK::HousingRenderer.active? && !$scene.is_a?(Scene_Map)
    super
  end
end
Graphics.singleton_class.prepend(PEMKHousingSceneCleanup)

