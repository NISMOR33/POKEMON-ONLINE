# --- Config ---
RSE_CHOICE_PATH     = "Graphics/UI/RSE Starter Choice"
MESSAGE_BASE_COLOR  = Color.new(99, 99, 99)
MESSAGE_SHADOW_COLOR= Color.new(214, 214, 206)

def vChooseStarters(pokemon = [], level = 5, message = "Choose your Starter Pokémon.")
  ret = nil
  unless pokemon.is_a?(Array)
    echoln "Couldn't show starter choices for #{pokemon}"
    echoln "The Pokemon argument must be an array..."
    return false
  end
  pbFadeOutIn {
    scene = RSESTarterChoice.new(pokemon, level, message)
    scene.pbStartScene
    scene.pbInputs
    ret = scene.pbEndScene
  }
  pbAddPokemon(ret)
  return ret
end

class RSESTarterChoice
  def initialize(pokemon, level, message)
    @pokemon_count = pokemon.length
    @pokemon       = pokemon.dup
    @generated_pokemon = []
    @species_cache = []
    @pokemon_count.times do |i|
      @generated_pokemon << Pokemon.new(@pokemon[i], level)
      @species_cache     << GameData::Species.get(@pokemon[i])
    end

    @message_show = message.is_a?(String) && !nil_or_empty?(message)
    @message      = @message_show ? message : ""

    @index        = 0
    @last_index   = -1
    @balls_index_last = -1

    @move_speed   = 16  # snappy at 60 FPS
    @sel_tx       = 0
    @sel_ty       = 0

    @needs_text_repaint   = true
    @pokemon_visible_last = false
  end

  def pbStartScene
    # Viewport & sprite hash
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}

    # Background
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["background"].setBitmap("#{RSE_CHOICE_PATH}/bg")

    # Bag
    @sprites["bag"] = IconSprite.new(Graphics.width / 2 + 32, Graphics.height / 3, @viewport)
    @sprites["bag"].setBitmap("#{RSE_CHOICE_PATH}/bag")
    @sprites["bag"].ox = @sprites["bag"].bitmap.width / 2
    @sprites["bag"].oy = @sprites["bag"].bitmap.height / 2

    # Infobox
    @sprites["infobox"] = IconSprite.new(Graphics.width / 2, Graphics.height / 3 - 32, @viewport)
    @sprites["infobox"].setBitmap("#{RSE_CHOICE_PATH}/infobox")
    @sprites["infobox"].ox = @sprites["infobox"].bitmap.width / 2
    @sprites["infobox"].oy = @sprites["infobox"].bitmap.height / 2
    @info_x = @sprites["infobox"].x
    @info_y = @sprites["infobox"].y

    # Poké Balls
    @pokemon_count.times do |i|
      spr = AnimatedSprite.new("#{RSE_CHOICE_PATH}/ball", 4, 48, 40, 2, @viewport)
      spr.ox = 24
      pos = calcPos(i)
      spr.x = pos[0]
      spr.y = pos[1] + 64
      spr.play if i == @index
      @sprites["ball#{i}"] = spr
    end

    # Selection arrow
    @sprites["sel"] = AnimatedSprite.new("#{RSE_CHOICE_PATH}/sel", 4, 64, 84, 2, @viewport)
    @sprites["sel"].ox = 32
    pos = calcPos(@index)
    @sprites["sel"].x = pos[0]
    @sprites["sel"].y = pos[1]
    @sel_tx, @sel_ty = pos[0], pos[1]
    @sprites["sel"].play
    @sprites["sel"].visible = false

    # Message window
    msgWindow = Window_AdvancedTextPokemon.newWithSize("", 16, Graphics.height - 96 + 2, Graphics.width - 32, 96, @viewport)
    msgWindow.baseColor      = MESSAGE_BASE_COLOR
    msgWindow.shadowColor    = MESSAGE_SHADOW_COLOR
    msgWindow.letterbyletter = false  # perf: off
    @sprites["messageWindow"] = msgWindow
    @sprites["messageWindow"].text = @message

    # Showcase backdrop
    @sprites["showcase"] = IconSprite.new(Graphics.width / 2, Graphics.height / 2, @viewport)
    @sprites["showcase"].setBitmap("#{RSE_CHOICE_PATH}/select")
    @sprites["showcase"].ox = @sprites["showcase"].bitmap.width / 2
    @sprites["showcase"].oy = @sprites["showcase"].bitmap.height / 2
    @sprites["showcase"].zoom_x = 0
    @sprites["showcase"].zoom_y = 0
    @sprites["showcase"].visible = false

    # Pokémon sprite
    @sprites["pokemon"] = PokemonSprite.new(@viewport)
    @sprites["pokemon"].setOffset(PictureOrigin::CENTER)
    @sprites["pokemon"].x = Graphics.width / 2
    @sprites["pokemon"].y = Graphics.height / 2
    @sprites["pokemon"].visible = false

    # Overlay text layer
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)

    # Fade in & reveal selector last
    pbFadeInAndShow(@sprites)
    @sprites["sel"].visible = true
  end

  def pbUpdate
    # Repaint text only when needed
    if @index != @last_index || @needs_text_repaint || (@pokemon_visible_last != @sprites["pokemon"].visible)
      pkmn = @species_cache[@index]
      base   = Color.new(248, 248, 248)
      shadow = Color.new(214, 214, 206)
      bmp = @sprites["overlay"].bitmap
      bmp.clear
      if @sprites["pokemon"].visible
        textpos = [[pkmn.name, @info_x, @info_y - 24, 2, base, shadow]]
      else
        textpos = [
          ["#{pkmn.category} Pokémon", @info_x, @info_y - 24, 2, base, shadow],
          [pkmn.name, @info_x, @info_y + 8, 2, base, shadow]
        ]
      end
      pbDrawTextPositions(bmp, textpos)
      @last_index = @index
      @needs_text_repaint = false
      @pokemon_visible_last = @sprites["pokemon"].visible
    end

    # Only start/stop ball anims on index change
    if @index != @balls_index_last
      @pokemon_count.times do |i|
        if i == @index
          @sprites["ball#{i}"].play unless @sprites["ball#{i}"].playing?
        else
          @sprites["ball#{i}"].stop
          @sprites["ball#{i}"].frame = 0
        end
      end
      @balls_index_last = @index
    end

    # Tween selector (no blocking waits)
    @sprites["sel"].x = move_to(@sprites["sel"].x, @sel_tx, @move_speed)
    @sprites["sel"].y = move_to(@sprites["sel"].y, @sel_ty - 24, @move_speed)

    pbUpdateSpriteHash(@sprites)
  end

  def pbInputs
    loop do
      Graphics.update
      Input.update
      pbUpdate

      if Input.trigger?(Input::LEFT) && @index > 0
        pbPlayCursorSE
        @index -= 1
        pos = calcPos(@index)
        @sel_tx, @sel_ty = pos[0], pos[1]
        @needs_text_repaint = true
      elsif Input.trigger?(Input::RIGHT) && @index < @pokemon_count - 1
        pbPlayCursorSE
        @index += 1
        pos = calcPos(@index)
        @sel_tx, @sel_ty = pos[0], pos[1]
        @needs_text_repaint = true
      elsif Input.trigger?(Input::BACK)
        pbPlayBuzzerSE
      elsif Input.trigger?(Input::USE)
        @sprites["messageWindow"].visible = false
        pkmn = @generated_pokemon[@index]
        showPkmn(pkmn)
        if pbConfirmMessage(_INTL("Would you like to choose {1}?", pkmn.name))
          pbPlayDecisionSE
          break
        end
        # Cancel selection: animate out cleanly
        @sprites["pokemon"].visible = false
        5.times do
          @sprites["showcase"].zoom_x -= 0.2
          @sprites["showcase"].zoom_y -= 0.2
          Graphics.update; Input.update; pbUpdate
        end
        @sprites["showcase"].zoom_x = 0
        @sprites["showcase"].zoom_y = 0
        @sprites["showcase"].visible = false
        @sprites["messageWindow"].visible = true
        @needs_text_repaint = true
      end
    end
  end

  # Frame-friendly step toward a target
  def move_to(start, stop, step)
    delta = stop - start
    return stop if delta.abs <= step
    start + (delta < 0 ? -step : step)
  end

  def showPkmn(pkmn = nil)
    return false if pkmn.nil?
    @sprites["showcase"].visible = true
    10.times do
      @sprites["showcase"].zoom_x += 0.1
      @sprites["showcase"].zoom_y += 0.1
      Graphics.update; Input.update; pbUpdate
    end
    @sprites["pokemon"].visible = true
    pkmn.play_cry
    @sprites["pokemon"].setPokemonBitmap(pkmn)
    @needs_text_repaint = true
    pbUpdate
  end

  def calcPos(n)
    offset  = 128
    fractX  = (Graphics.width - offset) / (@pokemon_count + 1)
    retX    = fractX * (n + 1) + offset / 2
    middle  = (@pokemon_count - 1).to_f / 2
    dist_m  = (middle - n).abs
    retY    = Graphics.height / 2 - 16 * dist_m - 106 + 16 * @pokemon_count - 32 * (@pokemon_count.to_f / 4).floor
    [retX, retY]
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
    return @generated_pokemon[@index]
  end
end
