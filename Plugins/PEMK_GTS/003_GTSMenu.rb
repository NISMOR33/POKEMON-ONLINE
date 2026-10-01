#===============================================================================
# PEMK_GTS :: 003 Menu (UI Interface)  -  v2 "Hôtel des ventes" (design pro)
#-------------------------------------------------------------------------------
# Interface du Global Trade System, refonte complète du design :
# thème sombre type place de marché, tableau d'annonces, fiche détaillée,
# badges, survols souris, tri, indicateur de connexion.
#
#   +----------------------------------------------------------------+
#   | (o) HÔTEL DES VENTES                          [ SOLDE  1 250 $ ]|
#   |     Marché des dresseurs                                        |
#   |  ACHETER   VENDRE   MES VENTES                                  |
#   | [Tous|Pokémon|Objets] F             [ (Q) Rechercher...     R ] |
#   | +-------------------------------------+ +--------------------+  |
#   | | ANNONCES (3)           [S] Tri: ... | | FICHE ANNONCE      |  |
#   | |>[ico] Nom            1 000 $        | |  [icône]           |  |
#   | |       par Vendeur    [PRIX FIXE]    | |  Nom  [POKÉMON]    |  |
#   | |  ...                                | |  PV / Vendeur      |  |
#   | +-------------------------------------+ |  Prix  [ACHETER]   |  |
#   |                                         +--------------------+  |
#   | [Entrée] Acheter  [^v] Liste  [<>] Onglets  [Échap] Quitter  *  |
#   +----------------------------------------------------------------+
#
# Onglets :
#   Acheter     - liste des annonces, filtres (F), recherche (R), tri (S), achat (Entrée)
#   Vendre      - mise en vente d'un Pokémon ou d'un objet du sac
#   Mes ventes  - annonces actives + gains à récupérer (Entrée / T = tout)
#
# Souris : onglets, filtres, tri, lignes, boutons et molette (avec survol).
# Toutes les confirmations / saisies utilisent des fenêtres intégrées au style.
#
# Réglages rapides : constantes FONT_* et USE_SYSTEM_FONT, palette C_* / THEMES.
#
# NB : le tri (touche S) est appliqué côté client sur les annonces reçues.
#===============================================================================
module PEMK
  module GTSMenu
    @active       = false
    @tab          = :browse       # :browse, :create, :mine
    @sub_type     = "all"         # "all", "pokemon", "item"
    @category_idx = 0
    @sort_idx     = 0
    @selected_idx = 0
    @scroll_top   = 0
    @create_idx   = 0
    @mine_idx     = 0
    @mine_scroll  = 0
    @search_query = ""
    @view_detail  = nil
    @dirty        = true
    @tick         = 0
    @open_t       = 0.0
    @hits         = []
    @hover        = nil
    @last_mouse   = nil
    @icon_cache   = {}
    @measure_bm   = nil
    @toast_sprite = nil
    @toast_frames = 0

    # ─── Dimensions ─────────────────────────────────────────────────────────────
    HEADER_H   = 44
    TAB_Y      = 44
    TAB_H      = 28
    FOOT_H     = 26
    ROW_H      = 40
    ROW_GAP    = 2
    DETAIL_W   = 172
    PANEL_HEAD = 22

    # ─── Polices ────────────────────────────────────────────────────────────────
    USE_SYSTEM_FONT = true
    FONT_TITLE  = 24
    FONT_NORMAL = 21
    FONT_SMALL  = 17
    FONT_TAG    = 16

    # ─── Palette (thème sombre) ─────────────────────────────────────────────────
    C_BG_TOP    = Color.new(9,  13, 26)
    C_BG_BOT    = Color.new(20, 29, 54)
    C_HEAD_TOP  = Color.new(16, 26, 56)
    C_HEAD_BOT  = Color.new(10, 16, 36)
    C_PANEL     = Color.new(22, 31, 56)
    C_PANEL_HI  = Color.new(33, 46, 82)
    C_PANEL_LO  = Color.new(14, 20, 40)
    C_EDGE      = Color.new(50, 66, 106)
    C_EDGE_LT   = Color.new(88, 110, 164)
    C_EDGE_DK   = Color.new(34, 46, 78)
    C_ROW       = Color.new(25, 35, 63)
    C_ROW_ALT   = Color.new(21, 30, 55)
    C_ROW_HOV   = Color.new(34, 47, 84)
    C_INK       = Color.new(8,  12, 26)
    C_LINE      = Color.new(46, 60, 96)
    C_ACCENT    = Color.new(92, 200, 244)
    C_GOLD      = Color.new(248, 196, 78)
    C_GOLD_DK   = Color.new(150, 104, 24)
    C_GREEN     = Color.new(96, 220, 140)
    C_RED       = Color.new(250, 100, 96)
    C_BLUE      = Color.new(104, 156, 250)
    C_ORANGE    = Color.new(244, 156, 64)
    C_MUTED     = Color.new(142, 156, 190)
    C_TEXT      = Color.new(236, 241, 252)
    C_WHITE     = Color.new(255, 255, 255)

    # [haut, bas, bordure] (boutons / barres)
    THEMES = {
      :blue  => [Color.new(104, 160, 250), Color.new(52,  100, 204), Color.new(22, 46, 120)],
      :gold  => [Color.new(250, 208, 92),  Color.new(222, 148, 34),  Color.new(120, 72, 12)],
      :green => [Color.new(100, 216, 144), Color.new(38,  152, 90),  Color.new(14, 82, 48)],
      :red   => [Color.new(242, 116, 108), Color.new(190, 52,  58),  Color.new(100, 20, 30)],
      :slate => [Color.new(74,  92,  136), Color.new(48,  62,  100), Color.new(24, 32, 62)],
    }

    # [texte, ombre]
    TONES = {
      :text   => [Color.new(236, 241, 252), Color.new(0, 0, 0, 120)],
      :muted  => [Color.new(142, 156, 190), Color.new(0, 0, 0, 100)],
      :dim    => [Color.new(96,  110, 146), nil],
      :light  => [Color.new(255, 255, 255), Color.new(0, 0, 0, 130)],
      :gold   => [Color.new(250, 200, 84),  Color.new(60, 36, 0, 140)],
      :title  => [Color.new(255, 228, 124), Color.new(60, 36, 0, 170)],
      :red    => [Color.new(255, 122, 114), Color.new(60, 0, 0, 120)],
      :green  => [Color.new(110, 226, 152), Color.new(0, 40, 16, 120)],
      :cyan   => [Color.new(124, 212, 250), Color.new(0, 24, 48, 120)],
      :blue   => [Color.new(128, 176, 255), Color.new(0, 16, 56, 120)],
      :orange => [Color.new(250, 174, 92),  Color.new(56, 24, 0, 120)],
    }

    TAG_COLORS = {
      :blue => C_BLUE, :orange => C_ORANGE, :green => C_GREEN,
      :gold => C_GOLD, :red => C_RED, :muted => C_MUTED, :cyan => C_ACCENT,
    }

    TABS    = [[:browse, "Acheter"], [:create, "Vendre"], [:mine, "Mes ventes"]]
    FILTERS = [["all", "Tous"], ["pokemon", "Pokémon"], ["item", "Objets"]]
    SORTS   = [["recent", "Récent"], ["price_asc", "Prix croissant"],
               ["price_desc", "Prix décroissant"], ["name", "Nom A-Z"]]

    class << self
      def active?
        @active
      end

      def open
        return if @active
        @active       = true
        @tab          = :browse
        @sub_type     = "all"
        @category_idx = 0
        @sort_idx     = 0
        @selected_idx = 0
        @scroll_top   = 0
        @create_idx   = 0
        @mine_idx     = 0
        @mine_scroll  = 0
        @search_query = ""
        @view_detail  = nil
        @tick         = 0
        @open_t       = 0.0
        @hits         = []
        @hover        = nil
        @last_mouse   = nil
        @dirty        = true

        $game_temp.in_menu = true if $game_temp

        create_ui
        fetch_listings
        main_loop
      end

      def close
        return unless @active
        @active = false
        dispose_ui
        $game_temp.in_menu = false if $game_temp
      end

      def on_data_received
        return unless @active
        clamp_selection
        @dirty = true
      end

      private

      # =========================================================================
      # CYCLE DE VIE
      # =========================================================================
      def create_ui
        gw = Graphics.width
        gh = Graphics.height
        @viewport = Viewport.new(0, 0, gw, gh)
        @viewport.z = 99999

        @bg_sprite = Sprite.new(@viewport)
        @bg_sprite.bitmap = Bitmap.new(gw, gh)
        @bg_sprite.opacity = 0

        @content_sprite = Sprite.new(@viewport)
        @content_sprite.bitmap = Bitmap.new(gw, gh)
        @content_sprite.z = 1
        @content_sprite.opacity = 0

        draw_background
        @dirty = true
      end

      def dispose_ui
        dispose_toast
        @bg_sprite&.bitmap&.dispose
        @bg_sprite&.dispose
        @bg_sprite = nil

        @content_sprite&.bitmap&.dispose
        @content_sprite&.dispose
        @content_sprite = nil

        @viewport&.dispose
        @viewport = nil

        (@icon_cache || {}).each_value { |b| b.dispose if b && !b.disposed? }
        @icon_cache = {}
        @measure_bm&.dispose unless @measure_bm&.disposed?
        @measure_bm = nil
      end

      def main_loop
        while @active
          Graphics.update
          Input.update
          @tick += 1
          update_fade
          update_toast
          update_input
          break unless @active
          PEMK::GTS.sync_to_file if @tick % 60 == 0 rescue nil
          @dirty = true if loading? && @tick % 6 == 0
          if @dirty
            @dirty = false
            draw_content
          end
        end
      end

      def update_fade
        return if @open_t >= 1.0
        @open_t = [@open_t + 0.15, 1.0].min
        o = (255 * (1.0 - (1.0 - @open_t) ** 3)).to_i
        @bg_sprite.opacity = o if @bg_sprite
        @content_sprite.opacity = o if @content_sprite
      end

      def loading?
        return false unless (PEMK::GTS.is_loading rescue false)
        return false if PEMK::GTS.listings && !PEMK::GTS.listings.empty?
        return false unless PEMK::GTS.connected?
        true
      end

      def connected?
        (PEMK::GTS.connected? rescue false) ? true : false
      end

      def fetch_listings
        @selected_idx = 0
        @scroll_top   = 0
        @dirty        = true
        PEMK::GTS.send_fetch_listings(@sub_type, "all", @search_query, "recent", 1)
      end

      # Liste affichée (tri client appliqué)
      def browse_list
        src  = PEMK::GTS.listings || []
        mode = SORTS[@sort_idx % SORTS.length][0]
        return src if mode == "recent" || src.size < 2
        i = -1
        tagged = src.map { |it| i += 1; [it, i] }
        case mode
        when "price_asc"  then tagged.sort_by { |it, n| [lget(it, :price, 0).to_i, n] }.map(&:first)
        when "price_desc" then tagged.sort_by { |it, n| [-lget(it, :price, 0).to_i, n] }.map(&:first)
        when "name"       then tagged.sort_by { |it, n| [lget(it, :title, "").to_s.downcase, n] }.map(&:first)
        else src
        end
      end

      def cycle_sort
        @sort_idx = (@sort_idx + 1) % SORTS.length
        @selected_idx = 0
        @scroll_top   = 0
        @dirty = true
      end

      def clamp_selection
        size = browse_list.size
        @selected_idx = size == 0 ? 0 : @selected_idx.clamp(0, size - 1)
        rows = browse_geo[:rows]
        @scroll_top = @selected_idx if @selected_idx < @scroll_top
        @scroll_top = @selected_idx - rows + 1 if @selected_idx >= @scroll_top + rows
        @scroll_top = [[@scroll_top, size - rows].min, 0].max
        claims = (PEMK::GTS.pending_claim || []).size
        @mine_idx = claims == 0 ? 0 : @mine_idx.clamp(0, claims - 1)
      end

      # =========================================================================
      # ENTRÉES
      # =========================================================================
      def trig?(*names)
        names.any? { |n| Input.const_defined?(n) && Input.trigger?(Input.const_get(n)) }
      rescue
        false
      end

      def rep?(*names)
        names.any? { |n| Input.const_defined?(n) && Input.repeat?(Input.const_get(n)) }
      rescue
        false
      end

      def kx?(sym)
        Input.respond_to?(:triggerex?) && Input.triggerex?(sym)
      rescue
        false
      end

      def cancel?
        trig?(:BACK, :B) || kx?(:RBUTTON)
      end

      def use?
        trig?(:USE, :C)
      end

      def lclick?
        kx?(:LBUTTON)
      end

      def mouse_pos
        return nil unless Input.respond_to?(:mouse_x)
        mx = Input.mouse_x; my = Input.mouse_y
        return nil if mx.nil? || my.nil? || mx < 0 || my < 0
        [mx, my]
      rescue
        nil
      end

      def mouse_moved?
        pos = mouse_pos
        return false unless pos
        moved = (pos != @last_mouse)
        @last_mouse = pos
        moved
      end

      def hover?(type, idx = nil)
        @hover && @hover[0] == type && (idx.nil? || @hover[1] == idx)
      end

      def update_input
        if cancel?
          close
          return
        end

        moved = mouse_moved?

        if trig?(:RIGHT)
          switch_tab(1)
        elsif trig?(:LEFT)
          switch_tab(-1)
        end

        case @tab
        when :browse then input_browse
        when :create then input_create
        when :mine   then input_mine
        end
        return unless @active

        handle_mouse(moved)
      end

      def switch_tab(dir)
        idx = TABS.index { |t| t[0] == @tab } || 0
        @tab = TABS[(idx + dir) % TABS.length][0]
        @dirty = true
      end

      def input_browse
        if rep?(:DOWN)
          move_selection(1)
        elsif rep?(:UP)
          move_selection(-1)
        end
        wheel_move { |d| move_selection(d) }

        if kx?(:F)
          set_filter((FILTERS.index { |f| f[0] == @sub_type } || 0) + 1)
        elsif kx?(:R)
          do_search
        elsif kx?(:S)
          cycle_sort
        elsif use?
          handle_browse_selection
        end
      end

      def input_create
        if trig?(:DOWN)
          @create_idx = [@create_idx + 1, 1].min
          @dirty = true
        elsif trig?(:UP)
          @create_idx = [@create_idx - 1, 0].max
          @dirty = true
        end
        handle_create_selection if use?
      end

      def input_mine
        if rep?(:DOWN)
          move_claim(1)
        elsif rep?(:UP)
          move_claim(-1)
        end
        wheel_move { |d| move_claim(d) }

        if kx?(:T)
          claim_all
        elsif use?
          handle_mine_selection
        end
      end

      def wheel_move
        return unless Input.respond_to?(:scroll_v)
        sv = Input.scroll_v
        yield(-sv.to_i.clamp(-1, 1)) if sv && sv != 0
      rescue
        nil
      end

      def move_selection(delta)
        size = browse_list.size
        return if size == 0
        new_idx = (@selected_idx + delta).clamp(0, size - 1)
        return if new_idx == @selected_idx
        @selected_idx = new_idx
        clamp_selection
        @dirty = true
      end

      def move_claim(delta)
        size = (PEMK::GTS.pending_claim || []).size
        return if size == 0
        new_idx = (@mine_idx + delta).clamp(0, size - 1)
        return if new_idx == @mine_idx
        @mine_idx = new_idx
        vis = mine_rows
        @mine_scroll = @mine_idx if @mine_idx < @mine_scroll
        @mine_scroll = @mine_idx - vis + 1 if @mine_idx >= @mine_scroll + vis
        @mine_scroll = [@mine_scroll, 0].max
        @dirty = true
      end

      def set_filter(idx)
        @sub_type = FILTERS[idx % FILTERS.length][0]
        fetch_listings
      end

      def do_search
        unless defined?(pbEnterText)
          show_toast("Saisie indisponible", :red)
          return
        end
        q = nil
        @viewport.visible = false
        begin
          q = pbEnterText(_INTL("Rechercher une annonce :"), 0, 24, @search_query)
        ensure
          @viewport.visible = true if @viewport && !@viewport.disposed?
        end
        return if q.nil?
        @search_query = q.to_s.strip
        fetch_listings
      end

      # ── Souris ─────────────────────────────────────────────────────────────
      def hit_at(pos)
        @hits.reverse.find do |r|
          pos[0] >= r[0] && pos[0] < r[0] + r[2] && pos[1] >= r[1] && pos[1] < r[1] + r[3]
        end
      end

      def handle_mouse(moved)
        pos = mouse_pos
        return unless pos
        if moved
          h  = hit_at(pos)
          nh = h ? [h[4], h[5]] : nil
          if nh != @hover
            @hover = nh
            @dirty = true
          end
          if h
            case h[4]
            when :row
              if @selected_idx != h[5]
                @selected_idx = h[5]; @dirty = true
              end
            when :create_card
              if @create_idx != h[5]
                @create_idx = h[5]; @dirty = true
              end
            when :claim
              if @mine_idx != h[5]
                @mine_idx = h[5]; @dirty = true
              end
            end
          end
        end
        return unless lclick?
        h = hit_at(pos)
        return unless h
        case h[4]
        when :tab
          @tab = h[5]; @dirty = true
        when :filter
          set_filter(h[5])
        when :search
          do_search
        when :sort
          cycle_sort
        when :row
          @selected_idx = h[5]
          handle_browse_selection
        when :buy
          handle_browse_selection
        when :create_card
          @create_idx = h[5]
          handle_create_selection
        when :claim
          @mine_idx = h[5]
          handle_mine_selection
        when :cancel_listing
          cancel_active_listing(h[5])
        when :claim_all
          claim_all
        end
      end

      # =========================================================================
      # DONNÉES D'ANNONCES
      # =========================================================================
      def lget(h, key, default = nil)
        return default unless h.respond_to?(:[]) && !h.is_a?(String)
        v = h[key]
        v = h[key.to_s] if v.nil?
        v.nil? ? default : v
      rescue
        default
      end

      def fmt(n)
        [n.to_i, 0].max.to_s.reverse.scan(/\d{1,3}/).join(" ").reverse
      end

      def player_money
        if defined?($player) && $player && $player.respond_to?(:money)
          return ($player.money rescue 0).to_i
        elsif defined?($Trainer) && $Trainer && $Trainer.respond_to?(:money)
          return ($Trainer.money rescue 0).to_i
        end
        0
      end

      def player_party
        if defined?($player) && $player && $player.respond_to?(:party)
          return ($player.party rescue []) || []
        elsif defined?($Trainer) && $Trainer && $Trainer.respond_to?(:party)
          return ($Trainer.party rescue []) || []
        end
        []
      end

      def auction?(item)
        lget(item, :price_type, "fixed").to_s == "auction"
      end

      def listing_kind(item)
        k = (lget(item, :listing_type) || lget(item, :type) || lget(item, :kind) || lget(item, :category)).to_s.downcase
        return "pokemon" if k.include?("poke")
        return "item" if k.include?("item") || k.include?("obj")
        lget(item, :title).to_s.include?("Niv.") ? "pokemon" : "item"
      end

      def listing_payload(item)
        d = lget(item, :data) || lget(item, :payload) || lget(item, :pokemon_data) || lget(item, :item_data) || lget(item, :data_json)
        if d.is_a?(String)
          json_parser = (defined?(PEMK::HousingJSON) ? PEMK::HousingJSON : (defined?(HousingJSON) ? HousingJSON : nil))
          d = begin json_parser ? json_parser.parse(d, symbolize_names: true) : {} rescue {} end
        end
        d.is_a?(Hash) ? d : {}
      end

      def tax_for(price)
        [(price * PEMK::GTS::TAX_RATE).round, PEMK::GTS::MIN_LISTING_FEE].max
      end

      def tax_percent_text
        pct = PEMK::GTS::TAX_RATE * 100.0
        (pct == pct.to_i ? pct.to_i.to_s : pct.round(1).to_s) + " %"
      rescue
        "-"
      end

      def limit_reached?
        (PEMK::GTS.my_listings || []).size >= PEMK::GTS::MAX_ACTIVE_LISTINGS
      end

      # ── Icônes ─────────────────────────────────────────────────────────────
      def icon_bitmap(path)
        return nil if path.nil? || path.to_s.empty?
        b = @icon_cache[path]
        return b if b && !b.disposed?
        b = (Bitmap.new(path) rescue nil)
        @icon_cache[path] = b if b
        b
      end

      def species_icon_path(sp)
        return nil unless defined?(GameData::Species) && GameData::Species.respond_to?(:icon_filename)
        sym = sp.is_a?(Symbol) ? sp : sp.to_s.to_sym
        GameData::Species.icon_filename(sym)
      rescue
        nil
      end

      def item_icon_path(id)
        return nil unless defined?(GameData::Item) && GameData::Item.respond_to?(:icon_filename)
        sym = id.is_a?(Symbol) ? id : id.to_s.to_sym
        GameData::Item.icon_filename(sym)
      rescue
        nil
      end

      def pokemon_icon_path(pkmn)
        if defined?(GameData::Species) && GameData::Species.respond_to?(:icon_filename_from_pokemon)
          GameData::Species.icon_filename_from_pokemon(pkmn)
        elsif defined?(pbPokemonIconFile)
          pbPokemonIconFile(pkmn)
        end
      rescue
        nil
      end

      def listing_icon_bitmap(item)
        pl = listing_payload(item)
        path = nil
        if listing_kind(item) == "pokemon"
          sp = lget(pl, :species) || lget(item, :species)
          path = species_icon_path(sp) if sp
        else
          id = lget(pl, :item_id) || lget(item, :item_id)
          path = item_icon_path(id) if id
        end
        icon_bitmap(path)
      end

      # Dessine une icône source (cadre unique ou 2 frames) mise à l'échelle dans un carré
      def blit_icon(bm, src, x, y, size)
        return unless src && !src.disposed? && src.width > 0 && src.height > 0
        fw = (src.width >= src.height * 2) ? src.width / 2 : src.width
        fh = src.height
        s  = [size.to_f / fw, size.to_f / fh].min
        s  = s.floor if s > 1.0
        dw = [(fw * s).to_i, 1].max
        dh = [(fh * s).to_i, 1].max
        bm.stretch_blt(Rect.new(x + (size - dw) / 2, y + (size - dh) / 2, dw, dh), src, Rect.new(0, 0, fw, fh))
      end

      def draw_slot(bm, x, y, size, edge = C_EDGE)
        pkmn_rect(bm, x, y, size, size, edge)
        draw_gradient_bg(bm, x + 1, y + 1, size - 2, size - 2, Color.new(28, 40, 76), Color.new(15, 22, 44))
      end

      def draw_listing_icon(bm, item, x, y, size)
        draw_slot(bm, x, y, size)
        src = listing_icon_bitmap(item)
        if src
          blit_icon(bm, src, x + 2, y + 2, size - 4)
        elsif listing_kind(item) == "pokemon"
          draw_pokeball(bm, x + size / 2, y + size / 2, size / 2 - 4)
        else
          draw_bag_icon(bm, x + size / 2, y + size / 2, size - 12)
        end
      end

      # =========================================================================
      # OUTILS DE DESSIN
      # =========================================================================
      def set_font(bm, size)
        pbSetSystemFont(bm) if USE_SYSTEM_FONT && defined?(pbSetSystemFont)
        bm.font.size = size
        bm.font.bold = false
      end

      def measure(str, size)
        @measure_bm = Bitmap.new(8, 8) if @measure_bm.nil? || @measure_bm.disposed?
        set_font(@measure_bm, size)
        @measure_bm.text_size(str.to_s).width
      end

      def txt(bm, x, y, w, h, str, size = FONT_NORMAL, tone = :text, align = 0)
        set_font(bm, size)
        base, shadow = TONES[tone] || TONES[:text]
        s = str.to_s
        if shadow
          bm.font.color = shadow
          bm.draw_text(x + 1, y + 1, w, h, s, align)
        end
        bm.font.color = base
        bm.draw_text(x, y, w, h, s, align)
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

      def lighten(c, n = 24)
        Color.new([c.red + n, 255].min, [c.green + n, 255].min, [c.blue + n, 255].min)
      end

      # Rectangle aux coins coupés
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

      # Boîte plate : bordure 1px + remplissage
      def box(bm, x, y, w, h, edge, fill)
        pkmn_rect(bm, x, y, w, h, edge)
        pkmn_rect(bm, x + 1, y + 1, w - 2, h - 2, fill)
      end

      # Cadre simple (modales, toasts)
      def draw_frame(bm, x, y, w, h, top = C_PANEL, bot = C_PANEL_LO)
        pkmn_rect(bm, x, y, w, h, C_EDGE_LT)
        pkmn_rect(bm, x + 1, y + 1, w - 2, h - 2, C_INK)
        draw_gradient_bg(bm, x + 2, y + 2, w - 4, h - 4, top, bot)
      end

      # Panneau avec bandeau de titre
      def panel(bm, x, y, w, h, title = nil, accent = C_ACCENT)
        box(bm, x, y, w, h, C_EDGE, C_PANEL)
        return unless title
        draw_gradient_bg(bm, x + 1, y + 1, w - 2, PANEL_HEAD - 1, C_PANEL_HI, C_PANEL)
        bm.fill_rect(x + 1, y + PANEL_HEAD, w - 2, 1, C_EDGE)
        bm.fill_rect(x + 1, y + 2, 3, PANEL_HEAD - 3, accent)
        txt(bm, x + 10, y - 1, w - 20, PANEL_HEAD, title, FONT_SMALL, :muted)
      end

      def draw_header_bar(bm, x, y, w, h, theme)
        top, bot, dk = THEMES[theme] || THEMES[:blue]
        pkmn_rect(bm, x, y, w, h, dk)
        draw_gradient_bg(bm, x + 1, y + 1, w - 2, h - 3, top, bot)
        bm.fill_rect(x + 2, y + 1, w - 4, 1, Color.new(255, 255, 255, 110))
      end

      def draw_button(bm, x, y, w, h, theme, label, hover = false, size = FONT_SMALL)
        top, bot, dk = THEMES[theme] || THEMES[:blue]
        top = lighten(top) if hover
        bot = lighten(bot) if hover
        pkmn_rect(bm, x, y, w, h, dk)
        draw_gradient_bg(bm, x + 1, y + 1, w - 2, h - 3, top, bot)
        bm.fill_rect(x + 2, y + 1, w - 4, 1, Color.new(255, 255, 255, 110))
        txt(bm, x, y - 1, w, h, label, size, :light, 1)
      end

      # Badge coloré (retourne la largeur)
      def tag_width(label)
        measure(label, FONT_TAG) + 12
      end

      def draw_tag(bm, x, y, label, kind)
        col = TAG_COLORS[kind] || C_MUTED
        w = tag_width(label)
        box(bm, x, y, w, 16, darker(col, 0.5), darker(col, 0.2))
        txt(bm, x, y - 1, w, 16, label, FONT_TAG, kind, 1)
        w
      end

      def draw_mini_cap(bm, x, y, label)
        box(bm, x, y, 16, 16, C_EDGE_LT, Color.new(44, 58, 98))
        txt(bm, x, y - 1, 16, 16, label, FONT_TAG, :light, 1)
      end

      def draw_key_cap(bm, x, y, label, w)
        box(bm, x, y, w, 20, C_EDGE_LT, Color.new(44, 58, 98))
        bm.fill_rect(x + 2, y + 1, w - 4, 1, Color.new(255, 255, 255, 40))
        case label
        when :arrows
          draw_arrow(bm, x + w / 2 - 6, y + 8, 0, 4, C_TEXT)
          draw_arrow(bm, x + w / 2 + 6, y + 8, 2, 4, C_TEXT)
        when :lr
          draw_arrow(bm, x + w / 2 - 6, y + 8, 3, 4, C_TEXT)
          draw_arrow(bm, x + w / 2 + 6, y + 8, 1, 4, C_TEXT)
        else
          txt(bm, x, y - 1, w, 18, label, FONT_SMALL, :light, 1)
        end
      end

      def key_cap_width(label)
        return 34 if label == :arrows || label == :lr
        [measure(label, FONT_SMALL) + 12, 22].max
      end

      def draw_chips(bm, chips, x, y, max_x)
        chips.each do |label, action|
          kw = key_cap_width(label)
          aw = action ? measure(action, FONT_SMALL) : 0
          total = kw + (action ? 5 + aw : 0)
          break if x + total > max_x
          draw_key_cap(bm, x, y, label, kw)
          txt(bm, x + kw + 5, y - 1, aw + 6, 20, action, FONT_SMALL, :muted) if action
          x += total + 14
        end
      end

      # dir : 0 haut, 1 droite, 2 bas, 3 gauche
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

      def fill_circle(bm, cx, cy, r, col)
        ((-r)..r).each do |dy|
          dx = Math.sqrt([r * r - dy * dy, 0].max).round
          bm.fill_rect(cx - dx, cy + dy, dx * 2 + 1, 1, col)
        end
      end

      def draw_coin(bm, cx, cy, r = 6)
        fill_circle(bm, cx, cy, r,     Color.new(150, 98, 14))
        fill_circle(bm, cx, cy, r - 1, Color.new(252, 210, 70))
        fill_circle(bm, cx, cy, [r - 3, 1].max, Color.new(230, 166, 32))
        bm.fill_rect(cx - 1, cy - 2, 2, 5, Color.new(150, 98, 14))
      end

      def draw_pokeball(bm, cx, cy, r, dim = false)
        red = dim ? Color.new(96, 104, 128)  : Color.new(236, 68, 68)
        wht = dim ? Color.new(150, 158, 180) : Color.new(250, 250, 250)
        ((-r)..r).each do |dy|
          dx = Math.sqrt([r * r - dy * dy, 0].max).round
          bm.fill_rect(cx - dx, cy + dy, dx * 2 + 1, 1, C_INK)
          ix = Math.sqrt([(r - 1) * (r - 1) - dy * dy, 0].max).round
          next if ix <= 0
          c = dy < -1 ? red : (dy > 1 ? wht : C_INK)
          bm.fill_rect(cx - ix, cy + dy, ix * 2 + 1, 1, c)
        end
        b = [r / 3, 2].max
        fill_circle(bm, cx, cy, b + 1, C_INK)
        fill_circle(bm, cx, cy, b - 1, wht)
      end

      def draw_bag_icon(bm, cx, cy, s)
        orange = Color.new(228, 148, 56)
        x = cx - s / 2
        y = cy - s / 2
        pkmn_rect(bm, x, y + s / 4, s, s * 3 / 4, darker(orange))
        pkmn_rect(bm, x + 1, y + s / 4 + 1, s - 2, s * 3 / 4 - 3, orange)
        bm.fill_rect(x + 3, y + s / 2, s - 6, 2, darker(orange))
        bm.fill_rect(cx - s / 5, y, 2, s / 4 + 1, C_INK)
        bm.fill_rect(cx + s / 5 - 1, y, 2, s / 4 + 1, C_INK)
        bm.fill_rect(cx - s / 5, y, s * 2 / 5 + 1, 2, C_INK)
        bm.fill_rect(cx - 2, y + s / 2 - 1, 4, 5, Color.new(252, 210, 64))
      end

      def draw_search_icon(bm, cx, cy, col)
        fill_circle(bm, cx - 1, cy - 1, 5, col)
        fill_circle(bm, cx - 1, cy - 1, 3, C_PANEL_LO)
        3.times { |i| bm.fill_rect(cx + 3 + i, cy + 3 + i, 2, 2, col) }
      end

      def draw_spinner(bm, cx, cy)
        8.times do |i|
          a = i * Math::PI / 4
          px = cx + (Math.cos(a) * 14).round
          py = cy + (Math.sin(a) * 14).round
          phase = (i - (@tick / 4)) % 8
          alpha = [255 - phase * 28, 40].max
          bm.fill_rect(px - 2, py - 2, 5, 5, Color.new(92, 200, 244, alpha))
        end
      end

      def draw_bar(bm, x, y, w, h, ratio, top, bot)
        bm.fill_rect(x, y, w, h, C_EDGE)
        bm.fill_rect(x + 1, y + 1, w - 2, h - 2, C_PANEL_LO)
        fw = ((w - 2) * [[ratio, 0.0].max, 1.0].min).round
        draw_gradient_bg(bm, x + 1, y + 1, fw, h - 2, top, bot) if fw > 0
      end

      # Mise en page commune
      def lay
        gw = Graphics.width
        gh = Graphics.height
        py = TAB_Y + TAB_H + 6
        { :gw => gw, :gh => gh, :px => 6, :py => py, :pw => gw - 12, :ph => gh - FOOT_H - 6 - py }
      end

      def browse_geo
        l  = lay
        ix = l[:px]
        iw = l[:pw]
        ty = l[:py]
        list_y = ty + 24 + 6
        list_h = l[:py] + l[:ph] - list_y
        list_w = iw - DETAIL_W - 6
        rows   = [(list_h - PANEL_HEAD - 7) / (ROW_H + ROW_GAP), 1].max
        { :ix => ix, :iw => iw, :ty => ty, :list_y => list_y, :list_h => list_h,
          :list_w => list_w, :rows => rows, :dx => ix + list_w + 6, :detail_w => DETAIL_W }
      end

      def mine_rows
        l = lay
        [(l[:ph] - 28 - 34) / 40, 1].max
      end

      # =========================================================================
      # DESSIN : fond, en-tête, onglets, pied
      # =========================================================================
      def draw_background
        bm = @bg_sprite.bitmap
        bm.clear
        gw = Graphics.width
        gh = Graphics.height
        draw_gradient_bg(bm, 0, 0, gw, gh, C_BG_TOP, C_BG_BOT)
        dot = Color.new(120, 150, 220, 16)
        (0...gh).step(12) { |yy| (0...gw).step(12) { |xx| bm.fill_rect(xx, yy, 1, 1, dot) } }
      end

      def draw_content
        return unless @content_sprite && !@content_sprite.disposed?
        bm = @content_sprite.bitmap
        bm.clear
        @hits = []
        l = lay
        draw_header(bm, l)
        draw_tabs(bm, l)
        case @tab
        when :browse then draw_browse_tab(bm, l)
        when :create then draw_create_tab(bm, l)
        when :mine   then draw_mine_tab(bm, l)
        end
        draw_footer(bm, l)
      end

      def draw_header(bm, l)
        gw = l[:gw]
        draw_gradient_bg(bm, 0, 0, gw, HEADER_H, C_HEAD_TOP, C_HEAD_BOT)
        bm.fill_rect(0, 0, gw, 1, Color.new(255, 255, 255, 36))
        bm.fill_rect(0, HEADER_H - 2, gw, 1, C_GOLD)
        bm.fill_rect(0, HEADER_H - 1, gw, 1, C_GOLD_DK)

        # Emblème
        fill_circle(bm, 24, 21, 15, C_GOLD_DK)
        fill_circle(bm, 24, 21, 14, C_GOLD)
        fill_circle(bm, 24, 21, 11, Color.new(30, 42, 82))
        draw_pokeball(bm, 24, 21, 9)

        txt(bm, 46, 1, 300, 26, "HÔTEL DES VENTES", FONT_TITLE, :title)
        txt(bm, 47, 24, 300, 18, "Marché des dresseurs", FONT_SMALL, :muted)

        # Solde
        gold  = fmt(player_money) + " $"
        tw    = measure(gold, FONT_NORMAL)
        lw    = measure("SOLDE", FONT_TAG)
        w     = lw + tw + 46
        x     = gw - w - 8
        box(bm, x, 8, w, 28, C_GOLD_DK, Color.new(18, 24, 46))
        txt(bm, x + 10, 7, lw + 6, 28, "SOLDE", FONT_TAG, :muted)
        draw_coin(bm, x + 10 + lw + 14, 22, 7)
        txt(bm, x + 10 + lw + 26, 7, tw + 8, 28, gold, FONT_NORMAL, :gold)
      end

      def draw_tabs(bm, l)
        gw = l[:gw]
        bm.fill_rect(0, TAB_Y, gw, TAB_H, Color.new(11, 17, 35))
        bm.fill_rect(0, TAB_Y + TAB_H - 1, gw, 1, C_EDGE)
        claims = (PEMK::GTS.pending_claim || []).size
        tx = 8
        TABS.each do |id, name|
          badge = (id == :mine && claims > 0)
          tw  = measure(name, FONT_NORMAL) + 30 + (badge ? 20 : 0)
          sel = (@tab == id)
          hov = hover?(:tab, id)
          if sel
            pkmn_rect(bm, tx, TAB_Y + 3, tw, TAB_H - 3, C_EDGE)
            draw_gradient_bg(bm, tx + 1, TAB_Y + 4, tw - 2, TAB_H - 4, C_PANEL_HI, Color.new(18, 27, 52))
            bm.fill_rect(tx + 1, TAB_Y + TAB_H - 3, tw - 2, 2, C_GOLD)
          elsif hov
            draw_gradient_bg(bm, tx, TAB_Y + 6, tw, TAB_H - 7, Color.new(22, 32, 60), Color.new(14, 21, 42))
          end
          label_w = tw - (badge ? 20 : 0)
          txt(bm, tx, TAB_Y + 3, label_w, TAB_H - 5, name, FONT_NORMAL, sel ? :light : (hov ? :text : :muted), 1)
          if badge
            bx = tx + tw - 14
            fill_circle(bm, bx, TAB_Y + 14, 8, THEMES[:red][2])
            fill_circle(bm, bx, TAB_Y + 14, 7, THEMES[:red][1])
            txt(bm, bx - 10, TAB_Y + 4, 20, 20, claims > 99 ? "99" : claims.to_s, FONT_TAG, :light, 1)
          end
          @hits << [tx, TAB_Y, tw, TAB_H, :tab, id]
          tx += tw + 4
        end
      end

      def footer_chips
        case @tab
        when :browse
          [["Entrée", "Acheter"], [:arrows, "Liste"], [:lr, "Onglets"], ["Échap", "Quitter"]]
        when :create
          [["Entrée", "Choisir"], [:arrows, "Liste"], [:lr, "Onglets"], ["Échap", "Quitter"]]
        else
          [["Entrée", "Récupérer"], ["T", "Tout"], [:arrows, "Liste"], [:lr, "Onglets"], ["Échap", "Quitter"]]
        end
      end

      def draw_footer(bm, l)
        gw = l[:gw]; gh = l[:gh]
        y0 = gh - FOOT_H
        draw_gradient_bg(bm, 0, y0, gw, FOOT_H, Color.new(15, 22, 44), Color.new(9, 14, 30))
        bm.fill_rect(0, y0, gw, 1, C_EDGE)
        conn  = connected?
        label = conn ? "Connecté" : "Hors ligne"
        col   = conn ? C_GREEN : C_RED
        tw    = measure(label, FONT_SMALL)
        fill_circle(bm, gw - tw - 22, y0 + FOOT_H / 2 + 1, 4, darker(col, 0.5))
        fill_circle(bm, gw - tw - 22, y0 + FOOT_H / 2 + 1, 3, col)
        txt(bm, gw - tw - 12, y0, tw + 8, FOOT_H - 1, label, FONT_SMALL, conn ? :green : :red)
        draw_chips(bm, footer_chips, 10, y0 + 3, gw - tw - 34)
      end

      # =========================================================================
      # ONGLET : ACHETER
      # =========================================================================
      def draw_browse_tab(bm, l)
        g = browse_geo
        clamp_selection
        list = browse_list
        ix = g[:ix]; iw = g[:iw]; ty = g[:ty]

        # ── Filtres (contrôle segmenté) ──
        seg_w = 74
        cw = seg_w * FILTERS.length + 2
        box(bm, ix, ty, cw, 24, C_EDGE, C_PANEL_LO)
        FILTERS.each_with_index do |(id, name), i|
          sx = ix + 1 + i * seg_w
          if @sub_type == id
            draw_button(bm, sx, ty + 1, seg_w, 22, :blue, name, false, FONT_SMALL)
          else
            txt(bm, sx, ty, seg_w, 23, name, FONT_SMALL, hover?(:filter, i) ? :text : :muted, 1)
          end
          @hits << [sx, ty, seg_w, 24, :filter, i]
        end
        draw_key_cap(bm, ix + cw + 6, ty + 2, "F", 22)

        # ── Recherche ──
        sw = 190
        sx = ix + iw - sw
        box(bm, sx, ty, sw, 24, hover?(:search) ? C_EDGE_LT : C_EDGE, C_PANEL_LO)
        draw_search_icon(bm, sx + 14, ty + 12, @search_query.empty? ? C_MUTED : C_ACCENT)
        if @search_query.empty?
          txt(bm, sx + 26, ty, sw - 60, 23, "Rechercher...", FONT_SMALL, :dim)
        else
          txt(bm, sx + 26, ty, sw - 60, 23, fit_text(@search_query, sw - 62, FONT_SMALL), FONT_SMALL, :text)
        end
        draw_key_cap(bm, sx + sw - 26, ty + 2, "R", 22)
        @hits << [sx, ty, sw, 24, :search, nil]

        # ── Liste ──
        area_empty = loading? || list.empty?
        lx = ix
        ly = g[:list_y]
        lw = area_empty ? iw : g[:list_w]
        lh = g[:list_h]
        panel(bm, lx, ly, lw, lh, "ANNONCES (#{list.size})", C_ACCENT)

        # Tri
        sl = "Tri : #{SORTS[@sort_idx % SORTS.length][1]}"
        sl_w = measure(sl, FONT_SMALL)
        sort_x = lx + lw - sl_w - 28
        draw_mini_cap(bm, sort_x, ly + 3, "S")
        txt(bm, sort_x + 20, ly - 1, sl_w + 8, PANEL_HEAD, sl, FONT_SMALL, hover?(:sort) ? :text : :cyan)
        @hits << [sort_x, ly + 1, sl_w + 28, 20, :sort, nil]

        cx = lx + lw / 2
        cy = ly + PANEL_HEAD + (lh - PANEL_HEAD) / 2

        if loading?
          draw_spinner(bm, cx, cy - 12)
          txt(bm, lx, cy + 10, lw, 24, "Chargement des annonces" + "." * ((@tick / 12) % 4), FONT_NORMAL, :muted, 1)
          return
        end

        if list.empty?
          draw_pokeball(bm, cx, cy - 22, 18, true)
          msg = @search_query.empty? ? "Aucune annonce disponible actuellement." : "Aucun résultat pour « #{@search_query} »"
          txt(bm, lx, cy + 4, lw, 24, fit_text(msg, lw - 20, FONT_NORMAL), FONT_NORMAL, :muted, 1)
          txt(bm, lx, cy + 26, lw, 20, "Essayez un autre filtre ou revenez plus tard.", FONT_SMALL, :dim, 1)
          return
        end

        rw     = lw - 16
        rx     = lx + 4
        body_y = ly + PANEL_HEAD + 4
        g[:rows].times do |r|
          idx = @scroll_top + r
          break if idx >= list.size
          item = list[idx]
          ry   = body_y + r * (ROW_H + ROW_GAP)
          sel  = (idx == @selected_idx)
          kind = listing_kind(item)

          if sel
            pkmn_rect(bm, rx, ry, rw, ROW_H, Color.new(88, 140, 232))
            draw_gradient_bg(bm, rx + 1, ry + 1, rw - 2, ROW_H - 2, Color.new(40, 64, 118), Color.new(28, 46, 90))
            bar = C_ACCENT
          else
            pkmn_rect(bm, rx, ry, rw, ROW_H, C_EDGE_DK)
            pkmn_rect(bm, rx + 1, ry + 1, rw - 2, ROW_H - 2, (r % 2 == 0) ? C_ROW : C_ROW_ALT)
            bar = (kind == "pokemon") ? C_BLUE : C_ORANGE
          end
          bm.fill_rect(rx + 1, ry + 3, 3, ROW_H - 6, bar)

          draw_listing_icon(bm, item, rx + 11, ry + 3, 34)

          title  = lget(item, :title, "Annonce").to_s
          seller = lget(item, :seller_name, "Joueur").to_s
          price  = lget(item, :price, 0).to_i
          tx = rx + 52
          tw = rw - 52 - 108
          txt(bm, tx, ry + 1, tw + 6, 22, fit_text(title, tw, FONT_NORMAL), FONT_NORMAL, sel ? :light : :text)
          txt(bm, tx, ry + 20, tw + 6, 18, fit_text("par #{seller}", tw, FONT_SMALL), FONT_SMALL, sel ? :cyan : :muted)

          pstr  = "#{fmt(price)} $"
          pw    = measure(pstr, FONT_NORMAL)
          right = rx + rw - 8
          txt(bm, right - pw, ry + 1, pw + 8, 22, pstr, FONT_NORMAL, :gold)
          draw_coin(bm, right - pw - 9, ry + 12, 6)
          label = auction?(item) ? "ENCHÈRE" : "PRIX FIXE"
          draw_tag(bm, right - tag_width(label), ry + 21, label, auction?(item) ? :gold : :green)

          @hits << [rx, ry, rw, ROW_H, :row, idx]
        end

        # Barre de défilement
        if list.size > g[:rows]
          th = g[:rows] * (ROW_H + ROW_GAP) - ROW_GAP
          bx = lx + lw - 10
          bm.fill_rect(bx, body_y, 5, th, C_PANEL_LO)
          thumb_h = [th * g[:rows] / list.size, 16].max
          span = [list.size - g[:rows], 1].max
          ty2 = body_y + ((th - thumb_h) * @scroll_top / span)
          pkmn_rect(bm, bx - 1, ty2, 7, thumb_h, C_EDGE_LT)
          bm.fill_rect(bx + 1, ty2 + 2, 3, [thumb_h - 4, 1].max, C_ACCENT)
        end

        draw_listing_detail(bm, g, list[@selected_idx]) if list[@selected_idx]
      end

      def draw_listing_detail(bm, g, item)
        dx = g[:dx]; dy = g[:list_y]; dw = g[:detail_w]; dh = g[:list_h]
        kind = listing_kind(item)
        pl   = listing_payload(item)
        tcol = (kind == "pokemon") ? C_BLUE : C_ORANGE
        panel(bm, dx, dy, dw, dh, "FICHE ANNONCE", tcol)

        # Vitrine
        ss = 48
        sx = dx + (dw - ss) / 2
        sy = dy + PANEL_HEAD + 5
        pkmn_rect(bm, sx, sy, ss, ss, darker(tcol, 0.7))
        draw_gradient_bg(bm, sx + 1, sy + 1, ss - 2, ss - 2, Color.new(32, 46, 88), Color.new(15, 22, 44))
        src = listing_icon_bitmap(item)
        if src
          blit_icon(bm, src, sx + 3, sy + 3, ss - 6)
        elsif kind == "pokemon"
          draw_pokeball(bm, sx + ss / 2, sy + ss / 2, 16)
        else
          draw_bag_icon(bm, sx + ss / 2, sy + ss / 2, 28)
        end

        # Nom
        y = sy + ss + 5
        name = (kind == "pokemon") ? (lget(pl, :name) || lget(item, :title, "Annonce")) : lget(item, :title, "Annonce")
        txt(bm, dx + 6, y, dw - 12, 22, fit_text(name.to_s, dw - 14, FONT_NORMAL), FONT_NORMAL, :text, 1)
        y += 24

        # Badges
        tags = []
        if kind == "pokemon"
          tags << ["POKÉMON", :blue]
          lvl = lget(pl, :level)
          tags << ["NIV. #{lvl}", :green] if lvl
        else
          tags << ["OBJET", :orange]
          qty = lget(pl, :qty).to_i
          tags << ["x#{qty}", :gold] if qty > 1
        end
        total = tags.map { |t| tag_width(t[0]) }.inject(0) { |a, b| a + b } + (tags.length - 1) * 4
        tx = dx + (dw - total) / 2
        tags.each { |lab, k| tx += draw_tag(bm, tx, y, lab, k) + 4 }
        y += 20

        # PV
        if kind == "pokemon"
          hp = lget(pl, :hp)
          totalhp = lget(pl, :totalhp)
          if hp && totalhp && totalhp.to_i > 0
            ratio = [hp.to_f / totalhp.to_f, 1.0].min
            th, tb = ratio > 0.5 ? THEMES[:green][0, 2] : (ratio > 0.2 ? THEMES[:gold][0, 2] : THEMES[:red][0, 2])
            txt(bm, dx + 8, y - 3, 30, 16, "PV", FONT_TAG, :muted)
            txt(bm, dx + 8, y - 3, dw - 16, 16, "#{hp} / #{totalhp}", FONT_TAG, :text, 2)
            draw_bar(bm, dx + 8, y + 12, dw - 16, 6, ratio, th, tb)
            y += 24
          end
        end

        # Vendeur
        seller = lget(item, :seller_name, "Joueur").to_s
        txt(bm, dx + 8, y, 60, 18, "Vendeur", FONT_SMALL, :muted)
        txt(bm, dx + 64, y, dw - 72, 18, fit_text(seller, dw - 74, FONT_SMALL), FONT_SMALL, :text, 2)

        # Bloc prix + bouton (ancrés en bas)
        by  = dy + dh - 30
        py0 = by - 42
        bm.fill_rect(dx + 6, py0 - 3, dw - 12, 1, C_LINE)
        price = lget(item, :price, 0).to_i
        auc   = auction?(item)
        txt(bm, dx + 8, py0 - 1, dw - 16, 16, auc ? "Enchère actuelle" : "Prix", FONT_TAG, :muted, 1)
        pstr = "#{fmt(price)} $"
        pw   = measure(pstr, FONT_TITLE)
        px   = dx + (dw - pw - 20) / 2
        draw_coin(bm, px + 7, py0 + 26, 7)
        txt(bm, px + 20, py0 + 12, pw + 10, 28, pstr, FONT_TITLE, :gold)

        my_name = defined?($player) && $player ? $player.name : (defined?($Trainer) && $Trainer ? $Trainer.name : "")
        is_mine = (seller == my_name) || (lget(item, :is_mine) == true)
        hov = hover?(:buy)
        bw  = dw - 12
        if is_mine
          draw_button(bm, dx + 6, by, bw, 24, :slate, "VOTRE ANNONCE", false)
        elsif auc
          draw_button(bm, dx + 6, by, bw, 24, :slate, "Enchère indisponible", false)
        elsif player_money < price
          draw_button(bm, dx + 6, by, bw, 24, :red, "SOLDE INSUFFISANT", hov)
        else
          draw_button(bm, dx + 6, by, bw, 24, :green, "ACHETER", hov)
        end
        @hits << [dx + 6, by, bw, 24, :buy, nil]
      end

      # =========================================================================
      # ONGLET : VENDRE
      # =========================================================================
      def draw_create_tab(bm, l)
        ix = l[:px]
        iy = l[:py]
        iw = l[:pw]
        ih = l[:ph]
        info_w = 190
        card_w = iw - info_w - 8
        card_h = 70
        disabled = limit_reached?

        cards = [
          [:pokemon, "Vendre un Pokémon", "Choisissez un Pokémon de votre équipe."],
          [:item,    "Vendre un objet",   "Choisissez un objet dans votre sac."],
        ]
        cards.each_with_index do |(kind, title, sub), i|
          cy  = iy + i * (card_h + 8)
          sel = (@create_idx == i)
          if sel
            pkmn_rect(bm, ix, cy, card_w, card_h, Color.new(88, 140, 232))
            draw_gradient_bg(bm, ix + 1, cy + 1, card_w - 2, card_h - 2, Color.new(40, 64, 118), Color.new(28, 46, 90))
          else
            pkmn_rect(bm, ix, cy, card_w, card_h, C_EDGE_DK)
            pkmn_rect(bm, ix + 1, cy + 1, card_w - 2, card_h - 2, C_ROW)
          end
          bar = disabled ? C_MUTED : (sel ? C_ACCENT : (kind == :pokemon ? C_BLUE : C_ORANGE))
          bm.fill_rect(ix + 1, cy + 4, 3, card_h - 8, bar)

          draw_slot(bm, ix + 16, cy + (card_h - 50) / 2, 50)
          icx = ix + 16 + 25
          icy = cy + (card_h - 50) / 2 + 25
          if kind == :pokemon
            draw_pokeball(bm, icx, icy, 17, disabled)
          else
            draw_bag_icon(bm, icx, icy, 32)
          end
          tx = ix + 78
          txt(bm, tx, cy + 8, card_w - 90, 24, title, FONT_NORMAL, disabled ? :muted : (sel ? :light : :text))
          txt(bm, tx, cy + 32, card_w - 90, 20, fit_text(sub, card_w - 96, FONT_SMALL), FONT_SMALL, sel ? :cyan : :muted)
          draw_tag(bm, tx, cy + 51, "LIMITE ATTEINTE", :red) if disabled
          @hits << [ix, cy, card_w, card_h, :create_card, i]
        end

        # Étapes
        sy = iy + 2 * (card_h + 8)
        sh = ih - 2 * (card_h + 8)
        panel(bm, ix, sy, card_w, sh, "COMMENT VENDRE", C_GOLD)
        steps = [
          "Choisissez un Pokémon ou un objet",
          "Fixez votre prix de vente",
          "Confirmez : l'annonce est publiée",
        ]
        steps.each_with_index do |s, i|
          yy = sy + PANEL_HEAD + 8 + i * 25
          fill_circle(bm, ix + 20, yy + 10, 9, C_GOLD_DK)
          fill_circle(bm, ix + 20, yy + 10, 8, C_GOLD)
          txt(bm, ix + 11, yy + 1, 18, 18, (i + 1).to_s, FONT_SMALL, :title, 1)
          txt(bm, ix + 38, yy, card_w - 46, 20, fit_text(s, card_w - 48, FONT_SMALL), FONT_SMALL, :text)
        end

        # Fiche d'infos
        fx = ix + iw - info_w
        panel(bm, fx, iy, info_w, ih, "VOTRE ACTIVITÉ", C_ACCENT)
        n   = (PEMK::GTS.my_listings || []).size
        max = PEMK::GTS::MAX_ACTIVE_LISTINGS.to_i
        y = iy + PANEL_HEAD + 8
        txt(bm, fx + 10, y, info_w - 20, 18, "Annonces actives", FONT_SMALL, :muted)
        txt(bm, fx + 10, y + 16, info_w - 20, 28, "#{n} / #{max}", FONT_TITLE, disabled ? :red : :text)
        ratio = max > 0 ? [n.to_f / max, 1.0].min : 0.0
        th, tb = disabled ? THEMES[:red][0, 2] : THEMES[:green][0, 2]
        draw_bar(bm, fx + 10, y + 46, info_w - 20, 8, ratio, th, tb)

        y += 66
        bm.fill_rect(fx + 8, y, info_w - 16, 1, C_LINE)
        y += 8
        txt(bm, fx + 10, y, info_w - 20, 18, "Frais de mise en vente", FONT_SMALL, :muted)
        fee = "#{tax_percent_text} (min. #{fmt(PEMK::GTS::MIN_LISTING_FEE)} $)"
        txt(bm, fx + 10, y + 18, info_w - 20, 22, fit_text(fee, info_w - 22, FONT_NORMAL), FONT_NORMAL, :gold)

        y += 50
        bm.fill_rect(fx + 8, y, info_w - 16, 1, C_LINE)
        y += 8
        txt(bm, fx + 10, y, info_w - 20, 18, "Exemple : vente à 10 000 $", FONT_SMALL, :muted)
        ex_fee = (tax_for(10000) rescue 0)
        txt(bm, fx + 10, y + 18, info_w - 20, 20, "Frais : #{fmt(ex_fee)} $", FONT_SMALL, :text)
        txt(bm, fx + 10, y + 36, info_w - 20, 18, "Payés à la mise en vente.", FONT_TAG, :dim)
      end

      # =========================================================================
      # ONGLET : MES VENTES
      # =========================================================================
      def draw_mine_tab(bm, l)
        ix = l[:px]
        iy = l[:py]
        iw = l[:pw]
        ih = l[:ph]
        colw = (iw - 8) / 2
        my_list = PEMK::GTS.my_listings || []
        claims  = PEMK::GTS.pending_claim || []
        vis = mine_rows

        # Colonne gauche : annonces actives
        panel(bm, ix, iy, colw, ih, "ANNONCES ACTIVES  #{my_list.size} / #{PEMK::GTS::MAX_ACTIVE_LISTINGS}", C_BLUE)
        if my_list.empty?
          draw_pokeball(bm, ix + colw / 2, iy + ih / 2 - 10, 16, true)
          txt(bm, ix, iy + ih / 2 + 12, colw, 22, "Aucune vente en cours.", FONT_NORMAL, :muted, 1)
        else
          vis.times do |r|
            item = my_list[r]
            break unless item
            ry = iy + 28 + r * 40
            hov = hover?(:cancel_listing, r)
            pkmn_rect(bm, ix + 6, ry, colw - 12, 36, hov ? C_EDGE_LT : C_EDGE_DK)
            pkmn_rect(bm, ix + 7, ry + 1, colw - 14, 34, hov ? C_ROW_HOV : (r % 2 == 0 ? C_ROW : C_ROW_ALT))
            draw_listing_icon(bm, item, ix + 12, ry + 3, 30)
            title = lget(item, :title, "Objet").to_s
            price = lget(item, :price, 0).to_i
            pstr  = "#{fmt(price)} $"
            bw    = 62
            tw    = colw - 12 - 46 - bw - 16
            txt(bm, ix + 48, ry, tw + 6, 20, fit_text(title, tw, FONT_NORMAL), FONT_NORMAL, :text)
            draw_coin(bm, ix + 54, ry + 27, 5)
            txt(bm, ix + 62, ry + 17, tw, 18, pstr, FONT_SMALL, :gold)
            draw_button(bm, ix + colw - 12 - bw - 2, ry + 8, bw, 20, :red, "Annuler", hov)
            @hits << [ix + 6, ry, colw - 12, 36, :cancel_listing, r]
          end
          if my_list.size > vis
            txt(bm, ix, iy + ih - 22, colw, 18, "+ #{my_list.size - vis} autre(s)", FONT_SMALL, :dim, 1)
          end
        end

        # Colonne droite : gains à récupérer
        cx = ix + colw + 8
        panel(bm, cx, iy, colw, ih, "À RÉCUPÉRER  #{claims.size}", C_GREEN)
        if claims.empty?
          draw_coin(bm, cx + colw / 2, iy + ih / 2 - 10, 14)
          txt(bm, cx, iy + ih / 2 + 12, colw, 22, "Rien à récupérer.", FONT_NORMAL, :muted, 1)
        else
          vis.times do |r|
            idx = @mine_scroll + r
            c = claims[idx]
            break unless c
            ry  = iy + 28 + r * 40
            sel = (idx == @mine_idx)
            if sel
              pkmn_rect(bm, cx + 6, ry, colw - 12, 36, Color.new(88, 140, 232))
              draw_gradient_bg(bm, cx + 7, ry + 1, colw - 14, 34, Color.new(40, 64, 118), Color.new(28, 46, 90))
              bm.fill_rect(cx + 7, ry + 3, 3, 30, C_ACCENT)
            else
              pkmn_rect(bm, cx + 6, ry, colw - 12, 36, C_EDGE_DK)
              pkmn_rect(bm, cx + 7, ry + 1, colw - 14, 34, r % 2 == 0 ? C_ROW : C_ROW_ALT)
            end
            draw_slot(bm, cx + 16, ry + 3, 30)
            draw_coin(bm, cx + 31, ry + 18, 8)
            title = lget(c, :title, "Gain").to_s
            bw    = 70
            tw    = colw - 12 - 54 - bw - 16
            txt(bm, cx + 54, ry, tw + 6, 20, fit_text(title, tw, FONT_NORMAL), FONT_NORMAL, sel ? :light : :text)
            txt(bm, cx + 54, ry + 17, tw + 6, 18, "Prêt à récupérer", FONT_SMALL, :green)
            draw_button(bm, cx + colw - 12 - bw - 2, ry + 8, bw, 20, :green, "Récupérer", sel)
            @hits << [cx + 6, ry, colw - 12, 36, :claim, idx]
          end
          # Bouton "Tout récupérer"
          draw_button(bm, cx + 6, iy + ih - 30, colw - 12, 24, :gold, "T  -  Tout récupérer", hover?(:claim_all))
          @hits << [cx + 6, iy + ih - 30, colw - 12, 24, :claim_all, nil]
        end
      end

      # =========================================================================
      # ACTIONS
      # =========================================================================
      def handle_browse_selection
        listings = browse_list
        return if listings.empty? || @selected_idx >= listings.size

        item  = listings[@selected_idx]
        price = lget(item, :price, 0).to_i
        title = lget(item, :title, "Annonce").to_s
        uid   = lget(item, :listing_uid)

        if auction?(item)
          ui_message("Les enchères ne sont pas encore disponibles depuis ce menu.", [], "Enchère", :slate)
          return
        end

        gold = player_money
        if gold < price
          ui_message("Solde insuffisant : il vous manque #{fmt(price - gold)} $.", [], "Achat impossible", :red)
          return
        end

        ok = ui_confirm("Acheter #{title} pour #{fmt(price)} $ ?",
                        ["Vendeur : #{lget(item, :seller_name, 'Joueur')}",
                         "Solde après achat : #{fmt(gold - price)} $"],
                        "Achat", :green)
        if ok
          PEMK::GTS.send_buy_fixed(uid)
          show_toast("Achat en cours...", :green)
        end
      end

      def handle_create_selection
        if limit_reached?
          ui_message("Vous avez atteint la limite d'annonces actives (#{PEMK::GTS::MAX_ACTIVE_LISTINGS}).",
                     [], "Limite atteinte", :red)
          return
        end
        @create_idx == 0 ? sell_pokemon : sell_item
      end

      def sell_pokemon
        party = player_party
        if party.empty?
          ui_message("Votre équipe est vide !", [], "Vente impossible", :red)
          return
        end
        if party.length <= 1
          ui_message("Vous ne pouvez pas vendre votre dernier Pokémon !", [], "Vente impossible", :red)
          return
        end

        idx = ui_pick_party(party)
        return unless idx
        pkmn  = party[idx]
        title = "#{pkmn.name} (Niv. #{pkmn.level})"

        info  = lambda { |v| ["Frais de mise en vente : #{fmt(tax_for(v))} $"] }
        price = ui_number("Prix de vente", "Fixez le prix de #{pkmn.name} :", 1, 999999, 1000, info)
        return unless price

        tax = tax_for(price)
        ok = ui_confirm("Mettre en vente #{title} pour #{fmt(price)} $ ?",
                        ["Frais de mise en vente : #{fmt(tax)} $"], "Confirmer la vente", :gold)
        return unless ok

        PEMK::GTS.add_player_money(-tax)
        party.delete_at(idx) rescue nil

        serialized_pkmn = nil
        begin
          serialized_pkmn = [Marshal.dump(pkmn)].pack("m0")
        rescue => e
        end

        pkmn_data = {
          species:    pkmn.species,
          level:      pkmn.level,
          name:       pkmn.name,
          hp:         pkmn.hp,
          totalhp:    pkmn.totalhp,
          serialized: serialized_pkmn
        }
        PEMK::GTS.send_create_listing("pokemon", pkmn_data, title, "fixed", price)
        PEMK::GTS.auto_save
        show_toast("Annonce envoyée !", :green)
      end

      def sell_item
        bag = $bag || $PokemonBag
        unless bag && defined?(PokemonBag_Scene) && defined?(PokemonBagScreen)
          ui_message("Le sac n'est pas disponible ici.", [], "Vente impossible", :red)
          return
        end

        item = nil
        @viewport.visible = false
        begin
          chooser = proc {
            scene  = PokemonBag_Scene.new
            screen = PokemonBagScreen.new(scene, bag)
            item   = screen.pbChooseItemScreen
          }
          defined?(pbFadeOutIn) ? pbFadeOutIn(&chooser) : chooser.call
        ensure
          @viewport.visible = true if @viewport && !@viewport.disposed?
        end
        return unless item

        data = (GameData::Item.get(item) rescue nil)
        if data && data.respond_to?(:is_important?) && data.is_important?
          ui_message("Cet objet clé ne peut pas être vendu.", [], "Vente impossible", :red)
          return
        end
        name = data ? data.name.to_s : item.to_s
        qty_max = (bag.quantity(item) rescue 1).to_i
        qty = 1
        if qty_max > 1
          qty = ui_number("Quantité", "Combien de #{name} vendre ?", 1, qty_max, 1)
          return unless qty
        end
        title = qty > 1 ? "#{name} ×#{qty}" : name

        info  = lambda { |v| ["Frais de mise en vente : #{fmt(tax_for(v))} $"] }
        price = ui_number("Prix de vente", "Fixez le prix de #{title} :", 1, 999999, 500, info)
        return unless price

        tax = tax_for(price)
        ok = ui_confirm("Mettre en vente #{title} pour #{fmt(price)} $ ?",
                        ["Frais de mise en vente : #{fmt(tax)} $"], "Confirmer la vente", :gold)
        return unless ok

        PEMK::GTS.add_player_money(-tax)
        if defined?($bag) && $bag && $bag.respond_to?(:remove)
          $bag.remove(item, qty) rescue nil
        elsif defined?($PokemonBag) && $PokemonBag && $PokemonBag.respond_to?(:pbDeleteItem)
          $PokemonBag.pbDeleteItem(item, qty) rescue nil
        end

        item_data = { item_id: item.to_s, qty: qty }
        PEMK::GTS.send_create_listing("item", item_data, title, "fixed", price)
        PEMK::GTS.auto_save
        show_toast("Annonce envoyée !", :green)
      end

      def cancel_active_listing(idx)
        my_list = PEMK::GTS.my_listings || []
        item = my_list[idx]
        return unless item
        title = lget(item, :title, "Objet").to_s
        uid   = lget(item, :listing_uid)

        if ui_confirm("Annuler la vente de #{title} et récupérer le contenu ?", [], "Annuler la vente", :red)
          PEMK::GTS.send_cancel_listing(uid)
          show_toast("Vente annulée !", :green)
        end
      end

      def handle_mine_selection
        claims = PEMK::GTS.pending_claim || []
        if claims.empty?
          ui_message("Aucun gain ou objet en attente de récupération.", [], "Information", :blue)
          return
        end
        c = claims[@mine_idx] || claims[0]
        title = lget(c, :title, "Gain").to_s
        if ui_confirm("Récupérer : #{title} ?", [], "Récupération", :green)
          PEMK::GTS.send_claim(lget(c, :claim_id))
          show_toast("Récupération en cours...", :green)
        end
      end

      def claim_all
        claims = PEMK::GTS.pending_claim || []
        if claims.empty?
          ui_message("Aucun gain ou objet en attente de récupération.", [], "Information", :blue)
          return
        end
        if ui_confirm("Récupérer tous les gains (#{claims.size}) ?", [], "Récupération", :green)
          claims.dup.each { |c| PEMK::GTS.send_claim(lget(c, :claim_id)) }
          show_toast("Récupération en cours...", :green)
        end
      end

      # =========================================================================
      # NOTIFICATION (toast)
      # =========================================================================
      def show_toast(text, theme = :blue)
        dispose_toast
        return unless @viewport && !@viewport.disposed?
        gw = Graphics.width; gh = Graphics.height
        tw = measure(text, FONT_NORMAL)
        w = tw + 54
        h = 32
        bm = Bitmap.new(w, h)
        top, bot, dk = THEMES[theme] || THEMES[:blue]
        pkmn_rect(bm, 0, 0, w, h, dk)
        pkmn_rect(bm, 1, 1, w - 2, h - 2, C_PANEL)
        draw_gradient_bg(bm, 1, 2, 5, h - 4, top, bot)
        fill_circle(bm, 23, h / 2, 9, dk)
        fill_circle(bm, 23, h / 2, 8, bot)
        txt(bm, 13, 5, 20, 22, theme == :red ? "!" : "i", FONT_SMALL, :light, 1)
        txt(bm, 40, 4, tw + 10, 24, text, FONT_NORMAL, :text)
        @toast_sprite = Sprite.new(@viewport)
        @toast_sprite.z = 8
        @toast_sprite.bitmap = bm
        @toast_sprite.x = (gw - w) / 2
        @toast_sprite.y = gh - FOOT_H - h - 10
        @toast_frames = 130
      end

      def update_toast
        return unless @toast_sprite && !@toast_sprite.disposed?
        @toast_frames -= 1
        if @toast_frames <= 0
          dispose_toast
        else
          @toast_sprite.opacity = (255 * [@toast_frames / 24.0, 1.0].min).to_i
        end
      end

      def dispose_toast
        @toast_sprite&.bitmap&.dispose
        @toast_sprite&.dispose unless @toast_sprite&.disposed?
        @toast_sprite = nil
      end

      # =========================================================================
      # FENÊTRES MODALES INTÉGRÉES (remplacent pbMessage / pbConfirmMessage)
      # =========================================================================
      def modal_begin(w, h)
        gw = Graphics.width; gh = Graphics.height
        dim = Sprite.new(@viewport)
        dim.z = 10
        dim.bitmap = Bitmap.new(gw, gh)
        dim.bitmap.fill_rect(0, 0, gw, gh, Color.new(4, 8, 20, 175))
        spr = Sprite.new(@viewport)
        spr.z = 11
        spr.bitmap = Bitmap.new(w, h)
        spr.x = (gw - w) / 2
        spr.y = (gh - h) / 2
        [dim, spr]
      end

      def modal_end(dim, spr)
        [dim, spr].each do |s|
          s.bitmap&.dispose
          s.dispose
        end
        @dirty = true
      end

      def in_rect?(pos, spr, r)
        pos[0] >= spr.x + r[0] && pos[0] < spr.x + r[0] + r[2] &&
          pos[1] >= spr.y + r[1] && pos[1] < spr.y + r[1] + r[3]
      end

      def draw_choice_button(bm, r, label, sel)
        x, y, w, h = r
        if sel
          draw_button(bm, x, y, w, h, :green, label, false, FONT_NORMAL)
        else
          box(bm, x, y, w, h, C_EDGE, C_PANEL_LO)
          txt(bm, x, y - 1, w, h, label, FONT_NORMAL, :muted, 1)
        end
      end

      # Boîte de dialogue à boutons. Retourne l'index du bouton choisi.
      # Annuler / Échap = dernier bouton.
      def ui_dialog(text, details, title, theme, buttons)
        w = 340
        lines = wrap_text(text, w - 32, FONT_NORMAL, 3)
        dl    = details.map { |d| fit_text(d, w - 32, FONT_SMALL) }
        h = 34 + lines.length * 22 + (dl.empty? ? 0 : 6 + dl.length * 18) + 16 + 28 + 16
        dim, spr = modal_begin(w, h)
        n   = buttons.length
        bw  = 96
        gap = 12
        total = n * bw + (n - 1) * gap
        by  = h - 16 - 28
        rects = (0...n).map { |i| [(w - total) / 2 + i * (bw + gap), by, bw, 28] }
        sel = 0
        redraw = true
        result = nil

        loop do
          if redraw
            redraw = false
            bm = spr.bitmap
            bm.clear
            draw_frame(bm, 0, 0, w, h)
            draw_header_bar(bm, 3, 3, w - 6, 22, theme)
            txt(bm, 3, 2, w - 6, 22, title, FONT_SMALL, :light, 1)
            y = 34
            lines.each { |ln| txt(bm, 16, y, w - 28, 22, ln, FONT_NORMAL, :text); y += 22 }
            unless dl.empty?
              y += 6
              dl.each { |d| txt(bm, 16, y, w - 28, 18, d, FONT_SMALL, :muted); y += 18 }
            end
            buttons.each_with_index { |lab, i| draw_choice_button(bm, rects[i], lab, sel == i) }
          end

          Graphics.update
          Input.update
          @tick += 1
          old = sel
          sel = [sel - 1, 0].max if trig?(:LEFT)
          sel = [sel + 1, n - 1].min if trig?(:RIGHT)

          moved = mouse_moved?
          pos = mouse_pos
          clicked = nil
          if pos
            rects.each_with_index do |r, i|
              next unless in_rect?(pos, spr, r)
              sel = i if moved
              clicked = i if lclick?
            end
          end

          if clicked
            result = clicked
            break
          elsif use?
            result = sel
            break
          elsif cancel?
            result = n - 1
            break
          end
          redraw = true if sel != old
        end

        modal_end(dim, spr)
        result
      end

      def ui_confirm(text, details = [], title = "Confirmation", theme = :blue)
        ui_dialog(text, details, title, theme, ["Oui", "Non"]) == 0
      end

      def ui_message(text, details = [], title = "Information", theme = :blue)
        ui_dialog(text, details, title, theme, ["OK"])
        nil
      end

      # Saisie d'un nombre. Retourne la valeur ou nil si annulé.
      def ui_number(title, text, min, max, default, info_proc = nil)
        w = 320
        lines = wrap_text(text, w - 32, FONT_NORMAL, 2)
        h = 34 + lines.length * 22 + 8 + 74 + 40 + 30 + 14
        dim, spr = modal_begin(w, h)
        v = default.clamp(min, max)
        hold = 0
        redraw = true
        result = nil

        loop do
          if redraw
            redraw = false
            bm = spr.bitmap
            bm.clear
            draw_frame(bm, 0, 0, w, h)
            draw_header_bar(bm, 3, 3, w - 6, 22, :gold)
            txt(bm, 3, 2, w - 6, 22, title, FONT_SMALL, :light, 1)
            y = 34
            lines.each { |ln| txt(bm, 16, y, w - 28, 22, ln, FONT_NORMAL, :text); y += 22 }
            y += 8
            # Zone du nombre
            bx = (w - 190) / 2
            draw_arrow(bm, w / 2, y + 4, 0, 6, v < max ? C_ACCENT : C_LINE)
            box(bm, bx, y + 12, 190, 36, C_GOLD_DK, C_PANEL_LO)
            vstr = "#{fmt(v)} $"
            txt(bm, bx + 22, y + 14, 160, 30, vstr, FONT_TITLE, :gold, 1)
            draw_coin(bm, bx + 18, y + 30, 8)
            draw_arrow(bm, w / 2, y + 58, 2, 6, v > min ? C_ACCENT : C_LINE)
            y += 70
            infos = info_proc ? (info_proc.call(v) || []) : []
            infos.each { |s| txt(bm, 16, y, w - 28, 18, fit_text(s, w - 32, FONT_SMALL), FONT_SMALL, :muted, 1); y += 18 }
            draw_chips(bm, [[:arrows, "±1"], [:lr, "±100"], ["Entrée", "OK"]], 18, h - 30, w - 10)
          end

          Graphics.update
          Input.update
          @tick += 1
          old = v

          up = rep?(:UP)
          dn = rep?(:DOWN)
          if up || dn
            hold += 1
            step = hold < 8 ? 1 : (hold < 20 ? 10 : (hold < 40 ? 100 : 1000))
            v += up ? step : -step
          elsif !(Input.press?(Input::UP) rescue false) && !(Input.press?(Input::DOWN) rescue false)
            hold = 0
          end
          v += 100 if rep?(:RIGHT)
          v -= 100 if rep?(:LEFT)
          if Input.respond_to?(:scroll_v)
            sv = (Input.scroll_v rescue 0)
            v += sv.to_i * 10 if sv && sv != 0
          end
          v = v.clamp(min, max)

          if use?
            result = v
            break
          elsif cancel?
            result = nil
            break
          end
          redraw = true if v != old
        end

        modal_end(dim, spr)
        result
      end

      # Sélecteur de Pokémon de l'équipe. Retourne l'index ou nil.
      def ui_pick_party(party)
        n = [party.length, 6].min
        w = 350
        row_h = 40
        h = 34 + n * row_h + 8 + 30
        dim, spr = modal_begin(w, h)
        sel = 0
        redraw = true
        result = nil

        loop do
          if redraw
            redraw = false
            bm = spr.bitmap
            bm.clear
            draw_frame(bm, 0, 0, w, h)
            draw_header_bar(bm, 3, 3, w - 6, 22, :blue)
            txt(bm, 3, 2, w - 6, 22, "Choisissez le Pokémon à vendre", FONT_SMALL, :light, 1)
            n.times do |i|
              pk = party[i]
              ry = 32 + i * row_h
              if i == sel
                pkmn_rect(bm, 8, ry, w - 16, row_h - 2, Color.new(88, 140, 232))
                draw_gradient_bg(bm, 9, ry + 1, w - 18, row_h - 4, Color.new(40, 64, 118), Color.new(28, 46, 90))
                bm.fill_rect(9, ry + 4, 3, row_h - 10, C_ACCENT)
              else
                pkmn_rect(bm, 8, ry, w - 16, row_h - 2, C_EDGE_DK)
                pkmn_rect(bm, 9, ry + 1, w - 18, row_h - 4, i % 2 == 0 ? C_ROW : C_ROW_ALT)
              end
              draw_slot(bm, 22, ry + 3, 32)
              src = icon_bitmap(pokemon_icon_path(pk))
              if src
                blit_icon(bm, src, 24, ry + 5, 28)
              else
                draw_pokeball(bm, 38, ry + 19, 10)
              end
              pname = (pk.respond_to?(:egg?) && pk.egg?) ? "Œuf" : pk.name.to_s
              txt(bm, 64, ry + 1, 140, 22, fit_text(pname, 134, FONT_NORMAL), FONT_NORMAL, i == sel ? :light : :text)
              txt(bm, 64, ry + 20, 140, 18, "Niv. #{pk.level}", FONT_SMALL, :muted)
              hp  = (pk.hp rescue 0).to_i
              mhp = [(pk.totalhp rescue 1).to_i, 1].max
              ratio = hp.to_f / mhp
              bar_x = w - 16 - 100
              col_t, col_b = ratio > 0.5 ? THEMES[:green][0, 2] : (ratio > 0.2 ? THEMES[:gold][0, 2] : THEMES[:red][0, 2])
              draw_bar(bm, bar_x, ry + 10, 92, 8, ratio, col_t, col_b)
              txt(bm, bar_x - 4, ry + 19, 100, 18, "#{hp} / #{mhp}", FONT_SMALL, :muted, 2)
            end
            draw_chips(bm, [[:arrows, "Choisir"], ["Entrée", "Valider"], ["Échap", "Annuler"]], 14, h - 28, w - 10)
          end

          Graphics.update
          Input.update
          @tick += 1
          old = sel
          sel = [sel - 1, 0].max if rep?(:UP)
          sel = [sel + 1, n - 1].min if rep?(:DOWN)

          moved = mouse_moved?
          pos = mouse_pos
          clicked = nil
          if pos
            n.times do |i|
              r = [8, 32 + i * row_h, w - 16, row_h - 2]
              next unless in_rect?(pos, spr, r)
              sel = i if moved
              clicked = i if lclick?
            end
          end

          if clicked
            result = clicked
            break
          elsif use?
            result = sel
            break
          elsif cancel?
            result = nil
            break
          end
          redraw = true if sel != old
        end

        modal_end(dim, spr)
        result
      end
    end
  end
end
