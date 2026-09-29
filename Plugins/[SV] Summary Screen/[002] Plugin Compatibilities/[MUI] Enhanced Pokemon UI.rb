#===============================================================================
# [MUI] Enhanced Pokemon UI compatibility for [SV] Summary Screen
#===============================================================================
if PluginManager.installed?("[MUI] Enhanced Pokemon UI")
  class PokemonSummary_Scene
    #-----------------------------------------------------------------------------
    # Aliased to add shiny leaf display.
    #-----------------------------------------------------------------------------
    alias enhanced_drawPage drawPage
    def drawPage(page)
      enhanced_drawPage(page)
      return if !Settings::SUMMARY_SHINY_LEAF
      overlay = @sprites["overlay"].bitmap
      coords = [195, 244]
      pbDisplayShinyLeaf(@pokemon, overlay, coords[0], coords[1])
    end

    #-----------------------------------------------------------------------------
    # Aliased to add happiness meter display.
    #-----------------------------------------------------------------------------
    alias enhanced_drawPageOne drawPageOne
    def drawPageOne
      enhanced_drawPageOne
      return if !Settings::SUMMARY_HAPPINESS_METER
      overlay = @sprites["overlay"].bitmap
      coords = [222, 352]
      pbDisplayHappiness(@pokemon, overlay, coords[0], coords[1])
    end

    #-----------------------------------------------------------------------------
    # Aliased to add Legacy data display.
    #-----------------------------------------------------------------------------
    alias enhanced_pbStartScene pbStartScene
    def pbStartScene(*args)
      if Settings::SUMMARY_LEGACY_DATA
        UIHandlers.edit_hash(:summary, :page_memo, "options", 
          [:item, :nickname, :pokedex, _INTL("View Legacy"), :mark]
        )
      end
      @statToggle = false
      enhanced_pbStartScene(*args)
      @sprites["legacy_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      pbSetSystemFont(@sprites["legacy_overlay"].bitmap)
      @sprites["legacyicon"] = PokemonIconSprite.new(@pokemon, @viewport)
      @sprites["legacyicon"].setOffset(PictureOrigin::CENTER)
      @sprites["legacyicon"].visible = false
    end

    alias enhanced_pbPageCustomOption pbPageCustomOption
    def pbPageCustomOption(cmd)
      if cmd == _INTL("View Legacy")
        pbLegacyMenu
        return true
      end
      return enhanced_pbPageCustomOption(cmd)
    end
    
    #-----------------------------------------------------------------------------
    # Legacy data menu.
    #-----------------------------------------------------------------------------
    TOTAL_LEGACY_PAGES = 3
    
    def pbLegacyMenu    
      base2   = Color.new(246, 198, 6)
      shadow2 = Color.new(74, 97, 103)
      base = Color.new(248, 248, 248)
      shadow = Color.new(74, 112, 175)
      path = Settings::POKEMON_UI_GRAPHICS_PATH
      legacy_overlay = @sprites["legacy_overlay"].bitmap
      legacy_overlay.clear
      ypos = 62
      index = 0
      @sprites["legacyicon"].x = 64
      @sprites["legacyicon"].y = ypos + 64
      @sprites["legacyicon"].pokemon = @pokemon
      @sprites["legacyicon"].visible = true
      data = @pokemon.legacy_data
      dorefresh = true
      loop do
        Graphics.update
        Input.update
        pbUpdate
        textpos = []
        imagepos = []
        if Input.trigger?(Input::BACK)
          break
        elsif Input.trigger?(Input::UP) && index > 0
          index -= 1
          pbPlayCursorSE
          dorefresh = true
        elsif Input.trigger?(Input::DOWN) && index < TOTAL_LEGACY_PAGES - 1
          index += 1
          pbPlayCursorSE
          dorefresh = true
        end
        if dorefresh
          case index
          when 0  # General
            name = _INTL("General")
            hour = data[:party_time].to_i / 60 / 60
            min  = data[:party_time].to_i / 60 % 60
            addltext = [
              [_INTL("Total time in party:"),    "#{hour} hrs #{min} min"],
              [_INTL("Items consumed:"),         data[:item_count]],
              [_INTL("Moves learned:"),          data[:move_count]],
              [_INTL("Eggs produced:"),          data[:egg_count]],
              [_INTL("Number of times traded:"), data[:trade_count]]
            ]
          when 1  # Battle History
            name = _INTL("Battle History")
            addltext = [
              [_INTL("Opponents defeated:"),        data[:defeated_count]],
              [_INTL("Number of times fainted:"),   data[:fainted_count]],
              [_INTL("Supereffective hits dealt:"), data[:supereff_count]],
              [_INTL("Critical hits dealt:"),       data[:critical_count]],
              [_INTL("Total number of retreats:"),  data[:retreat_count]]
            ]
          when 2  # Team History
            name = _INTL("Team History")
            addltext = [
              [_INTL("Trainer battle victories:"),        data[:trainer_count]],
              [_INTL("Gym Leader battle victories:"),     data[:leader_count]],
              [_INTL("Wild legendary battle victories:"), data[:legend_count]],
              [_INTL("Total Hall of Fame inductions:"),   data[:champion_count]],
              [_INTL("Total draws or losses:"),           data[:loss_count]]
            ]
          end
          textpos.push([_INTL("{1}'S LEGACY", @pokemon.name.upcase), 295, ypos + 38, :center, base2, shadow2],
                      [name, Graphics.width / 2, ypos + 90, :center, base, shadow])
          addltext.each_with_index do |txt, i|
            textY = ypos + 134 + (i * 32)
            textpos.push([txt[0], 38, textY, :left, base, shadow])
            textpos.push([_INTL("{1}", txt[1]), Graphics.width - 38, textY, :right, base, shadow])
          end
          imagepos.push([path + "bg_legacy", 0, ypos])
          if index > 0
            imagepos.push([path + "arrows_legacy", 118, ypos + 84, 0, 0, 32, 32])
          end
          if index < TOTAL_LEGACY_PAGES - 1
            imagepos.push([path + "arrows_legacy", 362, ypos + 84, 32, 0, 32, 32])
          end
          legacy_overlay.clear
          pbDrawImagePositions(legacy_overlay, imagepos)
          pbDrawTextPositions(legacy_overlay, textpos)
          dorefresh = false
        end
      end
      legacy_overlay.clear
      @sprites["legacyicon"].visible = false
    end

    #-----------------------------------------------------------------------------
    # Aliased to add IV ratings.
    #-----------------------------------------------------------------------------
    alias enhanced_drawPageThree drawPageThree
    def drawPageThree
      if @statToggle
        @sprites["background"].setBitmap("Graphics/UI/Summary/bg_skills_eviv")
      else
        @sprites["background"].setBitmap("Graphics/UI/Summary/bg_skills")
      end
      (@statToggle) ? drawEnhancedStats : enhanced_drawPageThree
      return if !Settings::SUMMARY_IV_RATINGS
      overlay = @sprites["overlay"].bitmap
      pbDisplayIVRatingsSV(@pokemon, overlay, @statToggle)
    end

    def drawEnhancedStats
      overlay = @sprites["overlay"].bitmap
      base   = Color.new(246, 198, 6)
      shadow = Color.new(74, 97, 103)
      base2 = Color.new(248, 248, 248)
      shadow2 = Color.new(74, 112, 175)
      ev_total = 0
      iv_total = 0
      ivs = applyLowerBound([@pokemon.iv[:HP], @pokemon.iv[:ATTACK], @pokemon.iv[:DEFENSE], @pokemon.iv[:SPEED], @pokemon.iv[:SPECIAL_DEFENSE], @pokemon.iv[:SPECIAL_ATTACK]], 3)
      evs = applyLowerBound([@pokemon.ev[:HP], @pokemon.ev[:ATTACK], @pokemon.ev[:DEFENSE], @pokemon.ev[:SPEED], @pokemon.ev[:SPECIAL_DEFENSE], @pokemon.ev[:SPECIAL_ATTACK]], 25)
      @sprites["hexagon_stats"].bitmap.clear unless !@sprites["hexagon_stats"]
      @sprites["hexagon_stats"].draw_hexagon_with_values(181, 77, 42, 48, Color.new(72, 204, 240, 191), 31, ivs, 12, true, false)
      @sprites["hexagon_base_stats"].bitmap.clear unless !@sprites["hexagon_base_stats"]
      @sprites["hexagon_base_stats"].draw_hexagon_with_values(181, 77, 42, 48, Color.new(210, 255, 168, 191), 252, evs, 12, true, false)
      textpos = []
      textpos.push([_INTL("EV/IV"), 468, 44, :center, Color.new(248, 248, 248), Color.new(74, 112, 175)])
      GameData::Stat.each_main do |s|
        case s.id
        when :HP then xpos, ypos, align = 364, 44, :center
        when :ATTACK then xpos, ypos, align = 416, 102, :left
        when :DEFENSE then xpos, ypos, align = 416, 162, :left 
        when :SPECIAL_ATTACK then xpos, ypos, align = 310, 102, :right
        when :SPECIAL_DEFENSE then xpos, ypos, align = 310, 162, :right    
        when :SPEED then xpos, ypos, align = 364, 220, :center
        end
        name = (s.id == :SPECIAL_ATTACK) ? "Sp. Atk" : (s.id == :SPECIAL_DEFENSE) ? "Sp. Def" : s.name
        statbase = base
        statshadow = shadow
        if !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
          @pokemon.nature_for_stats.stat_changes.each do |change|
            next if s.id != change[0]
            if change[1] > 0
              statbase = Color.new(228, 66, 66)
              statshadow = Color.new(68, 57, 121)
            elsif change[1] < 0
              statbase = Color.new(60, 120, 252) 
              statshadow = Color.new(18, 73, 176)
            end
          end
        end 
        textpos.push([_INTL("{1}", name), xpos, ypos, align, statbase, statshadow])
        if (align == :center)
          textpos.push(
            [@pokemon.ev[s.id].to_s, xpos - 8, (ypos + 26), :right, base2, shadow2],
            [@pokemon.iv[s.id].to_s, xpos + 6, ypos + 26, :left, base2, shadow2]
          )
        elsif (align == :left)
          textpos.push(
            [@pokemon.ev[s.id].to_s, xpos, (ypos + 26), align, base2, shadow2],
            [@pokemon.iv[s.id].to_s, xpos + 50, ypos + 26, align, base2, shadow2]
          )
        elsif (align == :right)
          textpos.push(
            [@pokemon.ev[s.id].to_s, xpos - 36, (ypos + 26), align, base2, shadow2],
            [@pokemon.iv[s.id].to_s, xpos, ypos + 26, align, base2, shadow2]
          )
        end
        ev_total += @pokemon.ev[s.id]
        iv_total += @pokemon.iv[s.id]
      end
      textpos.push(
        [_INTL("EV/IV Total"), 222, 280, :left, base, shadow],
        [sprintf("%d | %d", ev_total, iv_total), 504, 280, :right, base2, shadow2],
        [_INTL("EV's Remaining:"), 222, 312, :left, base2, shadow2],
        [sprintf("%d/%d", Pokemon::EV_LIMIT - ev_total, Pokemon::EV_LIMIT), 504, 312, :right, base2, shadow2],
        [_INTL("Hidden Power Type:"), 222, 346, :left, base2, shadow2]
      )
      pbDrawTextPositions(overlay, textpos)
      hiddenpower = pbHiddenPower(@pokemon)
      type_number = GameData::Type.get(hiddenpower[0]).icon_position
      type_rect = Rect.new(0, type_number * 28, 64, 28)
      overlay.blt(428, 343, @typebitmap.bitmap, type_rect)
    end

    def pbDisplayIVRatingsSV(pokemon, overlay, evivpage)
      return if !pokemon
      imagepos = []
      path  = Settings::POKEMON_UI_GRAPHICS_PATH
      style = (Settings::IV_DISPLAY_STYLE == 0) ? 0 : 16
      maxIV = Pokemon::IV_STAT_LIMIT
      xpos = evivpage ? [400, 496, 496, 216, 216, 400]: [412, 458, 458, 252, 252, 388]
      ypos = [72, 130, 190, 130, 190, 248]
      i = 0
      GameData::Stat.each_main do |s|
        stat = pokemon.iv[s.id]
        case stat
        when maxIV     then icon = 5  # 31 IV
        when maxIV - 1 then icon = 4  # 30 IV
        when 0         then icon = 0  #  0 IV
        else
          if stat > (maxIV - (maxIV / 4).floor)
            icon = 3 # 25-29 IV
          elsif stat > (maxIV - (maxIV / 2).floor)
            icon = 2 # 16-24 IV
          else
            icon = 1 #  1-15 IV
          end
        end
        imagepos.push([
          path + "iv_ratings", xpos[i], ypos[i], icon * 16, style, 16, 16
        ])
        i += 1
      end
      pbDrawImagePositions(overlay, imagepos)
    end
  end
end