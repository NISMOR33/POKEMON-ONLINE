class PokedexListSprite < Sprite
  PAGE_SIZE = 20
  ROW_SIZE  = 5
  ICON_GAP  = 80
  PAGE_X    = 94
  PAGE_Y    = 66 
  SHOW_SIHOUTTE_FOR_UNSEEN_SPECIES = true
  USE_GOLD_NUMBER_FOR_SHINY        = true

  attr_reader :page, :index, :dexlist

  def initialize(viewport)
    super(viewport)
    @index = 0
    @page  = 0
    @dexlist = []
    @pkmnsprites = []
    PAGE_SIZE.times do |i|
      @pkmnsprites[i] = PokemonSpeciesIconSprite.new(nil, viewport)
      @pkmnsprites[i].x = PAGE_X + ICON_GAP * (i % ROW_SIZE)
      @pkmnsprites[i].y = PAGE_Y + ICON_GAP * (i / ROW_SIZE)
      @pkmnsprites[i].setOffset(PictureOrigin::CENTER)
    end
    @numbersbitmap = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_numbers")
    @ballBitmap    = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_menu_own")
    @contents      = Bitmap.new(402, 322)
    self.bitmap = @contents
    self.x = 54
    self.y = 8
  end

  def dispose
    if !disposed?
      PAGE_SIZE.times do |i|
        @pkmnsprites[i]&.dispose
        @pkmnsprites[i] = nil
      end
      @contents.dispose
      @numbersbitmap.dispose
      @ballBitmap.dispose
      super
    end
  end
  
  def clear_all_icons
    PAGE_SIZE.times do |i|
      if @pkmnsprites[i] && !@pkmnsprites[i].disposed?
        @pkmnsprites[i].visible = false
      end
    end
  end

  def visible=(value)
    super
    PAGE_SIZE.times do |i|
      if @pkmnsprites[i] && !@pkmnsprites[i].disposed?
        @pkmnsprites[i].visible = value
      end
    end
    refresh if value
  end
  
  def color=(value)
    super
    PAGE_SIZE.times do |i|
      if @pkmnsprites[i] && !@pkmnsprites[i].disposed?
        @pkmnsprites[i].color = value 
      end
    end
  end

  def index=(value)
    old_page = @page
    @index = value
    @page = (@index / PAGE_SIZE).floor
    refresh if @page != old_page && self.visible
  end

  def dexlist=(value)
    @dexlist = value
    refresh if self.visible
  end
  
  def commands=(value)
    self.dexlist = value
  end

  def refresh
    @contents.clear
    return if @dexlist.length == 0 || !self.visible
    PAGE_SIZE.times do |i|
      idx = @page * PAGE_SIZE + i 
      if idx < @dexlist.length
        species = @dexlist[idx][:species]
        gender, form, shiny = $player.pokedex.last_form_seen(species)
        @pkmnsprites[i].pbSetParams(species, gender, form, shiny)
        @pkmnsprites[i].visible = true
        dex_num = @dexlist[idx][:number]
        dex_num -= 1 if @dexlist[idx][:shift]
        numtext = sprintf("%03d", dex_num)
        style   = ($player.owned?(species)) ? 1 : 0
        style   = 2 if $player.owned?(species) && shiny && USE_GOLD_NUMBER_FOR_SHINY
        x = 76 + ICON_GAP * (i % ROW_SIZE)
        y = 4 + ICON_GAP * (i / ROW_SIZE)
        drawDexNumber(numtext, @contents, x, y, style)
        ball_x = x - 72
        ball_y = y
        pbCopyBitmap(@contents, @ballBitmap.bitmap, ball_x, ball_y) if $player.owned?(species)
        if $player.seen?(species)
          @pkmnsprites[i].opacity = ($player.owned?(species)) ? 255 : 64
          @pkmnsprites[i].tone    = Tone.new(0, 0, 0, 0)
        else
          @pkmnsprites[i].opacity = 64
          if SHOW_SIHOUTTE_FOR_UNSEEN_SPECIES
            @pkmnsprites[i].tone    = Tone.new(-255, -255, -255, 255) 
          else
            @pkmnsprites[i].visible = false
          end
        end
      else
        @pkmnsprites[i].visible = false
      end
    end
  end
  
  def species
    return @dexlist[@index][:species]
  end

  def drawDexNumber(number, btmp, x, y, style)
    charWidth  = @numbersbitmap.width / 10
    charHeight = @numbersbitmap.height / 3
    x -= charWidth * number.length
    number.each_char do |i|
      btmp.blt(x, y, @numbersbitmap.bitmap, Rect.new(i.to_i * charWidth, style * charHeight, charWidth, charHeight))
      x += charWidth
    end
  end
end

class PokemonPokedex_Scene
  def pbStartScene
    @sliderbitmap       = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_slider")
    @typebitmap         = AnimatedBitmap.new(_INTL("Graphics/UI/Pokedex/icon_types"))
    @shapebitmap        = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_shapes")
    @hwbitmap           = AnimatedBitmap.new(_INTL("Graphics/UI/Pokedex/icon_hw"))
    @selbitmap          = AnimatedBitmap.new("Graphics/UI/Pokedex/icon_searchsel")
    @searchsliderbitmap = AnimatedBitmap.new(_INTL("Graphics/UI/Pokedex/icon_searchslider"))
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    addBackgroundPlane(@sprites, "background", "Pokedex/bg_list", @viewport)
    addBackgroundPlane(@sprites, "searchbg", "Pokedex/bg_search", @viewport)
    @sprites["searchbg"].visible = false
    @sprites["pokedex"] = PokedexListSprite.new(@viewport)
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["searchcursor"] = PokedexSearchSelectionSprite.new(@viewport)
    @sprites["searchcursor"].visible = false
    @searchResults = false
    @searchParams  = [$PokemonGlobal.pokedexMode, -1, -1, -1, -1, -1, -1, -1, -1, -1]
    pbRefreshDexList($PokemonGlobal.pokedexIndex[pbGetSavePositionIndex])
    pbDeactivateWindows(@sprites)
    pbFadeInAndShow(@sprites)
  end

  def pbRefresh
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    index = @sprites["pokedex"].index
    imagepos = []
    # Draw Slider.
    showslider = false
    page_size = PokedexListSprite::PAGE_SIZE
    row_size  = PokedexListSprite::ROW_SIZE
    dex_len   = @sprites["pokedex"].dexlist.length
    max_page  = (dex_len.to_f / page_size).ceil - 1
    if @sprites["pokedex"].page > 0
      overlay.blt(464, 12, @sliderbitmap.bitmap, Rect.new(0, 0, 40, 30))
      showslider = true
    end
    if @sprites["pokedex"].page < max_page
      overlay.blt(464, 262, @sliderbitmap.bitmap, Rect.new(0, 30, 40, 30))
      showslider = true
    end
    if showslider && max_page > 0
      sliderheight = 220
      boxheight = [ (sliderheight / (max_page + 1)).floor, 40 ].max
      y = 42 + ((sliderheight - boxheight) * @sprites["pokedex"].page / max_page).floor
      overlay.blt(464, y, @sliderbitmap.bitmap, Rect.new(40, 0, 40, 8))
      i = 0
      while i * 16 < boxheight - 24
        overlay.blt(464, y + 8 + (i * 16), @sliderbitmap.bitmap, Rect.new(40, 8, 40, 16))
        i += 1
      end
      overlay.blt(464, y + boxheight - 16, @sliderbitmap.bitmap, Rect.new(40, 24, 40, 16))
    end
    # Cursor and Species Name.
    pageidx = index % page_size
    cursorX = 52 + (pageidx % row_size) * 80
    cursorY = 6 + (pageidx / row_size) * 80
    imagepos.push(["Graphics/UI/Pokedex/cursor_list", cursorX, cursorY])
    imagepos.push(["Graphics/UI/Pokedex/overlay_name", 88, 332])
    pbDrawImagePositions(overlay, imagepos) 
    species_data = GameData::Species.try_get(@sprites["pokedex"].species)
    display_name = $player.seen?(@sprites["pokedex"].species) ? species_data.name : "?????"
    pbDrawTextPositions(overlay, [[display_name, 256, 340, :center, Color.new(248, 248, 248), Color.new(104, 104, 104)]])
    @sprites["pokedex"].refresh
  end

  def pbPokedex
    loop do
      Graphics.update
      Input.update
      pbUpdate
      oldindex  = @sprites["pokedex"].index
      dexlength = @sprites["pokedex"].dexlist.length
      pagesize  = PokedexListSprite::PAGE_SIZE
      rowsize   = PokedexListSprite::ROW_SIZE
      if Input.repeat?(Input::UP)
        @sprites["pokedex"].index = (oldindex - rowsize) % dexlength
      elsif Input.repeat?(Input::DOWN)
        @sprites["pokedex"].index = (oldindex + rowsize) % dexlength
      elsif Input.repeat?(Input::LEFT)
        @sprites["pokedex"].index = (oldindex - 1) % dexlength
      elsif Input.repeat?(Input::RIGHT)
        @sprites["pokedex"].index = (oldindex + 1) % dexlength
      elsif Input.repeat?(Input::JUMPUP)
        if oldindex > pagesize
          @sprites["pokedex"].index -= pagesize
        elsif oldindex < dexlength % pagesize
          @sprites["pokedex"].index = (dexlength / pagesize) * pagesize + oldindex
        else
          @sprites["pokedex"].index = dexlength - 1
        end
      elsif Input.repeat?(Input::JUMPDOWN)
        if oldindex + pagesize < dexlength
          @sprites["pokedex"].index += pagesize
        elsif oldindex < (dexlength / pagesize) * pagesize
          @sprites["pokedex"].index = dexlength - 1
        else
          @sprites["pokedex"].index = oldindex % pagesize
        end
      elsif Input.trigger?(Input::ACTION)
        pbSEPlay("GUI pokedex open")
        pbDexSearch
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        if @searchResults
          pbCloseSearch
        else
          break
        end
      elsif Input.trigger?(Input::USE)
        if $player.seen?(@sprites["pokedex"].species)
          pbSEPlay("GUI pokedex open")
          pbDexEntry(@sprites["pokedex"].index)
        end
      end
      if oldindex != @sprites["pokedex"].index
        pbPlayCursorSE
        $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex] = @sprites["pokedex"].index if !@searchResults
        pbRefresh
      end
    end
  end
end