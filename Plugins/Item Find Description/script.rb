#-------------------------------------------------------------------------------
# Item Find
# v2.1
# By Boonzeet
# Updated by JulieHaru
#-------------------------------------------------------------------------------
# A script to show a helpful message with item name, icon and description
# when an item is found for the first time.
#-------------------------------------------------------------------------------

WINDOWSKIN_NAME = "" # set for custom windowskin

#-------------------------------------------------------------------------------
# Save data registry
#-------------------------------------------------------------------------------
SaveData.register(:item_log) do
  save_value { $item_log }
  load_value { |value|  $item_log = value }
  new_game_value { ItemLog.new }
end

#-------------------------------------------------------------------------------
# Base Class
#-------------------------------------------------------------------------------

class PokemonItemFind_Scene
  def pbStartScene
    echoln "[ITEM FIND] pbStartScene"

    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    skin = WINDOWSKIN_NAME == "" ? MessageConfig.pbGetSystemFrame : "Graphics/Windowskins/" + WINDOWSKIN_NAME
        
    @sprites["background"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, Graphics.width, 0, @viewport)
    @sprites["background"].z = @viewport.z - 1
    @sprites["background"].visible = false
    @sprites["background"].setSkin(skin)
    
    colors = getDefaultTextColors(@sprites["background"].windowskin)

    @sprites["itemicon"] = ItemIconSprite.new(42, Graphics.height - 48, nil, @viewport)
    @sprites["itemicon"].visible = false
    @sprites["itemicon"].z = @viewport.z + 2
	
    @sprites["descwindow"] = Window_UnformattedTextPokemon.newWithSize("", 64, 0, Graphics.width - 64, 64, @viewport)
    @sprites["descwindow"].windowskin = nil
    @sprites["descwindow"].z = @viewport.z
    @sprites["descwindow"].visible = false
    @sprites["descwindow"].baseColor = colors[0]
    @sprites["descwindow"].shadowColor = colors[1]

    @sprites["titlewindow"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, 128, 16, @viewport)
    @sprites["titlewindow"].visible = false
    @sprites["titlewindow"].z = @viewport.z + 1
    @sprites["titlewindow"].windowskin = nil
    @sprites["titlewindow"].baseColor = Color.new(0, 112, 248)
    @sprites["titlewindow"].shadowColor = Color.new(120, 184, 232)
  end

  def pbShow(item)
    item_object = GameData::Item.get(item)
    name = item_object.name
    description = item_object.description

    descwindow = @sprites["descwindow"]
    descwindow.resizeToFit(description, Graphics.width - 64)
    descwindow.text = description
    descwindow.y = Graphics.height - descwindow.height
    descwindow.visible = true

    titlewindow = @sprites["titlewindow"]
    titlewindow.resizeToFit(name, Graphics.height)
    titlewindow.text = name
    titlewindow.y = Graphics.height - descwindow.height - 32
    titlewindow.visible = true

    background = @sprites["background"]
    background.height = descwindow.height + 32
    background.y = Graphics.height - background.height
    background.visible = true

    itemicon = @sprites["itemicon"]
    itemicon.item = item
    itemicon.y = Graphics.height - (descwindow.height / 2).floor
    itemicon.visible = true

    loop do
      background.update
      itemicon.update
      descwindow.update
      titlewindow.update
      Graphics.update
      Input.update
      pbUpdateSceneMap
      if Input.trigger?(Input::B) || Input.trigger?(Input::C)
        pbEndScene
        break
      end
    end
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end


#-------------------------------------------------------------------------------
# Item Log class
#-------------------------------------------------------------------------------
# The store of found items
#-------------------------------------------------------------------------------
class ItemLog
  def initialize()
    @found_items = []
  end

  def register(item)
    if !@found_items.include?(item)
      @found_items.push(item)
      scene = PokemonItemFind_Scene.new
      scene.pbStartScene
      scene.pbShow(item)
    end
  end
end

#-------------------------------------------------------------------------------
# Overrides of pbItemBall and pbReceiveItem
#-------------------------------------------------------------------------------
# Picking up an item found on the ground
#-------------------------------------------------------------------------------

def pbItemBall(item, quantity = 1)
  item = GameData::Item.get(item)
  return false if !item || quantity < 1
  itemname = (quantity > 1) ? item.portion_name_plural : item.portion_name
  pocket = item.pocket
  move = item.move
  if $bag.add(item, quantity)   # If item can be picked up
    meName = (item.is_key_item?) ? "Key item get" : "Item get" 
    if item == :DNASPLICERS
      pbMessage("\\me[#{meName}]" + _INTL("You found \\c[1]{1}\\c[0]!", itemname) + "\\wtnp[40]")
    elsif item.is_machine?   # TM or HM
      if quantity > 1
        pbMessage("\\me[Machine get]" + _INTL("You found {1} \\c[1]{2} {3}\\c[0]!",
                                              quantity, itemname, GameData::Move.get(move).name) + "\\wtnp[70]")
      else
        pbMessage("\\me[Machine get]" + _INTL("You found \\c[1]{1} {2}\\c[0]!",
                                              itemname, GameData::Move.get(move).name) + "\\wtnp[70]")
      end
    elsif quantity > 1
      pbMessage("\\me[#{meName}]" + _INTL("You found {1} \\c[1]{2}\\c[0]!", quantity, itemname) + "\\wtnp[40]")
    elsif itemname.starts_with_vowel?
      pbMessage("\\me[#{meName}]" + _INTL("You found an \\c[1]{1}\\c[0]!", itemname) + "\\wtnp[40]")
    else
      pbMessage("\\me[#{meName}]" + _INTL("You found a \\c[1]{1}\\c[0]!", itemname) + "\\wtnp[40]")
    end
    pbMessage(_INTL("You put the {1} in\\nyour Bag's <icon=bagPocket{2}>\\c[1]{3}\\c[0] pocket.",
                    itemname, pocket, PokemonBag.pocket_names[pocket - 1]))

    $item_log.register(item) if true
    return true
  end
  # Can't add the item
  if item.is_machine?   # TM or HM
    if quantity > 1
      pbMessage(_INTL("You found {1} \\c[1]{2} {3}\\c[0]!", quantity, itemname, GameData::Move.get(move).name))
    else
      pbMessage(_INTL("You found \\c[1]{1} {2}\\c[0]!", itemname, GameData::Move.get(move).name))
    end
  elsif quantity > 1
    pbMessage(_INTL("You found {1} \\c[1]{2}\\c[0]!", quantity, itemname))
  elsif itemname.starts_with_vowel?
    pbMessage(_INTL("You found an \\c[1]{1}\\c[0]!", itemname))
  else
    pbMessage(_INTL("You found a \\c[1]{1}\\c[0]!", itemname))
  end
  pbMessage(_INTL("But your Bag is full..."))
  return false
end

def pbReceiveItem(item, quantity = 1)
  item = GameData::Item.get(item)
  return false if !item || quantity < 1
  itemname = (quantity > 1) ? item.portion_name_plural : item.portion_name
  pocket = item.pocket
  move = item.move
  meName = (item.is_key_item?) ? "Key item get" : "Item get"
  
  if item == :DNASPLICERS
    pbMessage("\\me[#{meName}]" + _INTL("You obtained \\c[1]{1}\\c[0]!", itemname) + "\\wtnp[40]")
  elsif item.is_machine?   # TM or HM
    if quantity > 1
      pbMessage("\\me[Machine get]" + _INTL("You obtained {1} \\c[1]{2} {3}\\c[0]!",
                                            quantity, itemname, GameData::Move.get(move).name) + "\\wtnp[70]")
    else
      pbMessage("\\me[Machine get]" + _INTL("You obtained \\c[1]{1} {2}\\c[0]!",
                                            itemname, GameData::Move.get(move).name) + "\\wtnp[70]")
    end
  elsif quantity > 1
    pbMessage("\\me[#{meName}]" + _INTL("You obtained {1} \\c[1]{2}\\c[0]!", quantity, itemname) + "\\wtnp[40]")
  elsif itemname.starts_with_vowel?
    pbMessage("\\me[#{meName}]" + _INTL("You obtained an \\c[1]{1}\\c[0]!", itemname) + "\\wtnp[40]")
  else
    pbMessage("\\me[#{meName}]" + _INTL("You obtained a \\c[1]{1}\\c[0]!", itemname) + "\\wtnp[40]")
  end
  if $bag.add(item, quantity)   # If item can be added
    pbMessage(_INTL("You put the {1} in\\nyour Bag's <icon=bagPocket{2}>\\c[1]{3}\\c[0] pocket.",
                    itemname, pocket, PokemonBag.pocket_names[pocket - 1]))
    
    $item_log.register(item) if true
    return true
  end
  return false   # Can't add the item
end


def pbPickBerry(berry, qty = 1)
  berry = GameData::Item.get(berry)
  berry_name = (qty > 1) ? berry.portion_name_plural : berry.portion_name
  if qty > 1
    message = _INTL("There are {1} \\c[1]{2}\\c[0]!\nWant to pick them?", qty, berry_name)
  else
    message = _INTL("There is 1 \\c[1]{1}\\c[0]!\nWant to pick it?", berry_name)
  end
  return false if !pbConfirmMessage(message)
  if !$bag.can_add?(berry, qty)
    pbMessage(_INTL("Too bad...\nThe Bag is full..."))
    return false
  end
  $stats.berry_plants_picked += 1
  if qty >= GameData::BerryPlant.get(berry.id).maximum_yield
    $stats.max_yield_berry_plants += 1
  end
  $bag.add(berry, qty)
  if qty > 1
    pbMessage("\\me[Berry get]" + _INTL("You picked the {1} \\c[1]{2}\\c[0].", qty, berry_name) + "\\wtnp[30]")
  else
    pbMessage("\\me[Berry get]" + _INTL("You picked the \\c[1]{1}\\c[0].", berry_name) + "\\wtnp[30]")
  end
  pocket = berry.pocket
  pbMessage(_INTL("You put the {1} in\\nyour Bag's <icon=bagPocket{2}>\\c[1]{3}\\c[0] pocket.",
                  berry_name, pocket, PokemonBag.pocket_names[pocket - 1]) + "\1")
  if Settings::NEW_BERRY_PLANTS
    pbMessage(_INTL("The soil returned to its soft and earthy state."))
  else
    pbMessage(_INTL("The soil returned to its soft and loamy state."))
  end
  this_event = pbMapInterpreter.get_self
  pbSetSelfSwitch(this_event.id, "A", true)

  $item_log.register(berry) if true
  return true
end