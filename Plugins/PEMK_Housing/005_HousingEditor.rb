#===============================================================================
# PEMK_Housing :: 005 Editor
#-------------------------------------------------------------------------------
# Mode édition de maison - Interface style Pokémon (fenêtres à double bordure,
# bandeaux dégradés, touches en relief, panneau d'infos, inventaire visuel).
#
# Layout :
#   ┌───────────────┬────────────────────────────────┬───────────────┐
#   │ Bandeau titre │                                │ Fiche meuble  │
#   │ / Inventaire  │           Vue carte            │ (survol/main) │
#   │               │      + grille + curseur        │               │
#   ├───────────────┴────────────────────────────────┴───────────────┤
#   │  Message contextuel  +  touches (icônes clavier)               │
#   └────────────────────────────────────────────────────────────────┘
#
# Contrôles :
#   H / Menu Pause     — Ouvrir / Quitter le mode édition
#   Z/Q/S/D / Flèches  — Déplacer le curseur (ou souris)
#   Entrée / Espace    — Saisir un meuble posé / Poser / Ouvrir l'inventaire
#   R                  — Tourner le meuble tenu
#   I / F              — Ouvrir / fermer l'inventaire
#   X / Suppr          — Ranger (meuble posé) / Annuler (meuble neuf)
#   Échap / Clic droit — Annuler la prise / Fermer / Quitter l'édition
#
# Réglages rapides : voir les constantes FONT_* et USE_SYSTEM_FONT ci-dessous.
#===============================================================================
module PEMK
  module HousingEditor
    @active          = false
    @mode            = :view
    @cursor_x        = 0
    @cursor_y        = 0
    @held            = nil
    @held_item       = nil
    @held_is_moving  = false
    @held_valid      = nil
    @last_valid      = nil
    @rot             = 0
    @error_msg       = nil
    @error_until     = 0
    @hover_item      = nil
    @anim_tick       = 0
    @was_in_menu     = false
    @paint_mode           = false
    @paint_step           = :select_style
    @zone_start           = nil
    @selected_floor_style = 1
    @ui_t                 = 1.0    # animation d'entrée des HUD
    @inv_t           = 1.0    # animation d'entrée de l'inventaire
    @panel_t         = 0.0    # animation du panneau latéral
    @panel_target    = 0.0
    @inv_open        = false
    @inv_index       = 0
    @inv_scroll      = 0
    @last_mouse      = nil
    @mouse_moved     = false
    @mouse_on_hud    = false
    @foot_key        = nil
    @grid_key        = nil
    @bmp_cache       = {}
    @measure_bm      = nil
    @cursor_sprite   = nil
    @foot_sprite     = nil
    @grid_sprite     = nil
    @preview_sprite  = nil
    @hud_bottom      = nil
    @hud_panel       = nil
    @hud_title       = nil
    @hud_error       = nil
    @hud_inv         = nil

    # ─── Dimensions ─────────────────────────────────────────────────────────────
    BOTTOM_H    = 58    # Hauteur de la barre du bas
    PANEL_W     = 164   # Largeur de la fiche meuble (droite)
    TITLE_W     = 176
    TITLE_H     = 44
    INV_W       = 220   # Largeur de l'inventaire
    INV_HEAD_H  = 26
    INV_FOOT_H  = 20
    INV_ROW_H   = 40

    # ─── Polices ─────────────────────────────────────────────────────────────────
    # USE_SYSTEM_FONT = false → police par défaut RMXP (taille fiable)
    # Si tu veux la police Pokémon Essentials, passe à true MAIS augmente les rects.
    USE_SYSTEM_FONT = false
    FONT_TITLE  = 18
    FONT_NORMAL = 16
    FONT_SMALL  = 13

    # ─── Palette ────────────────────────────────────────────────────────────────
    C_NAVY      = Color.new(40,  48,  80)
    C_LINE      = Color.new(200, 208, 224)
    C_PAPER_TOP = Color.new(252, 252, 248)
    C_PAPER_BOT = Color.new(230, 236, 244)
    C_WHITE     = Color.new(255, 255, 255)

    # [haut, bas, bordure]
    THEMES = {
      :blue  => [Color.new(112, 168, 248), Color.new(56,  104, 200), Color.new(32, 56, 128)],
      :gold  => [Color.new(252, 208, 80),  Color.new(232, 152, 32),  Color.new(136, 80, 16)],
      :green => [Color.new(128, 224, 128), Color.new(56,  168, 88),  Color.new(24, 88, 48)],
      :red   => [Color.new(252, 128, 112), Color.new(208, 56,  56),  Color.new(112, 24, 32)],
    }

    # [texte, ombre]
    TONES = {
      :dark  => [Color.new(72,  72,  80),  Color.new(200, 208, 216)],
      :grey  => [Color.new(128, 136, 152), Color.new(216, 222, 232)],
      :light => [Color.new(252, 252, 252), Color.new(64,  72,  104)],
    }

    CATEGORY_LABELS = {
      "functional" => "Fonctionnel",
      "decor"      => "Décoration",
      "wall"       => "Mural",
      "floor"      => "Sol",
      "partition"  => "Cloison",
    }
    CATEGORY_TINTS = {
      "functional" => Color.new(72,  132, 220),
      "decor"      => Color.new(216, 152, 48),
      "wall"       => Color.new(128, 128, 168),
      "floor"      => Color.new(96,  176, 72),
      "partition"  => Color.new(176, 112, 56),
    }
    DEFAULT_TINT = Color.new(144, 144, 168)

    # Codes d'erreur serveur -> texte joueur (à compléter si besoin)
    ERROR_TEXTS = {
      "VERSION_CONFLICT" => "La maison a changé, réessaie !",
    }

    class << self
      def active?
        @active && @mode == :edit
      end

      def setup_view
        unless $game_map && Housing.is_house_map?($game_map.map_id)
          dispose_all
          return
        end
        @active         = true
        @mode           = :view
        @held           = nil
        @held_item      = nil
        @held_is_moving = false
        @paint_mode     = false
        @paint_step     = :select_style
        @zone_start     = nil
        tier  = Housing.state&.dig(:size_tier) || 1
        entry = (Housing.entry_grid_for(tier) rescue nil)
        @cursor_x = entry ? entry[0] : 2
        @cursor_y = entry ? entry[1] : 4
        create_hud_bottom
        refresh_hud_bottom
      end

      def start
        return if active?
        @active      = true
        @mode        = :edit
        @paint_mode  = false
        @paint_step  = :select_style
        @zone_start  = nil
        @was_in_menu = $game_temp ? $game_temp.in_menu : false
        $game_temp.in_menu = true if $game_temp
        $game_player.straighten rescue nil
        PEMK.log("housing editor: enter edit mode")
        @ui_t         = 0.0
        @panel_t      = 0.0
        @panel_target = 0.0
        @inv_open     = false
        @last_valid   = nil
        @last_mouse   = nil
        @hover_item   = piece_at(@cursor_x, @cursor_y)
        create_cursor_sprite
        create_hud_bottom
        create_hud_panel
        create_hud_title
        refresh_hud_bottom
        refresh_hud_panel
        refresh_hud_title
        apply_hud_positions
      end

      def stop
        return unless @mode == :edit
        PEMK.log("housing editor: exit edit mode")
        begin
          @inv_open   = false
          @paint_mode = false
          @paint_step = :select_style
          @zone_start = nil
          dispose_hud_inv
          dispose_cursor
          dispose_foot
          dispose_grid
          dispose_preview
          dispose_hud_panel
          dispose_hud_title
          dispose_hud_error
          clear_bitmap_cache
          @mode           = :view
          @held           = nil
          @held_item      = nil
          @held_is_moving = false
          @hover_item     = nil
          if $game_map && Housing.is_house_map?($game_map.map_id)
            @ui_t           = 1.0
            create_hud_bottom
            refresh_hud_bottom
          else
            dispose_all
          end
        ensure
          $game_temp.in_menu = @was_in_menu if $game_temp
        end
      end

      def dispose_all
        stop if active?
        @active         = false
        @mode           = :view
        @held           = nil
        @held_item      = nil
        @held_is_moving = false
        @hover_item     = nil
        @inv_open       = false
        dispose_cursor
        dispose_foot
        dispose_grid
        dispose_preview
        dispose_hud_bottom
        dispose_hud_panel
        dispose_hud_title
        dispose_hud_error
        dispose_hud_inv
        clear_bitmap_cache
        @measure_bm&.dispose unless @measure_bm&.disposed?
        @measure_bm = nil
      end

      def on_state_refreshed
        return unless active?
        refresh_hud_bottom
        refresh_hud_panel
        refresh_hud_title
        refresh_hud_inv if @inv_open
      end

      def on_place_ok(msg)
        old_catalog_id = @held_item ? @held_item[:catalog_id] : nil
        @held           = nil
        @held_item      = nil
        @held_is_moving = false
        if old_catalog_id && Housing.state
          next_item = (Housing.state[:inventory] || []).find { |i| i[:catalog_id] == old_catalog_id }
          if next_item
            @held      = next_item[:uid]
            @held_item = next_item
          end
        end
        update_preview_sprite
        refresh_hud_bottom
        refresh_hud_panel
      end

      def on_move_ok(msg)
        release_hold
      end

      def on_remove_ok(msg)
        release_hold
      end

      def on_error(msg)
        code = msg[:code].to_s
        show_error(ERROR_TEXTS.fetch(code, code))
        if msg[:code] == "VERSION_CONFLICT"
          release_hold
          Housing.send_enter
        end
      end

      # ── Boucle principale ──────────────────────────────────────────────────
      def update
        unless $scene.is_a?(Scene_Map) && $game_map && Housing.state && Housing.is_house_map?($game_map.map_id)
          dispose_all if @active || @hud_bottom || @hud_panel
          return
        end

        setup_view unless @active

        @anim_tick = (@anim_tick + 1) % 120
        update_hud_error_tick

        $game_temp.in_menu = true if active? && $game_temp

        if key_triggered?(:H)
          active? ? stop : start
          return
        end

        unless active?
          update_view_click
          return
        end

        @mouse_moved = mouse_moved?
        update_ui_animation

        # Inventaire ouvert : il capte toutes les entrées
        if @inv_open
          update_inventory
          return
        end

        if key_triggered?(:ESCAPE)
          if @held
            release_hold
          else
            stop; return
          end
        end

        old_cx = @cursor_x
        old_cy = @cursor_y
        update_mouse_position
        update_keyboard_position

        if (@cursor_x != old_cx || @cursor_y != old_cy) && @paint_mode && @paint_step == :select_zone && @zone_start
          refresh_hud_bottom
        end

        # Meuble sous le curseur
        new_hover = piece_at(@cursor_x, @cursor_y)
        if new_hover != @hover_item
          @hover_item = new_hover
          refresh_hud_panel
          refresh_hud_bottom
        end

        # Validité du placement (met à jour la fiche si elle change)
        if @held && @held_item
          fw, fh = effective_footprint(@held_item[:footprint_w].to_i, @held_item[:footprint_h].to_i, @rot.to_i)
          @held_valid = valid_position?(@cursor_x, @cursor_y, fw, fh)
          if @held_valid != @last_valid
            @last_valid = @held_valid
            refresh_hud_panel
          end
        else
          @held_valid = nil
          @last_valid = nil
        end

        update_input
        return unless active?

        update_grid_sprite
        update_cursor_sprite
        update_foot_sprite
        update_preview_sprite
      end

      private

      # =========================================================================
      # ENTRÉES
      # =========================================================================
      def key_triggered?(sym)
        return false unless Input.respond_to?(:triggerex?)
        return true if Input.triggerex?(sym)
        if sym == :RETURN
          return Input.triggerex?(:ENTER) || Input.triggerex?(13)
        elsif sym == :ENTER
          return Input.triggerex?(:RETURN) || Input.triggerex?(13)
        end
        false
      end

      def key_pressed?(sym)
        return false unless Input.respond_to?(:pressedex?)
        return true if Input.pressedex?(sym)
        if sym == :RETURN
          return Input.pressedex?(:ENTER) || Input.pressedex?(13)
        elsif sym == :ENTER
          return Input.pressedex?(:RETURN) || Input.pressedex?(13)
        end
        false
      end

      def key_repeat?(sym)
        if Input.respond_to?(:repeatex?)
          return true if Input.repeatex?(sym)
          if sym == :RETURN
            return Input.repeatex?(:ENTER) || Input.repeatex?(13)
          elsif sym == :ENTER
            return Input.repeatex?(:RETURN) || Input.repeatex?(13)
          end
          false
        else
          key_triggered?(sym)
        end
      end

      def grid_w; Housing.state&.dig(:grid_w) || 11; end
      def grid_h; Housing.state&.dig(:grid_h) || 7; end

      def mouse_pos
        return nil unless Input.respond_to?(:mouse_x)
        mx = Input.mouse_x; my = Input.mouse_y
        return nil if mx.nil? || my.nil? || mx < 0 || my < 0
        [mx, my]
      end

      def mouse_moved?
        pos = mouse_pos
        return false unless pos
        moved = (pos != @last_mouse)
        @last_mouse = pos
        moved
      end

      def mouse_on_hud?(mx, my)
        gh = Graphics.height rescue 384
        return true if my >= gh - BOTTOM_H
        [@hud_panel, @hud_title].each do |s|
          next unless s && !s.disposed? && s.visible && s.bitmap
          return true if mx >= s.x && mx < s.x + s.bitmap.width && my >= s.y && my < s.y + s.bitmap.height
        end
        false
      end

      # Clic sur la pastille "H Décorer" en mode vue
      def update_view_click
        return unless key_triggered?(:LBUTTON)
        pos = mouse_pos
        return unless pos
        return unless @hud_bottom && !@hud_bottom.disposed? && @hud_bottom.bitmap
        bx = @hud_bottom.x; by = @hud_bottom.y
        bw = @hud_bottom.bitmap.width; bh = @hud_bottom.bitmap.height
        start if pos[0] >= bx && pos[0] < bx + bw && pos[1] >= by && pos[1] < by + bh
      end

      def update_mouse_position
        pos = mouse_pos
        @mouse_on_hud = false
        return unless pos
        @mouse_on_hud = mouse_on_hud?(pos[0], pos[1])
        return unless @mouse_moved
        return if @mouse_on_hud
        gx, gy = Housing.screen_to_grid(pos[0], pos[1])
        if gx.between?(0, grid_w - 1) && gy.between?(0, grid_h - 1)
          @cursor_x = gx; @cursor_y = gy
        end
      end

      def update_keyboard_position
        dx = 0; dy = 0
        dx -= 1 if Input.repeat?(Input::LEFT)  || key_repeat?(:Q) || key_repeat?(:A)
        dx += 1 if Input.repeat?(Input::RIGHT) || key_repeat?(:D)
        dy -= 1 if Input.repeat?(Input::UP)    || key_repeat?(:Z) || key_repeat?(:W)
        dy += 1 if Input.repeat?(Input::DOWN)  || key_repeat?(:S)
        @cursor_x = (@cursor_x + dx).clamp(0, grid_w - 1)
        @cursor_y = (@cursor_y + dy).clamp(0, grid_h - 1)
      end

      def update_input
        click = key_triggered?(:LBUTTON) && !@mouse_on_hud

        if key_triggered?(:P)
          @paint_mode = !@paint_mode
          if @paint_mode
            release_hold
            close_inventory if @inv_open
            @paint_step = :select_style
            @zone_start = nil
            @floor_index ||= 1
            @floor_scroll ||= 0
            styles = Housing.floor_styles
            @selected_floor_style = styles[@floor_index][:id] rescue 1
            @inv_t = 0.0
            create_hud_inv
            refresh_hud_inv
          else
            @zone_start = nil
            dispose_hud_inv
          end
          refresh_hud_bottom; refresh_hud_panel; refresh_hud_title
          return
        end

        if @paint_mode
          update_paint_inventory
          return
        end

        if click || key_triggered?(:RETURN) || key_triggered?(:SPACE)
          if @held
            fw, fh = effective_footprint(@held_item[:footprint_w].to_i, @held_item[:footprint_h].to_i, @rot)
            if valid_position?(@cursor_x, @cursor_y, fw, fh)
              if @held_is_moving
                Housing.send_move(@held, @cursor_x, @cursor_y, @rot || 0)
              else
                Housing.send_place(@held, @cursor_x, @cursor_y, @rot || 0)
              end
            else
              show_error("Placement impossible !")
            end
          else
            p = piece_at(@cursor_x, @cursor_y)
            if p
              @held = p[:uid]; @held_item = p
              @rot  = p[:rot].to_i; @held_is_moving = true
              refresh_hud_bottom; refresh_hud_panel
            else
              open_inventory
            end
          end
        end
        return if @inv_open

        if key_triggered?(:R)
          if @held_item && rotatable?(@held_item)
            @rot = ((@rot || 0) + 90) % 360
            refresh_hud_bottom; refresh_hud_panel
          elsif @held_item
            show_error("Ce meuble ne peut pas pivoter")
          end
        end

        if key_triggered?(:I)
          open_inventory
        end
        return if @inv_open

        if key_triggered?(:X) || key_triggered?(:DELETE)
          if @held
            if @held_is_moving
              Housing.send_remove(@held)
            else
              release_hold
            end
          else
            p = piece_at(@cursor_x, @cursor_y)
            Housing.send_remove(p[:uid]) if p
          end
        end

        if key_triggered?(:RBUTTON)
          if @held
            release_hold
          else
            stop
          end
        end
      end

      def release_hold
        @held           = nil
        @held_item      = nil
        @held_is_moving = false
        @held_valid     = nil
        @last_valid     = nil
        update_preview_sprite
        refresh_hud_bottom
        refresh_hud_panel
      end

      def rotatable?(item)
        v = item[:rotatable]
        v == true || v == 1 || v == "true"
      end

      # =========================================================================
      # LOGIQUE DE GRILLE
      # =========================================================================
      def valid_position?(gx, gy, fw, fh)
        return false unless gx >= 0 && gy >= 0 && gx + fw <= grid_w && gy + fh <= grid_h
        tier = Housing.state[:size_tier] || 1
        entry = Housing.entry_grid_for(tier)
        if entry && gx <= entry[0] && entry[0] < gx + fw && gy <= entry[1] && entry[1] < gy + fh
          return false
        end
        placed = Housing.state[:placed] || []
        new_layer = @held_item&.[](:category) == "floor" ? :floor : :solid
        placed.each do |p|
          next if p[:uid] == @held
          other_layer = p[:category] == "floor" ? :floor : :solid
          next if new_layer != other_layer
          ofw, ofh = effective_footprint(p[:footprint_w].to_i, p[:footprint_h].to_i, p[:rot].to_i)
          next if gx + fw <= p[:x].to_i || p[:x].to_i + ofw <= gx
          next if gy + fh <= p[:y].to_i || p[:y].to_i + ofh <= gy
          return false
        end
        true
      end

      # Meuble sous la case (priorité aux meubles "solides" sur les sols)
      def piece_at(x, y)
        list = (Housing.state&.dig(:placed) || []).select { |p|
          fw, fh = effective_footprint(p[:footprint_w].to_i, p[:footprint_h].to_i, p[:rot].to_i)
          x >= p[:x].to_i && x < p[:x].to_i + fw && y >= p[:y].to_i && y < p[:y].to_i + fh
        }
        list.find { |p| p[:category] != "floor" } || list.first
      end

      def effective_footprint(w, h, rot)
        (rot == 90 || rot == 270) ? [h, w] : [w, h]
      end

      # =========================================================================
      # INVENTAIRE (liste visuelle, non bloquante)
      # =========================================================================
      def inventory_groups
        inv   = Housing.state&.dig(:inventory) || []
        order = []
        map   = {}
        inv.each do |it|
          k = it[:catalog_id] || it[:uid]
          unless map[k]
            map[k] = []
            order << k
          end
          map[k] << it
        end
        order.map { |k| { :item => map[k][0], :count => map[k].length } }
      end

      def inv_rect
        gh = Graphics.height rescue 384
        [6, 6, INV_W, gh - BOTTOM_H - 12]
      end

      def inv_visible_rows
        h = inv_rect[3]
        [(h - INV_HEAD_H - 3 - INV_FOOT_H) / INV_ROW_H, 1].max
      end

      def inv_ensure_visible
        rows = inv_visible_rows
        @inv_scroll = @inv_index if @inv_index < @inv_scroll
        @inv_scroll = @inv_index - rows + 1 if @inv_index >= @inv_scroll + rows
        @inv_scroll = 0 if @inv_scroll < 0
      end

      def open_inventory
        groups = inventory_groups
        return show_error("Inventaire vide") if groups.empty?
        @inv_open   = true
        @inv_index  = 0
        @inv_scroll = 0
        @inv_t      = 0.0
        if @held && !@held_is_moving && @held_item
          idx = groups.index { |g| g[:item][:catalog_id] == @held_item[:catalog_id] }
          @inv_index = idx if idx
        end
        inv_ensure_visible
        create_hud_inv
        [@cursor_sprite, @foot_sprite, @preview_sprite].each do |s|
          s.visible = false if s && !s.disposed?
        end
        refresh_hud_inv
        refresh_hud_bottom
        refresh_hud_panel
        apply_hud_positions
      end

      def close_inventory
        @inv_open = false
        dispose_hud_inv
        @last_valid = nil
        refresh_hud_bottom
        refresh_hud_panel
        apply_hud_positions
      end

      def update_inventory
        groups = inventory_groups
        if groups.empty?
          close_inventory
          return
        end
        old_index  = @inv_index
        old_scroll = @inv_scroll

        @inv_index -= 1 if key_repeat?(:Z) || key_repeat?(:W) || Input.repeat?(Input::UP)
        @inv_index += 1 if key_repeat?(:S) || Input.repeat?(Input::DOWN)
        if Input.respond_to?(:scroll_v)
          sv = Input.scroll_v
          @inv_index -= sv.to_i if sv && sv != 0
        end
        @inv_index = @inv_index.clamp(0, groups.length - 1)

        # Souris sur une ligne
        clicked = false
        pos = mouse_pos
        if pos
          rx, ry, rw, rh = inv_rect
          y0   = ry + INV_HEAD_H + 3
          rows = inv_visible_rows
          if pos[0] >= rx && pos[0] < rx + rw && pos[1] >= y0
            row = (pos[1] - y0) / INV_ROW_H
            idx = @inv_scroll + row
            if row < rows && idx < groups.length
              @inv_index = idx if @mouse_moved
              if key_triggered?(:LBUTTON)
                @inv_index = idx
                clicked = true
              end
            end
          end
        end

        inv_ensure_visible
        if @inv_index != old_index || @inv_scroll != old_scroll
          refresh_hud_inv
          refresh_hud_panel
        end

        if clicked || key_triggered?(:RETURN) || key_triggered?(:SPACE)
          it = groups[@inv_index][:item]
          @held           = it[:uid]
          @held_item      = it
          @rot            = 0
          @held_is_moving = false
          close_inventory
          return
        end

        if key_triggered?(:ESCAPE) || key_triggered?(:RBUTTON) || key_triggered?(:X) ||
           key_triggered?(:I) || key_triggered?(:F)
          close_inventory
        end
      end

      def update_paint_inventory
        styles = Housing.floor_styles
        return if styles.empty?

        # ── Phase 1 : Sélection du motif dans le catalogue ──────────────────
        if @paint_step == :select_style
          if key_triggered?(:ESCAPE) || key_triggered?(:RBUTTON)
            @paint_mode = false
            dispose_hud_inv
            refresh_hud_bottom; refresh_hud_panel; refresh_hud_title
            return
          end

          old_index  = @floor_index
          old_scroll = @floor_scroll

          @floor_index -= 1 if key_repeat?(:Z) || key_repeat?(:W) || Input.repeat?(Input::UP)
          @floor_index += 1 if key_repeat?(:S) || Input.repeat?(Input::DOWN)
          if Input.respond_to?(:scroll_v)
            sv = Input.scroll_v
            @floor_index -= sv.to_i if sv && sv != 0
          end
          @floor_index = @floor_index.clamp(0, styles.length - 1)

          pos = mouse_pos
          clicked_row = false
          if pos
            rx, ry, rw, rh = inv_rect
            y0   = ry + INV_HEAD_H + 3
            rows = inv_visible_rows
            if pos[0] >= rx && pos[0] < rx + rw && pos[1] >= y0
              row = (pos[1] - y0) / INV_ROW_H
              idx = @floor_scroll.to_i + row
              if row < rows && idx < styles.length
                @floor_index = idx if @mouse_moved
                if key_triggered?(:LBUTTON) && !@mouse_on_hud
                  @floor_index = idx
                  clicked_row = true
                end
              end
            end
          end

          rows = inv_visible_rows
          if @floor_index < @floor_scroll
            @floor_scroll = @floor_index
          elsif @floor_index >= @floor_scroll + rows
            @floor_scroll = @floor_index - rows + 1
          end

          @selected_floor_style = styles[@floor_index][:id]

          if @floor_index != old_index || @floor_scroll != old_scroll
            refresh_hud_inv
            refresh_hud_title
          end

          # Valider le motif choisi -> ferme le catalogue et passe en sélection de zone sur la carte
          if clicked_row || key_triggered?(:RETURN) || key_triggered?(:SPACE)
            @paint_step = :select_zone
            @zone_start = nil
            dispose_hud_inv
            refresh_hud_title
            refresh_hud_bottom
            refresh_hud_panel
          end
          return
        end

        # ── Phase 2 : Sélection de zone et peinture sur la carte ───────────────
        if @paint_step == :select_zone
          pos = mouse_pos

          # Clic sur le badge indicatif du sol (haut gauche) ou touche TAB -> Réouvrir le catalogue
          if (key_triggered?(:LBUTTON) && pos && pos[0].between?(6, 182) && pos[1].between?(6, 50)) ||
             key_triggered?(:TAB)
            @paint_step = :select_style
            @zone_start = nil
            @inv_t = 0.0
            create_hud_inv
            refresh_hud_inv
            refresh_hud_title
            refresh_hud_bottom
            return
          end

          action_triggered = (key_triggered?(:LBUTTON) && !@mouse_on_hud) ||
                             key_triggered?(:RETURN) || key_triggered?(:SPACE) ||
                             (Input.trigger?(Input::USE) rescue false) ||
                             (Input.trigger?(Input::C) rescue false)

          if action_triggered
            if @zone_start.nil?
              # 1er coin : enregistrer le coin de départ
              @zone_start = [@cursor_x, @cursor_y]
              refresh_hud_bottom
              return
            else
              # 2ème coin : appliquer la peinture sur tout le rectangle !
              sx, sy = @zone_start
              x1 = [sx, @cursor_x].min; x2 = [sx, @cursor_x].max
              y1 = [sy, @cursor_y].min; y2 = [sy, @cursor_y].max

              (y1..y2).each do |j|
                (x1..x2).each do |i|
                  Housing.set_floor_tile(i, j, @selected_floor_style)
                end
              end

              HousingRenderer.refresh_floor_sprite
              HousingRenderer.update_sprite_positions
              Housing.send_floor_paint(Housing.state[:floor_tiles])
              @zone_start = nil # Zone terminée, prêt pour la suivante
              refresh_hud_bottom
              return
            end
          end

          if key_triggered?(:ESCAPE) || key_triggered?(:RBUTTON) ||
             (Input.trigger?(Input::BACK) rescue false) || (Input.trigger?(Input::B) rescue false)
            if @zone_start
              @zone_start = nil # Annuler la sélection de zone en cours
              refresh_hud_bottom
            else
              # Quitter le mode peinture
              @paint_mode = false
              @paint_step = :select_style
              refresh_hud_title
              refresh_hud_bottom
              refresh_hud_panel
            end
            return
          end

          if key_triggered?(:F)
            Housing.fill_floor(@selected_floor_style)
            HousingRenderer.refresh_floor_sprite
            HousingRenderer.update_sprite_positions
            Housing.send_floor_paint(Housing.state[:floor_tiles])
            @zone_start = nil
            show_error("Sol appliqué à toute la pièce !")
            refresh_hud_bottom
            return
          end
        end
      end

      def create_hud_inv
        dispose_hud_inv
        @hud_inv = Sprite.new
        @hud_inv.z = 605
      end

      def dispose_hud_inv
        @hud_inv&.bitmap&.dispose
        @hud_inv&.dispose unless @hud_inv&.disposed?
        @hud_inv = nil
      end

      def refresh_hud_inv
        return unless @hud_inv && !@hud_inv.disposed?
        if @paint_mode
          refresh_hud_inv_floors
          return
        end
        groups = inventory_groups
        if groups.empty?
          close_inventory
          return
        end
        @inv_index = @inv_index.clamp(0, groups.length - 1)
        inv_ensure_visible
        rx, ry, w, h = inv_rect
        rows = inv_visible_rows
        bm = Bitmap.new(w, h)
        draw_frame(bm, 0, 0, w, h)

        # En-tête
        draw_header_bar(bm, 3, 3, w - 6, 22, :blue)
        txt(bm, 10, 3, w - 20, 20, "INVENTAIRE", FONT_SMALL, :light, 0)
        total = (Housing.state&.dig(:inventory) || []).length
        txt(bm, 10, 3, w - 20, 20, "#{total} meuble#{total > 1 ? 's' : ''}", FONT_SMALL, :light, 2)

        y0 = INV_HEAD_H + 3
        rows.times do |v|
          idx = @inv_scroll + v
          g = groups[idx]
          break unless g
          it = g[:item]
          ry2 = y0 + v * INV_ROW_H
          sel = (idx == @inv_index)
          if sel
            pkmn_rect(bm, 5, ry2, w - 10, INV_ROW_H - 2, Color.new(88, 136, 224))
            draw_gradient_bg(bm, 6, ry2 + 1, w - 12, INV_ROW_H - 4,
                             Color.new(226, 242, 255), Color.new(176, 208, 248))
            draw_arrow(bm, 11, ry2 + INV_ROW_H / 2 - 1, 1, 5, C_NAVY)
          else
            bm.fill_rect(8, ry2 + INV_ROW_H - 2, w - 16, 1, C_LINE)
          end
          # Vignette
          sx0 = 20
          sy0 = ry2 + (INV_ROW_H - 32) / 2
          pkmn_rect(bm, sx0, sy0, 32, 32, Color.new(168, 180, 208))
          bm.fill_rect(sx0 + 1, sy0 + 1, 30, 30, Color.new(238, 242, 250))
          draw_thumb(bm, it, sx0 + 2, sy0 + 2, 28)
          # Textes — lignes de 20px avec espacement explicite
          tx = sx0 + 32 + 6
          name_w = w - tx - 10 - (g[:count] > 1 ? 28 : 0)
          name = fit_text(Housing.furniture_name(it).to_s, name_w, FONT_NORMAL)
          txt(bm, tx, ry2 + 2,  name_w, 20, name, FONT_NORMAL, :dark)
          sub = "#{cat_label(it)}  #{it[:footprint_w].to_i}×#{it[:footprint_h].to_i}"
          txt(bm, tx, ry2 + 22, name_w, 18, sub, FONT_SMALL, :grey)
          if g[:count] > 1
            txt(bm, w - 44, ry2 + 8, 34, 20, "×#{g[:count]}", FONT_NORMAL, :dark, 2)
          end
        end

        # Pied
        fy = h - INV_FOOT_H
        bm.fill_rect(8, fy, w - 16, 1, C_LINE)
        txt(bm, 0, fy + 2, w, 18, "#{@inv_index + 1} / #{groups.length}", FONT_SMALL, :grey, 1)
        draw_arrow(bm, 16, fy + 10, 0, 4, C_NAVY) if @inv_scroll > 0
        draw_arrow(bm, w - 16, fy + 10, 2, 4, C_NAVY) if @inv_scroll + rows < groups.length

        @hud_inv.bitmap&.dispose
        @hud_inv.bitmap = bm
        apply_hud_positions
      end

      def refresh_hud_inv_floors
        styles = Housing.floor_styles
        rx, ry, w, h = inv_rect
        rows = inv_visible_rows
        bm = Bitmap.new(w, h)
        draw_frame(bm, 0, 0, w, h)

        draw_header_bar(bm, 3, 3, w - 6, 22, :gold)
        txt(bm, 10, 3, w - 20, 20, "PEINTURE SOL", FONT_SMALL, :light, 0)
        txt(bm, 10, 3, w - 20, 20, "#{styles.length} motifs", FONT_SMALL, :light, 2)

        y0 = INV_HEAD_H + 3
        rows.times do |v|
          idx = @floor_scroll.to_i + v
          style = styles[idx]
          break unless style
          ry2 = y0 + v * INV_ROW_H
          sel = (idx == @floor_index)
          if sel
            pkmn_rect(bm, 5, ry2, w - 10, INV_ROW_H - 2, Color.new(216, 168, 48))
            draw_gradient_bg(bm, 6, ry2 + 1, w - 12, INV_ROW_H - 4,
                             Color.new(255, 246, 216), Color.new(248, 224, 160))
            draw_arrow(bm, 11, ry2 + INV_ROW_H / 2 - 1, 1, 5, C_NAVY)
          else
            bm.fill_rect(8, ry2 + INV_ROW_H - 2, w - 16, 1, C_LINE)
          end

          sx0 = 20
          sy0 = ry2 + (INV_ROW_H - 32) / 2
          pkmn_rect(bm, sx0, sy0, 32, 32, C_NAVY)
          tile_bm = Housing.build_floor_tile_bitmap(style[:id])
          bm.blt(sx0 + 1, sy0 + 1, tile_bm, Rect.new(0, 0, 30, 30))
          tile_bm.dispose

          tx = sx0 + 32 + 6
          name_w = w - tx - 10
          name = fit_text(style[:name], name_w, FONT_NORMAL)
          txt(bm, tx, ry2 + 2, name_w, 20, name, FONT_NORMAL, :dark)
          txt(bm, tx, ry2 + 22, name_w, 18, "Motif ##{style[:id]}", FONT_SMALL, :grey)
        end

        fy = h - INV_FOOT_H
        bm.fill_rect(8, fy, w - 16, 1, C_LINE)
        txt(bm, 0, fy + 2, w, 18, "#{@floor_index.to_i + 1} / #{styles.length}", FONT_SMALL, :grey, 1)
        draw_arrow(bm, 16, fy + 10, 0, 4, C_NAVY) if @floor_scroll.to_i > 0
        draw_arrow(bm, w - 16, fy + 10, 2, 4, C_NAVY) if @floor_scroll.to_i + rows < styles.length

        @hud_inv.bitmap&.dispose
        @hud_inv.bitmap = bm
        apply_hud_positions
      end

      def draw_thumb(bm, piece, x, y, size)
        src = furniture_bitmap(piece)
        return unless src && !src.disposed? && src.width > 0 && src.height > 0
        s = [size.to_f / src.width, size.to_f / src.height].min
        s = s.floor if s > 1.0
        dw = [(src.width * s).to_i, 1].max
        dh = [(src.height * s).to_i, 1].max
        bm.stretch_blt(Rect.new(x + (size - dw) / 2, y + (size - dh) / 2, dw, dh),
                       src, Rect.new(0, 0, src.width, src.height))
      end

      def cat_label(item)
        cat = item[:category].to_s
        CATEGORY_LABELS[cat] || cat.capitalize
      end

      # =========================================================================
      # BITMAPS MEUBLES (mis en cache, libérés à la sortie)
      # =========================================================================
      def furniture_bitmap(piece)
        key = [piece[:key].to_s, piece[:sprite].to_s, piece[:footprint_w].to_i,
               piece[:footprint_h].to_i, piece[:category].to_s]
        bm = @bmp_cache[key]
        return bm if bm && !bm.disposed?
        bm = load_furniture_bitmap(piece)
        @bmp_cache[key] = bm
        bm
      end

      def clear_bitmap_cache
        (@bmp_cache || {}).each_value { |b| b.dispose if b && !b.disposed? }
        @bmp_cache = {}
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
            if r; resolved = r; break; end
          end
          if FileTest.exist?(c); resolved = c; break; end
        end
        bm = nil
        if resolved
          begin; bm = Bitmap.new(resolved)
          rescue => e; PEMK.log("housing: Bitmap.new failed for '#{resolved}': #{e.message}") rescue nil; end
        end
        bm || begin
          PEMK.log("housing: missing sprite for '#{key}'") rescue nil
          fw = piece[:footprint_w].to_i.clamp(1, 16)
          fh = piece[:footprint_h].to_i.clamp(1, 16)
          w  = [fw * Housing::TILE_SIZE, 1].max
          h  = [fh * Housing::TILE_SIZE, 1].max
          b  = Bitmap.new(w, h)
          cat = piece[:category].to_s
          col = Housing::CATEGORY_COLORS.fetch(cat, Housing::DEFAULT_COLOR)
          b.fill_rect(0, 0, w, h, col)
          if w >= 4 && h >= 4
            bd = Color.new((col.red * 0.6).to_i, (col.green * 0.6).to_i, (col.blue * 0.6).to_i)
            b.fill_rect(0, 0, w, 2, bd); b.fill_rect(0, h - 2, w, 2, bd)
            b.fill_rect(0, 0, 2, h, bd); b.fill_rect(w - 2, 0, 2, h, bd)
          end
          b
        end
      end

      # =========================================================================
      # SPRITES CARTE : grille, curseur, empreinte, aperçu
      # =========================================================================
      def pulse
        Math.sin(@anim_tick * Math::PI / 30.0)
      end

      # ── Grille ──────────────────────────────────────────────────────────────
      def update_grid_sprite
        tier  = Housing.state[:size_tier] || 1
        entry = (Housing.entry_grid_for(tier) rescue nil)
        key   = [grid_w, grid_h, entry]
        if key != @grid_key || @grid_sprite.nil? || @grid_sprite.disposed?
          dispose_grid
          @grid_sprite = Sprite.new
          @grid_sprite.z = 250
          @grid_sprite.bitmap = build_grid_bitmap(grid_w, grid_h, entry)
          @grid_key = key
        end
        sx, sy = Housing.grid_to_screen(0, 0)
        @grid_sprite.x = sx.to_i
        @grid_sprite.y = sy.to_i
        @grid_sprite.visible = true
      end

      def build_grid_bitmap(gw_t, gh_t, entry)
        ts = Housing::TILE_SIZE
        bm = Bitmap.new(gw_t * ts, gh_t * ts)
        gh_t.times do |j|
          gw_t.times do |i|
            c = ((i + j) % 2 == 0) ? Color.new(255, 255, 255, 16) : Color.new(0, 0, 0, 12)
            bm.fill_rect(i * ts, j * ts, ts, ts, c)
          end
        end
        line = Color.new(255, 255, 255, 46)
        gw_t.times { |i| bm.fill_rect(i * ts, 0, 1, gh_t * ts, line) }
        gh_t.times { |j| bm.fill_rect(0, j * ts, gw_t * ts, 1, line) }
        bw = gw_t * ts; bh = gh_t * ts
        edge = Color.new(255, 255, 255, 110)
        bm.fill_rect(0, 0, bw, 2, edge);      bm.fill_rect(0, bh - 2, bw, 2, edge)
        bm.fill_rect(0, 0, 2, bh, edge);      bm.fill_rect(bw - 2, 0, 2, bh, edge)
        if entry
          ex = entry[0]; ey = entry[1]
          bm.fill_rect(ex * ts + 1, ey * ts + 1, ts - 1, ts - 1, Color.new(96, 224, 128, 90))
          draw_arrow(bm, ex * ts + ts / 2, ey * ts + ts / 2, 2, 6, Color.new(255, 255, 255, 220))
        end
        bm
      end

      def dispose_grid
        @grid_sprite&.bitmap&.dispose
        @grid_sprite&.dispose unless @grid_sprite&.disposed?
        @grid_sprite = nil
        @grid_key    = nil
      end

      # ── Curseur ─────────────────────────────────────────────────────────────
      def create_cursor_sprite
        dispose_cursor
        ts = Housing::TILE_SIZE
        bm = Bitmap.new(ts, ts)
        draw_brackets(bm, 0, 0, ts, ts, 10, 4, Color.new(40, 48, 80, 230))
        draw_brackets(bm, 1, 1, ts - 2, ts - 2, 8, 2, C_WHITE)
        bm.fill_rect(3, 3, ts - 6, ts - 6, Color.new(255, 255, 255, 26))
        @cursor_sprite = Sprite.new
        @cursor_sprite.bitmap = bm
        @cursor_sprite.ox = ts / 2
        @cursor_sprite.oy = ts / 2
        @cursor_sprite.z = 300
      end

      def dispose_cursor
        @cursor_sprite&.bitmap&.dispose
        @cursor_sprite&.dispose unless @cursor_sprite&.disposed?
        @cursor_sprite = nil
      end

      def update_cursor_sprite
        return unless @cursor_sprite && !@cursor_sprite.disposed?
        if @held || @inv_open
          @cursor_sprite.visible = false
          return
        end
        ts = Housing::TILE_SIZE
        sx, sy = Housing.grid_to_screen(@cursor_x, @cursor_y)
        @cursor_sprite.x = sx.to_i + ts / 2
        @cursor_sprite.y = sy.to_i + ts / 2
        p = pulse
        @cursor_sprite.opacity = (225 + p * 30).to_i
        z = 1.0 + p * 0.05
        @cursor_sprite.zoom_x = z
        @cursor_sprite.zoom_y = z
        @cursor_sprite.visible = true
      end

      # ── Empreinte (zone occupée) ────────────────────────────────────────────
      def update_foot_sprite
        target = nil
        if !@inv_open
          if @paint_mode && @paint_step == :select_zone
            if @zone_start
              sx, sy = @zone_start
              x1 = [sx, @cursor_x].min; x2 = [sx, @cursor_x].max
              y1 = [sy, @cursor_y].min; y2 = [sy, @cursor_y].max
              target = [x1, y1, x2 - x1 + 1, y2 - y1 + 1, :ok]
            else
              target = [@cursor_x, @cursor_y, 1, 1, :hover]
            end
          elsif @held && @held_item
            fw, fh = effective_footprint(@held_item[:footprint_w].to_i, @held_item[:footprint_h].to_i, @rot.to_i)
            valid = @held_valid.nil? ? valid_position?(@cursor_x, @cursor_y, fw, fh) : @held_valid
            target = [@cursor_x, @cursor_y, fw, fh, valid ? :ok : :bad]
          elsif @hover_item
            fw, fh = effective_footprint(@hover_item[:footprint_w].to_i, @hover_item[:footprint_h].to_i, @hover_item[:rot].to_i)
            target = [@hover_item[:x].to_i, @hover_item[:y].to_i, fw, fh, :hover]
          end
        end
        if target.nil?
          @foot_sprite.visible = false if @foot_sprite && !@foot_sprite.disposed?
          return
        end
        gx, gy, fw, fh, kind = target
        key = [fw, fh, kind]
        if key != @foot_key || @foot_sprite.nil? || @foot_sprite.disposed?
          dispose_foot
          @foot_sprite = Sprite.new
          @foot_sprite.z = 290
          @foot_sprite.bitmap = build_foot_bitmap(fw, fh, kind)
          @foot_key = key
        end
        sx, sy = Housing.grid_to_screen(gx, gy)
        @foot_sprite.x = sx.to_i
        @foot_sprite.y = sy.to_i
        @foot_sprite.opacity = (215 + pulse * 35).to_i
        @foot_sprite.visible = true
      end

      def build_foot_bitmap(fw, fh, kind)
        ts = Housing::TILE_SIZE
        w = [fw * ts, 4].max
        h = [fh * ts, 4].max
        col = case kind
              when :ok    then Color.new(110, 235, 130)
              when :bad   then Color.new(250, 90, 80)
              else             Color.new(100, 180, 255)
              end
        bm = Bitmap.new(w, h)
        bm.fill_rect(0, 0, w, h, Color.new(col.red, col.green, col.blue, 56))
        edge = Color.new(col.red, col.green, col.blue, 235)
        bm.fill_rect(0, 0, w, 2, edge);      bm.fill_rect(0, h - 2, w, 2, edge)
        bm.fill_rect(0, 0, 2, h, edge);      bm.fill_rect(w - 2, 0, 2, h, edge)
        draw_brackets(bm, 0, 0, w, h, 10, 4, Color.new(40, 48, 80, 230))
        draw_brackets(bm, 1, 1, w - 2, h - 2, 8, 2, C_WHITE)
        bm
      end

      def dispose_foot
        @foot_sprite&.bitmap&.dispose
        @foot_sprite&.dispose unless @foot_sprite&.disposed?
        @foot_sprite = nil
        @foot_key    = nil
      end

      # ── Aperçu du meuble tenu ───────────────────────────────────────────────
      def update_preview_sprite
        unless active? && @held && @held_item && !@inv_open
          dispose_preview; return
        end
        @preview_sprite ||= Sprite.new
        @preview_sprite.z = 310
        bmp = furniture_bitmap(@held_item)
        @preview_sprite.bitmap = bmp unless @preview_sprite.bitmap.equal?(bmp)
        @preview_sprite.opacity = (170 + pulse * 20).to_i
        rot = @rot.to_i
        fw, fh = effective_footprint(@held_item[:footprint_w].to_i, @held_item[:footprint_h].to_i, rot)
        img_h = @held_item[:image_h] ? @held_item[:image_h].to_i : bmp.height
        sx, sy = Housing.grid_to_screen(@cursor_x, @cursor_y)
        @preview_sprite.x = sx.to_i
        @preview_sprite.y = (sy + (fh * Housing::TILE_SIZE) - img_h).to_i
        Housing.apply_sprite_rotation(@preview_sprite, rot, bmp.width, bmp.height)
        ok = @held_valid.nil? ? valid_position?(@cursor_x, @cursor_y, fw, fh) : @held_valid
        if ok
          @preview_sprite.tone = Tone.new(-80, 100, -80, 80)
        else
          @preview_sprite.tone = Tone.new(120, -80, -80, 80)
        end
        @preview_sprite.visible = true
      end

      def dispose_preview
        @preview_sprite&.dispose unless @preview_sprite&.disposed?
        @preview_sprite = nil
      end

      # =========================================================================
      # OUTILS DE DESSIN (style Pokémon)
      # =========================================================================
      def set_font(bm, size)
        if USE_SYSTEM_FONT && defined?(pbSetSystemFont)
          pbSetSystemFont(bm)
        else
          bm.font.name = "Arial"
        end
        bm.font.size = size
        bm.font.bold = false
      end

      def measure(str, size)
        @measure_bm = Bitmap.new(8, 8) if @measure_bm.nil? || @measure_bm.disposed?
        set_font(@measure_bm, size)
        @measure_bm.text_size(str.to_s).width
      end

      # Texte avec ombre (utilise pbDrawShadowText si disponible)
      def txt(bm, x, y, w, h, str, size = FONT_NORMAL, tone = :dark, align = 0)
        set_font(bm, size)
        base, shadow = TONES[tone] || TONES[:dark]
        if defined?(pbDrawShadowText)
          pbDrawShadowText(bm, x, y, w, h, str.to_s, base, shadow, align)
        else
          bm.font.color = shadow
          bm.draw_text(x + 1, y + 1, w, h, str.to_s, align)
          bm.font.color = base
          bm.draw_text(x, y, w, h, str.to_s, align)
        end
      end

      def fit_text(str, maxw, size)
        s = str.to_s
        return s if measure(s, size) <= maxw
        s = s.dup
        s = s[0...-1] while s.length > 1 && measure(s + "...", size) > maxw
        s + "..."
      end

      def wrap_text(str, maxw, size, max_lines)
        lines = []; cur = ""
        str.to_s.split(" ").each do |w|
          t = cur.empty? ? w : "#{cur} #{w}"
          if measure(t, size) > maxw && !cur.empty?
            lines << cur
            cur = w
          else
            cur = t
          end
        end
        lines << cur unless cur.empty?
        if lines.length > max_lines
          rest  = lines[(max_lines - 1)..-1].join(" ")
          lines = lines[0...(max_lines - 1)] + [rest]
        end
        lines = [""] if lines.empty?
        lines.map { |l| fit_text(l, maxw, size) }
      end

      def darker(c, f = 0.55)
        Color.new((c.red * f).to_i, (c.green * f).to_i, (c.blue * f).to_i)
      end

      # Rectangle aux coins "pixel" (escalier de 2 px), comme dans Pokémon
      def pkmn_rect(bm, x, y, w, h, c)
        return if w < 5 || h < 5
        bm.fill_rect(x + 2, y,     w - 4, h,     c)
        bm.fill_rect(x + 1, y + 1, w - 2, h - 2, c)
        bm.fill_rect(x,     y + 2, w,     h - 4, c)
      end

      def draw_gradient_bg(bm, x, y, w, h, col_top, col_bot)
        return if w <= 0 || h <= 0
        h.times do |i|
          t = i.to_f / [h - 1, 1].max
          r = (col_top.red   * (1 - t) + col_bot.red   * t).to_i.clamp(0, 255)
          g = (col_top.green * (1 - t) + col_bot.green * t).to_i.clamp(0, 255)
          b = (col_top.blue  * (1 - t) + col_bot.blue  * t).to_i.clamp(0, 255)
          a = (col_top.alpha * (1 - t) + col_bot.alpha * t).to_i.clamp(0, 255)
          bm.fill_rect(x, y + i, w, 1, Color.new(r, g, b, a))
        end
      end

      # Fenêtre : bordure marine + liseré bleu + liseré blanc + fond papier
      def draw_frame(bm, x, y, w, h, top = C_PAPER_TOP, bot = C_PAPER_BOT)
        pkmn_rect(bm, x,     y,     w,     h,     C_NAVY)
        pkmn_rect(bm, x + 1, y + 1, w - 2, h - 2, Color.new(88, 128, 208))
        pkmn_rect(bm, x + 2, y + 2, w - 4, h - 4, C_WHITE)
        draw_gradient_bg(bm, x + 3, y + 3, w - 6, h - 6, top, bot)
      end

      # Bandeau coloré (en-tête)
      def draw_header_bar(bm, x, y, w, h, theme)
        top, bot, dk = THEMES[theme] || THEMES[:blue]
        pkmn_rect(bm, x, y, w, h, dk)
        draw_gradient_bg(bm, x + 1, y + 1, w - 2, h - 3, top, bot)
        bm.fill_rect(x + 2, y + 1, w - 4, 1, Color.new(255, 255, 255, 130))
      end

      def draw_pill(bm, x, y, w, h, tint, label)
        pkmn_rect(bm, x, y, w, h, darker(tint))
        pkmn_rect(bm, x + 1, y + 1, w - 2, h - 3, tint)
        # Centre le texte verticalement dans la pill
        txt(bm, x, y + 1, w, h - 2, label, FONT_SMALL, :light, 1)
      end

      # Touche de clavier en relief. label = String ou :arrows
      def draw_key_cap(bm, x, y, label, w)
        pkmn_rect(bm, x, y, w, 20, C_NAVY)
        draw_gradient_bg(bm, x + 1, y + 1, w - 2, 15, C_WHITE, Color.new(214, 222, 238))
        if label == :arrows
          draw_arrow(bm, x + w / 2 - 6, y + 8, 0, 4, C_NAVY)
          draw_arrow(bm, x + w / 2 + 6, y + 8, 2, 4, C_NAVY)
        else
          txt(bm, x, y + 1, w, 16, label, FONT_SMALL, :dark, 1)
        end
      end

      # Flèche pleine. dir : 0 haut, 1 droite, 2 bas, 3 gauche
      def draw_arrow(bm, cx, cy, dir, s, col)
        s.times do |i|
          case dir
          when 0 then bm.fill_rect(cx - i, cy - s / 2 + i, 1 + i * 2, 1, col)
          when 2 then bm.fill_rect(cx - (s - 1 - i), cy - s / 2 + i, 1 + (s - 1 - i) * 2, 1, col)
          when 1 then bm.fill_rect(cx - s / 2 + i, cy - (s - 1 - i), 1, 1 + (s - 1 - i) * 2, col)
          when 3 then bm.fill_rect(cx - s / 2 + i, cy - i, 1, 1 + i * 2, col)
          end
        end
      end

      def draw_brackets(bm, x, y, w, h, len, thick, col)
        bm.fill_rect(x,             y,             len,   thick, col)
        bm.fill_rect(x,             y,             thick, len,   col)
        bm.fill_rect(x + w - len,   y,             len,   thick, col)
        bm.fill_rect(x + w - thick, y,             thick, len,   col)
        bm.fill_rect(x,             y + h - thick, len,   thick, col)
        bm.fill_rect(x,             y + h - len,   thick, len,   col)
        bm.fill_rect(x + w - len,   y + h - thick, len,   thick, col)
        bm.fill_rect(x + w - thick, y + h - len,   thick, len,   col)
      end

      # Mini-grille représentant l'empreinte du meuble
      def draw_mini_grid(bm, x, y, fw, fh, cell, tint)
        bm.fill_rect(x - 1, y - 1, fw * cell + 1, fh * cell + 1, C_NAVY)
        fh.times do |j|
          fw.times do |i|
            bm.fill_rect(x + i * cell, y + j * cell, cell - 1, cell - 1, tint)
          end
        end
      end

      # =========================================================================
      # ANIMATION / POSITIONS DES HUD
      # =========================================================================
      def ease_out(t)
        1.0 - (1.0 - t.to_f.clamp(0.0, 1.0)) ** 3
      end

      def update_ui_animation
        @ui_t  = [@ui_t + 0.14, 1.0].min if @ui_t < 1.0
        @inv_t = [@inv_t + 0.16, 1.0].min if (@inv_open || @paint_mode) && @inv_t < 1.0
        diff = @panel_target - @panel_t
        if diff.abs < 0.02
          @panel_t = @panel_target
        else
          @panel_t += diff * 0.35
        end
        apply_hud_positions
      end

      def apply_hud_positions
        gw = Graphics.width  rescue 512
        gh = Graphics.height rescue 384
        e  = ease_out(@ui_t)

        if @hud_bottom && !@hud_bottom.disposed? && @hud_bottom.bitmap
          bh = @hud_bottom.bitmap.height
          if active?
            @hud_bottom.x = 0
            @hud_bottom.y = gh - BOTTOM_H + ((1.0 - e) * bh).to_i
          else
            @hud_bottom.x = 6
            @hud_bottom.y = gh - bh - 6
          end
          @hud_bottom.visible = true
        end

        if @hud_title && !@hud_title.disposed?
          @hud_title.x = 6
          @hud_title.y = 6 - ((1.0 - e) * (TITLE_H + 8)).to_i
          @hud_title.visible = !@inv_open && !@hud_title.bitmap.nil?
        end

        if @hud_panel && !@hud_panel.disposed?
          pe = ease_out(@panel_t)
          @hud_panel.x = gw - PANEL_W - 6 + ((1.0 - pe) * (PANEL_W + 12)).to_i
          @hud_panel.y = 6
          @hud_panel.visible = (@panel_t > 0.02 && !@hud_panel.bitmap.nil?)
        end

        if @hud_inv && !@hud_inv.disposed? && @hud_inv.bitmap
          ie = ease_out(@inv_t)
          @hud_inv.x = 6 - ((1.0 - ie) * (INV_W + 12)).to_i
          @hud_inv.y = 6
          @hud_inv.visible = true
        end

        if @hud_error && !@hud_error.disposed? && @hud_error.bitmap
          @hud_error.x = (gw - @hud_error.bitmap.width) / 2
          @hud_error.y = gh - BOTTOM_H - @hud_error.bitmap.height - 6
        end
      end

      # =========================================================================
      # BARRE DU BAS : message + touches
      # =========================================================================
      def create_hud_bottom
        dispose_hud_bottom
        @hud_bottom = Sprite.new
        @hud_bottom.z = 600
      end

      def dispose_hud_bottom
        @hud_bottom&.bitmap&.dispose
        @hud_bottom&.dispose unless @hud_bottom&.disposed?
        @hud_bottom = nil
      end

      def bottom_message
        if @paint_mode
          if @paint_step == :select_style
            "Choisis un motif dans le catalogue à gauche, puis appuie sur Entrée."
          else
            style = Housing.floor_styles[@selected_floor_style] rescue nil
            name  = style ? style[:name] : "Motif"
            if @zone_start
              sx, sy = @zone_start
              w = ([sx, @cursor_x].max - [sx, @cursor_x].min + 1)
              h = ([sy, @cursor_y].max - [sy, @cursor_y].min + 1)
              "Zone #{w}×#{h} (#{name}) : Appuie sur Entrée pour peindre cette zone."
            else
              "Peinture (#{name}) : Clique pour poser le 1er coin de la zone."
            end
          end
        elsif @inv_open
          "Choisis un meuble à installer dans la maison."
        elsif @held && @held_item
          name = Housing.furniture_name(@held_item)
          @held_is_moving ? "Où placer #{name} ?" : "Où installer #{name} ?"
        elsif @hover_item
          "#{Housing.furniture_name(@hover_item)} : Entrée pour le déplacer."
        else
          "Déplace le curseur. [P] Peindre le sol  [I] Inventaire"
        end
      end

      def bottom_chips
        if @paint_mode
          if @paint_step == :select_style
            [[:arrows, "Choisir motif"], ["Entrée", "Valider motif"], ["Échap", "Annuler"]]
          else
            if @zone_start
              [["Entrée", "Peindre Zone"], ["Échap", "Annuler Zone"]]
            else
              [["Entrée", "1er Coin Zone"], ["F", "Tout remplir"], ["C", "Changer motif"], ["P", "Quitter"]]
            end
          end
        elsif @inv_open
          [[:arrows, "Naviguer"], ["Entrée", "Choisir"], ["Échap", "Retour"]]
        elsif @held
          chips = [["Entrée", "Poser"], ["R", "Tourner"]]
          chips << ["X", "Ranger"] if @held_is_moving
          chips << ["Échap", "Annuler"]
          chips
        else
          [[:arrows, "Bouger"],
           ["Entrée", @hover_item ? "Saisir" : "Choisir"],
           ["P", "Peindre sol"],
           ["I", "Inventaire"],
           ["H", "Quitter"]]
        end
      end

      def draw_chips(bm, chips, x, y, max_x)
        chips.each do |label, action|
          kw = (label == :arrows) ? 34 : [measure(label, FONT_SMALL) + 14, 24].max
          aw = measure(action, FONT_SMALL)
          total = kw + 5 + aw
          break if x + total > max_x
          draw_key_cap(bm, x, y, label, kw)
          txt(bm, x + kw + 5, y, aw + 8, 22, action, FONT_SMALL, :dark)
          x += total + 14
        end
      end

      def refresh_hud_bottom
        return unless @hud_bottom && !@hud_bottom.disposed?
        gw = Graphics.width rescue 512
        if active?
          bm = Bitmap.new(gw, BOTTOM_H)
          draw_frame(bm, -6, 0, gw + 12, BOTTOM_H + 6)
          msg = fit_text(bottom_message, gw - 36, FONT_NORMAL)
          txt(bm, 12, 6, gw - 24, 20, msg, FONT_NORMAL, :dark)
          bm.fill_rect(10, 29, gw - 20, 1, C_LINE)
          draw_chips(bm, bottom_chips, 12, 33, gw - 12)
        else
          label = "Décorer la maison"
          lw = measure(label, FONT_SMALL)
          w  = 8 + 24 + 6 + lw + 18
          h  = 30
          bm = Bitmap.new(w, h)
          draw_frame(bm, 0, 0, w, h)
          draw_key_cap(bm, 8, 5, "H", 24)
          txt(bm, 8 + 24 + 6, 5, lw + 8, 20, label, FONT_SMALL, :dark)
        end
        @hud_bottom.bitmap&.dispose
        @hud_bottom.bitmap = bm
        apply_hud_positions
      end

      # =========================================================================
      # FICHE MEUBLE (panneau droit)
      # =========================================================================
      def create_hud_panel
        dispose_hud_panel
        @hud_panel = Sprite.new
        @hud_panel.z = 600
      end

      def dispose_hud_panel
        @hud_panel&.bitmap&.dispose
        @hud_panel&.dispose unless @hud_panel&.disposed?
        @hud_panel = nil
      end

      def panel_item
        if @inv_open
          g = inventory_groups[@inv_index]
          return g ? g[:item] : nil
        end
        @held_item || @hover_item
      end

      def refresh_hud_panel
        return unless @hud_panel && !@hud_panel.disposed?
        if @paint_mode
          @panel_target = 0.0
          @hud_panel.visible = false
          return
        end

        item = panel_item
        unless item
          @panel_target = 0.0
          return
        end
        @panel_target = 1.0

        held_now = (@held && @held_item && !@inv_open) ? true : false
        theme, status =
          if @inv_open then [:blue, "Inventaire"]
          elsif held_now && @held_is_moving then [:gold, "Déplacement"]
          elsif held_now then [:green, "En main"]
          else [:blue, "Meuble posé"]
          end

        inner_w = PANEL_W - 16
        lines   = wrap_text(Housing.furniture_name(item), inner_w, FONT_NORMAL, 2)
        rot     = held_now ? @rot.to_i : item[:rot].to_i
        fw, fh  = effective_footprint(item[:footprint_w].to_i, item[:footprint_h].to_i, rot)
        fw = [fw, 1].max; fh = [fh, 1].max
        cell    = [[12, 60 / fw, 34 / fh].min, 3].max
        gpw     = fw * cell
        gph     = fh * cell
        block_h = [gph + 8, 34].max

        line_h  = 20
        h = 28 + lines.length * line_h + 4 + 24 + 6 + block_h + 6
        h += 22 if held_now
        h += 28 if held_now
        h += 4

        bm = Bitmap.new(PANEL_W, h)
        draw_frame(bm, 0, 0, PANEL_W, h)
        draw_header_bar(bm, 3, 3, PANEL_W - 6, 22, theme)
        txt(bm, 3, 4, PANEL_W - 6, 18, status, FONT_SMALL, :light, 1)

        y = 32
        lines.each do |l|
          txt(bm, 8, y, inner_w, line_h, l, FONT_NORMAL, :dark)
          y += line_h
        end
        y += 4

        # Catégorie
        cat   = item[:category].to_s
        label = cat_label(item)
        tint  = CATEGORY_TINTS.fetch(cat, DEFAULT_TINT)
        pw    = measure(label, FONT_SMALL) + 16
        draw_pill(bm, 8, y, pw, 22, tint, label)
        y += 28

        # Taille + mini-grille
        txt(bm, 8, y, 60, 16, "Taille", FONT_SMALL, :grey)
        txt(bm, 8, y + 18, 70, line_h, "#{fw} × #{fh}", FONT_NORMAL, :dark)
        draw_mini_grid(bm, PANEL_W - 12 - gpw, y + 2, fw, fh, cell, tint)
        y += block_h + 6

        if held_now
          # Rotation
          txt(bm, 8, y, 70, 16, "Rotation", FONT_SMALL, :grey)
          rtxt = "#{@rot.to_i}°"
          txt(bm, 8, y + 2, PANEL_W - 16, line_h, rtxt, FONT_NORMAL, :dark, 2)
          y += 22

          # Validité du placement
          ok = valid_position?(@cursor_x, @cursor_y, fw, fh)
          draw_header_bar(bm, 3, y, PANEL_W - 6, 22, ok ? :green : :red)
          txt(bm, 3, y + 4, PANEL_W - 6, 16, ok ? "Placement possible" : "Placement impossible",
              FONT_SMALL, :light, 1)
        end

        @hud_panel.bitmap&.dispose
        @hud_panel.bitmap = bm
        apply_hud_positions
      end

      # =========================================================================
      # BANDEAU TITRE (haut gauche)
      # =========================================================================
      def create_hud_title
        dispose_hud_title
        @hud_title = Sprite.new
        @hud_title.z = 601
      end

      def dispose_hud_title
        @hud_title&.bitmap&.dispose
        @hud_title&.dispose unless @hud_title&.disposed?
        @hud_title = nil
      end

      def refresh_hud_title
        return unless @hud_title && !@hud_title.disposed?
        bm = Bitmap.new(TITLE_W, TITLE_H)
        draw_frame(bm, 0, 0, TITLE_W, TITLE_H)
        if @paint_mode
          if @paint_step == :select_style
            draw_header_bar(bm, 3, 3, TITLE_W - 6, 18, :gold)
            txt(bm, 3, 2, TITLE_W - 6, 18, "PEINTURE SOL", FONT_SMALL, :light, 1)
            txt(bm, 4, 23, TITLE_W - 8, 18, "Choisir un motif", FONT_SMALL, :dark, 1)
          else # :select_zone
            style = Housing.floor_styles[@selected_floor_style]
            name  = style ? style[:name] : "Motif"
            draw_header_bar(bm, 3, 3, TITLE_W - 6, 18, :gold)
            txt(bm, 3, 2, TITLE_W - 6, 18, "SOL : #{name.upcase}", FONT_SMALL, :light, 1)

            pkmn_rect(bm, 8, 23, 18, 18, C_NAVY)
            tile_bm = Housing.build_floor_tile_bitmap(@selected_floor_style)
            bm.stretch_blt(Rect.new(9, 24, 16, 16), tile_bm, Rect.new(0, 0, 32, 32))
            tile_bm.dispose

            txt(bm, 30, 23, TITLE_W - 34, 18, "Clic: Changer", FONT_SMALL, :dark, 0)
          end
        else
          draw_header_bar(bm, 3, 3, TITLE_W - 6, 18, :blue)
          txt(bm, 3, 2, TITLE_W - 6, 18, "DÉCORATION", FONT_SMALL, :light, 1)
          n_placed = Housing.state&.dig(:placed)&.length || 0
          n_inv    = Housing.state&.dig(:inventory)&.length || 0
          txt(bm, 4, 23, TITLE_W - 8, 18, "Posés #{n_placed}   Inventaire #{n_inv}", FONT_SMALL, :dark, 1)
        end
        @hud_title.bitmap&.dispose
        @hud_title.bitmap = bm
        apply_hud_positions
      end

      # =========================================================================
      # BULLE D'ERREUR
      # =========================================================================
      def show_error(msg)
        @error_msg   = msg.to_s
        @error_until = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2.5
        refresh_hud_error
      end

      def update_hud_error_tick
        return unless @error_msg
        remaining = @error_until - Process.clock_gettime(Process::CLOCK_MONOTONIC)
        if remaining <= 0
          @error_msg = nil
          dispose_hud_error
          return
        end
        if @hud_error && !@hud_error.disposed?
          @hud_error.opacity = (255 * [remaining / 0.4, 1.0].min).to_i
        end
      end

      def refresh_hud_error
        dispose_hud_error
        return unless @error_msg
        tw = measure(@error_msg, FONT_NORMAL)
        w  = tw + 46
        h  = 30
        bm = Bitmap.new(w, h)
        draw_frame(bm, 0, 0, w, h, Color.new(255, 246, 242), Color.new(255, 224, 216))
        red = THEMES[:red]
        pkmn_rect(bm, 6, 5, 20, 20, red[2])
        pkmn_rect(bm, 7, 6, 18, 17, red[1])
        txt(bm, 6, 4, 20, 20, "!", FONT_NORMAL, :light, 1)
        txt(bm, 32, 3, tw + 10, 24, @error_msg, FONT_NORMAL, :dark)
        @hud_error = Sprite.new
        @hud_error.z = 700
        @hud_error.bitmap = bm
        apply_hud_positions
        @hud_error.visible = true
      end

      def dispose_hud_error
        @hud_error&.bitmap&.dispose
        @hud_error&.dispose unless @hud_error&.disposed?
        @hud_error = nil
      end
    end
  end
end

# ─── Hook Scene_Map#update ──────────────────────────────────────────────────
class Scene_Map
  unless method_defined?(:pemk_housing_editor_orig_update)
    alias_method :pemk_housing_editor_orig_update, :update
  end

  def update
    if $scene.is_a?(Scene_Map) && $game_map && PEMK::Housing.is_house_map?($game_map.map_id) && PEMK::Housing.state
      PEMK::HousingEditor.update
    else
      PEMK::HousingEditor.dispose_all if defined?(PEMK::HousingEditor)
    end
    pemk_housing_editor_orig_update
  end
end

# ─── Option Menu Pause "Décorer ma maison" ──────────────────────────────────
if defined?(MenuHandlers)
  MenuHandlers.add(:pause_menu, :mmo_housing_edit, {
    "name"      => _INTL("Décorer ma maison"),
    "order"     => 45,
    "condition" => proc {
      next PEMK::Housing.state &&
           $game_map &&
           $game_map.map_id == PEMK::Housing::MAP_FOR_TIER[PEMK::Housing.state[:size_tier]]
    },
    "effect"    => proc { |menu|
      menu.pbHideMenu
      PEMK::HousingEditor.start
      menu.pbEndScene
      next true
    }
  })
end