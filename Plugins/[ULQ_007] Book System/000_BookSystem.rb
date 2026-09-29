#===============================================================================
# BOOK SYSTEM
#===============================================================================
# 
# HOW TO USE THIS BOOK SYSTEM:
# 
# 1. CREATING A BOOK:
#    Add a new entry to the BookConfig::BOOKS hash with a unique ID.
#    Each book has a title and an array of pages (strings).
#
# 2. CALLING A BOOK IN EVENTS:
#    Use: pbCallBook(book_id, "label_name")
#    - book_id: The ID of the book (integer, e.g., 1, 2, 3)
#    - label_name: (Optional) Name of a label to jump to after closing the book
#                  Pass nil or omit this parameter if you don't need label jumping
#
# 3. LABEL JUMPING:
#    After the player closes the book, the script will automatically jump to 
#    the event label you specified. This allows you to continue the event flow
#    at a specific point (useful for branching dialogue).
#
# EXAMPLES:
#    pbCallBook(1)                 # Open book 1, no label jump
#    pbCallBook(1, "after_reading") # Open book 1, jump to "after_reading" label when closed
#
#===============================================================================

module BookConfig
  
  #=============================================================================
  # Define all your books here in this hash.
  # Format: ID => { :title => "Book Title", :pages => ["Page 1 text", "Page 2 text", ...] }
  #=============================================================================
  BOOKS = {
    # Example Book 1: Multi-page book
    1 => {
      :title => "Nasty note from Professor Oak",
      :pages => [
        "You little rat, you still haven't completed the Pokédex??!",
        "If I see you, I'll smash you to pieces",
        "And then throw yourself to the Magikarp!"
      ]
    },
    # Example Book 2: Two-page book
    2 => {
      :title => "Two pages - notes",
      :pages => [
        "I still have to go shopping for some delicious Magikarp meat",
        "But of course, I throw the Magikarp back into the water so it can swim away"
      ]
    },
    # Example Book 3: Single-page book
    3 => {
      :title => "One-page report",
      :pages => [
        "The Pidgeys have become very dangerous lately; Bob died because of them."
      ]
    },
    
	4 => {
      :title => "Find my Skitty!",
      :pages => [
        "I lost my Skitty in Petalburg Woods while we were traveling to Rustboro City. I'm scared of the filthy bugs in that forest, so I would rather have someone else, like a Pokémon Ranger, find her for me.",
        "Please take this request and find her for me. I beg of you...",
		"Rewards: 6000$",
		"Mission Difficulty: 1/5"
      ]
    },

    5 => {
      :title => "The Seashore Robbery!",
      :pages => [
        "Someone stole a bunch of Soda Pops from my restaurant, the Seashore House near Slateport City. If anyone can meet me at the Seashore House, I can provide more information.",
		"Rewards: 6x Soda Pops, 2500$",
		"Mission Difficulty: 2/5"
      ]
    },
	
    6 => {
      :title => "Catch an Abra for Me",
      :pages => [
        "I have always wanted an Abra of my own, but I don't know where to find one. Someone, please trade me an Abra, and I'll give you something cool in return!",
		"Rewards: Pikachu",
		"Mission Difficulty: 2/5"
      ]
    },
	
    7 => {
      :title => "Brother Trouble",
      :pages => [
        "My brother has this crazy idea of taking on the Gym Challenge and leaving Dewford Island. I want a strong Ranger or Trainer to show him that it isn't such a smart idea. Show him that being a Trainer isn't as easy as it looks.",
		"Rewards: 1x Carbos",
		"Mission Difficulty: 1/5"
      ]
    },
	
    8 => {
      :title => "Lost Person",
      :pages => [
        "A few days ago, someone went inside Granite Cave to explore its dark depths. A few days later, he still hasn't returned. I need a capable Ranger to go in and find him.",
		"Rewards: 1x Lagging Tail, 1x Revive",
		"Mission Difficulty: 2/5"
      ]
    },
	
	9 => {
	  :title => "Defeat All of the Sandygast",
	  :pages => [
		"We need help taking down all of the Sandygast on Route 106.",
		"There are four of them in total, and we just need to prove that they are gone so they will leave our beach alone!",
		"Rewards: 2x Dive Balls, 2x Super Potions",
		"Mission Difficulty: 1/5"
	  ]
	},
	
    10 => {
      :title => "Trick House Materials",
      :pages => [
        "I need a few materials for my Trick House on Route 110. If you're interested in finding them for me, I shall be waiting outside my house. Meet me there, and I will give you more details...",
		"Rewards: 1x TM104 Throat Chop, 1x Moon Stone, 3x Timer Balls",
		"Mission Difficulty: 3/5"
      ]
    },
	
	11 => {
	  :title => "Unwanted Krabby",
	  :pages => [
		"The beach on Route 115 is flooded with a bunch of unwanted Krabby. We need someone like a Pokémon Ranger to drive them away.",
		"Rewards: 1x Nugget",
		"Mission Difficulty: 2/5"
	  ]
	},
	
	12 => {
	  :title => "Rustboro Sewers Pokémon",
	  :pages => [
		"A Pokémon is stirring up trouble in the sewers of Rustboro City. We would like a Pokémon Ranger to go take care of it. ",
		"Head to Devon Corporation and talk to the lady at the counter for more details.",
		"Rewards: 1x Black Sludge, $3000",
		"Mission Difficulty: 3/5",
		"Recommended Level for 1-2 Badges: 25"
	  ]
	},
	
	13 => {
	  :title => "Mirage Island Pokémon Encounter",
	  :pages => [
		"A Pokémon has been causing problems on the island near our Ranger Guild. We need a Ranger to surf over there and take it down!",
		"Requirements: Ability to Surf, 5 Gym Badges",
		"Rewards: 1x Absorb Bulb, 1x Sun Stone, 1x Energy Root",
		"Mission Difficulty: 3.5/5",
		"Levels scale depending on Gym Badge count."
	  ]
	},
	
	14 => {
	  :title => "Lost Locket",
	  :pages => [
		"I was exploring the Abandoned Ship when I lost something important to me. A strange Pokémon appeared out of thin air, and the locket fell out of my pocket. Meet me outside the ship.",
		"Requirements: Ability to Surf, 5 Gym Badges",
		"Rewards: 1x Ability Capsule, 1x Ability Urge",
		"Mission Difficulty: 3.5/5",
		"Levels scale depending on Gym Badge count."
	  ]
	},
	
	15 => {
	  :title => "Duel Game",
	  :pages => [
		"I need someone to fight. I want to show off my defense, precise attacks, fierce attacks, and special attacks. Please, some Ranger, accept my request and take a beating from me!",
		"Rewards: TM75 Swords Dance, 1x Covert Cloak",
		"Mission Difficulty: 3/5"
	  ]
	},
	
	16 => {
	  :title => "Poker Wilds",
	  :pages => [
		"I created a poker game inspired by the game from Dragon Quest. I want to show the Game Corner that it can be fun!",
		"Could a Ranger come over and try it for me? I need someone else to play it. You will need a Coin Case, but don't worry about the coins.",
		"Rewards: 1x Loaded Dice, 200 Coins for the Coin Case",
		"Mission Difficulty: 1.5/5"
	  ]
	},
	
	17 => {
	  :title => "Where Are My Glasses?",
	  :pages => [
		"I dropped my glasses somewhere... I'm currently on Route 116 looking for them. Can someone please help me? Come speak to me on Route 116, and I can give you more information.",
		"Rewards: 1x Wise Glasses, 2x Carbos",
		"Mission Difficulty: 1.5/5"
	  ]
	},
	
	18 => {
	  :title => "Shore Package Delivery",
	  :pages => [
		"A package washed up on the shore of Route 118. I have it in my possession, and it seems to have a return address.",
		"I am busy fishing. Can a Ranger deliver it for me? The recipient lives in Slateport City.",
		"Rewards: 1x Mystic Water, 5x Net Balls",
		"Mission Difficulty: 1/5"
	  ]
	},
	
	19 => {
	  :title => "Winstrate Family Passion",
	  :pages => [
		"We need someone strong to face. Our family never loses to random traveling Trainers, so I thought of a different approach.",
		"Maybe the Ranger Guild has a strong Trainer for us to face. What do you say? Are you up for taking on our family in a series of four Pokémon battles?",
		"Rewards: Lucky Egg",
		"Mission Difficulty: 3/5 - Depends on your levels"
	  ]
	},
	
	20 => {
	  :title => "Route 103 Berry Thief",
	  :pages => [
		"A very strong Pokémon has been causing trouble for people on Route 103. It has also been eating many of the berries normally left for other wild Pokémon.",
		"We need a Ranger to take it down!",
		"Rewards: 3x Lum Berries, 5x Sitrus Berries",
		"Mission Difficulty: 3.5/5",
		"Levels scale depending on Gym Badge count."
	  ]
	},
	
	21 => {
	  :title => "Daycare Delivery",
	  :pages => [
		"We need to deliver an Egg to a customer who couldn't pick it up themselves. Could a Ranger please deliver it for us? I will be waiting outside the Pokémon Day Care.",
		"Notes: Fallarbor Town must be unlocked to finish this request.",
		"Rewards: Pokémon Egg",
		"Mission Difficulty: 1/5"
	  ]
	},
	
	22 => {
	  :title => "Find the Volcanic Ash",
	  :pages => [
		"Our client has asked us to go to Route 113 and find some Volcanic Ash for him.",
		"Why he can't do it himself, who knows? He wants a total of 5 Volcanic Ash. Happy hunting, Ranger!",
		"Rewards: 2x Sacred Ash, 3x Rash Mints",
		"Mission Difficulty: 1/5"
	  ]
	},
	
	23 => {
	  :title => "Terror in Ranger Cave!",
	  :pages => [
		"A very strong Pokémon appeared in the cave next to our guild. None of the Rangers who have faced it so far have been able to defeat it.",
		"We need someone strong to take it down for us!",
		"Rewards: 1x Rockium Z",
		"Mission Difficulty: 3/5",
		"Recommended Level: 35-40"
	  ]
	},
	
	24 => {
	  :title => "Perfect Picture",
	  :pages => [
		"I am trying to envision some new background images for the Pokémon Storage System.",
		"I don't have any Pokémon, so I would like someone to accompany me to a few places where I can take pictures for inspiration.",
		"If you're interested, I will arrive shortly. -Lanette",
		"Rewards: 2x Dive Balls, 2x Super Potions",
		"Mission Difficulty: 3/5"
	  ]
	},
	
	25 => {
	  :title => "Ash Patch Mayhem",
	  :pages => [
		"The ash patches outside Route 114 have been overrun by wild Pokémon. The task is to clear out the Pokémon feeding on the patches.",
		"Rewards: 1x Sitrus Berry, 1x Eject Pack",
		"Mission Difficulty: 1/5"
	  ]
	},
	
	26 => {
	  :title => "Fiery Disorder",
	  :pages => [
		"I heard a strange drilling noise coming from Fiery Path. Could someone go check it out for me? Preferably a Pokémon Ranger!",
		"Rewards: 1x Rocky Helmet, 1x Power Belt",
		"Mission Difficulty: 2/5",
		"Recommended Level: 20-25"
	  ]
	},
	
	27 => {
	  :title => "Spiky Turn",
	  :pages => [
		"A Cacturne is causing trouble for the Trainers and other people in the desert on Route 111. We need a Ranger to take it down!",
		"Notes: 4 Gym Badges are required.",
		"Rewards: 1x Fearonite",
		"Mission Difficulty: 3.5/5",
		"Wild Pokémon levels adjust depending on your Gym Badge count."
	  ]
	},
	
	28 => {
	  :title => "Mirage Applin Catching Challenge",
	  :pages => [
		"I am Drayden, a Gym Leader from the Unova region. I am looking for an Applin, but I don't have time to search for one myself.",
		"I heard that one can be found in Mirage Tower in the Route 111 desert. Please find one for me, and I will trade you something special!",
		"Rewards: Axew",
		"Mission Difficulty: 4/5"
	  ]
	},
	
	29 => {
	  :title => "Cry of the Lost Fox",
	  :pages => [
		"My Zoroark's child got lost in the Sinister Swamp. It wandered off while jumping around on the nearby logs. I am too scared to go looking for it myself.",
		"Can someone enter the Sinister Swamp and bring Zorua back to me? I will be waiting at the swamp's entrance with further directions.",
		"Rewards: Hisuian Zorua",
		"Mission Difficulty: 2/5"
	  ]
	},
	
	30 => {
	  :title => "Rescue the Twins",
	  :pages => [
		"The younger twin siblings of one of our fellow Rangers have gone missing on Mt. Pyre. Can you meet the Ranger there and help him find his siblings?",
		"Rewards: 1x Dawn Stone",
		"Mission Difficulty: 2.5/5"
	  ]
	},
	
	31 => {
	  :title => "Sparks of a Dark Ghost-Type Pokémon",
	  :pages => [
		"I have a rare Pokémon that I need to test, but it must only be used against someone I can trust.",
		"A Pokémon Ranger once saved my life in Kalos, so I have decided to trust a strong Ranger today. Meet me at Route 120, and I will reveal it through battle!",
		"Rewards: ???",
		"Mission Difficulty: 4/5 if you have 6 Gym Badges or fewer",
		"Recommended Level: 50"
	  ]
	},
	
	32 => {
	  :title => "Moo Moo Trouble",
	  :pages => [
		"Our MooMoo Farm near Route 123 has run out of Moomoo Milk. Something or someone is invading our farm and stealing all of our Miltank.",
		"We need a Ranger to come to the farm and help us find out what's going on. It always happens at night. Please come quickly",
		"Rewards: ???",
		"Mission Difficulty: 4/5 if you have 6 Gym Badges or fewer",
		"Recommended Level: 50"
	  ]
	},
	
	33 => {
	  :title => "Feebas Show and Tell",
	  :pages => [
		"I heard that Feebas can appear on Route 119, but there is only a 1% chance of finding one.",
		"I want proof! Someone, please catch a Feebas and show it to me. As a lifelong fisherman, I want to see one up close.",
		"Rewards: 1x Fossilized Fish, 1x Cornerstone Mask",
		"Mission Difficulty: 5/5"
	  ]
	},
	
	34 => {
	  :title => "Garbage Pickup",
	  :pages => [
		"The residents of the Battle Frontier have thrown more garbage than I can account for. Can a Pokémon Ranger please help me pick some of it up?",
		"I will be waiting in front of the Battle Pike. Please hurry, or I may be fired...",
		"Rewards: 1x Leftovers",
		"Mission Difficulty: 2/5"
	  ]
	},
	
	35 => {
	  :title => "Pyramid Escapade",
	  :pages => [
		"I am looking for someone strong to face. I want the strongest Ranger you can send. Although the Battle Pyramid is not fully operational yet, I need someone to test my abilities against.",
		"Will you come? We shall see. -Brandon",
		"Rewards: ???",
		"Mission Difficulty: 5/5"
	  ]
	},
	
	36 => {
	  :title => "Daycare",
	  :pages => [
		"One of the Pokémon that was left in our care ran away! I chased after it, but it jumped over the ledge and entered Artisan Cave.",
		"I'm not strong enough to go inside alone. Could a strong Ranger go inside and find it for me?",
		"Rewards: 1x Lucky Punch, 1x Lucky Egg",
		"Mission Difficulty: 3.5/5"
	  ]
	},
	
	37 => {
	  :title => "Gym Questions",
	  :pages => [
		"I am trying to come up with some new questions for my Gym back in Kanto. Can you come find me in one of the Battle Frontier houses?",
		"I want to test someone and see whether my new set of questions is worthy of being used in my Gym back in Kanto. -Blaine",
		"Rewards: 1x Arcanium Z",
		"Mission Difficulty: 1.5/5"
	  ]
	},
	
	38 => {
	  :title => "Mega Confrontation",
	  :pages => [
		"I am looking for a Mega Evolution Master to take on this quest. I need you to travel around the Hoenn region and record your battles against other Mega Evolution Trainers.",
		"This task is important for my research. You can find me waiting inside the Battle Factory...",
		"Rewards: ???",
		"Mission Difficulty: 5/5"
	  ]
	},
    # To add more books, use this format:
    # 4 => {
    #   :title => "Your Book Title",
    #   :pages => [
    #     "Page 1 content here",
    #     "Page 2 content here",
    #     "Page 3 content here"
    #   ]
    # }
  }
end

#===============================================================================
# SYSTEM CORE
#===============================================================================

# PBook Class: Represents a single book object
# This class stores book data (ID, title, and pages) for use by the BookOverlay
class PBook
  attr_accessor :id, :name, :pages
  
  # Initialize a new book object
  # Parameters:
  #   id: Unique identifier for the book
  #   name: Title of the book (displayed at the top)
  #   pages: Array of strings, each string is one page of text
  def initialize(id, name, pages)
    @id = id
    @name = name
    @pages = pages
  end
  
  # Returns the total number of pages in this book
  def page_count
    @pages.length
  end
end

# Opens a book and displays it to the player
# This is the main function you call from event commands
# Parameters:
#   book_id: The ID of the book to display (must exist in BookConfig::BOOKS)
#   label_name: (Optional) Name of an event label to jump to after closing the book
#              This allows you to continue an event at a specific point
# 
# USAGE EXAMPLES:
#   pbCallBook(1)                    # Open book with ID 1
#   pbCallBook(2, "continue_here")   # Open book with ID 2, jump to label "continue_here" when closed
def pbCallBook(book_id, label_name = nil)
  # Retrieve book data from the configuration
  book_data = BookConfig::BOOKS[book_id]
  if !book_data
    p "Error: Book with ID #{book_id} not found in BookConfig!"
    return
  end
  # Create a book object from the configuration data
  book = PBook.new(book_id, book_data[:title], book_data[:pages])
  # Create the visual overlay and display the book to the player
  BookOverlay.new(book, label_name)
end

# Jumps to a specific event label
# This function is automatically called by the BookOverlay when the book is closed
# if a label_name was provided to pbCallBook()
# 
# How label jumping works:
#   1. Player opens a book with: pbCallBook(1, "my_label")
#   2. Player closes the book
#   3. BookOverlay automatically calls pbCallLabel("my_label")
#   4. This function finds the label in the event and jumps to it
#   5. Event execution continues from that label
#
# In the event editor, create a label with the label command.
# The label name must match exactly (case-sensitive).
#
# Parameters:
#   label_name: The name of the label to jump to
def pbCallLabel(label_name)
  return if !label_name
  # Get the current event interpreter
  interp = pbMapInterpreter rescue nil
  return if !interp
  # Search through all event commands to find the label
  interp.instance_eval do
    return if !@list
    @list.size.times do |i|
      # Code 118 is the label command in RPG Maker XP
      # parameters[0] contains the label name
      if @list[i].code == 118 && @list[i].parameters[0] == label_name
        # Jump to this line index
        @index = i
        return
      end
    end
    p "Error: Label '#{label_name}' was not found in this event!"
  end
end

class BookOverlay
  # Initialize and display the book overlay
  # This creates the visual book interface and handles all user input
  # Parameters:
  #   book: The PBook object to display
  #   label_name: (Optional) Label to jump to when the book is closed
  def initialize(book, label_name = nil)
    @book = book
    @current_page = 1  # Start on page 1
    @label_name = label_name
    
    # Create a viewport for drawing the book UI (z = 99999 puts it on top)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    
    # Create a dark background veil (semi-transparent black overlay)
    @bg_veil = Sprite.new(@viewport)
    @bg_veil.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @bg_veil.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0, 190))
    @bg_veil.opacity = 0
    
    # Calculate book UI dimensions and position (centered on screen)
    @ui_width = Graphics.width - 40
    @ui_height = Graphics.height - 60
    @ui_x = (Graphics.width - @ui_width) / 2
    @ui_y = (Graphics.height - @ui_height) / 2
    
    # Create the book background/border
    @base_sprite = Sprite.new(@viewport)
    @base_sprite.bitmap = Bitmap.new(@ui_width + 8, @ui_height + 8)
    @base_sprite.x = @ui_x
    @base_sprite.y = @ui_y + 40
    @base_sprite.opacity = 0
    
    # Create the text/content layer
    @text_sprite = Sprite.new(@viewport)
    @text_sprite.bitmap = Bitmap.new(@ui_width, @ui_height)
    @text_sprite.x = @ui_x
    @text_sprite.y = @ui_y + 40
    @text_sprite.opacity = 0
    
    # Set the font for text rendering
    pbSetSystemFont(@text_sprite.bitmap) rescue nil
    
    # Draw and display the book
    draw_base
    draw_content
    animate_in
    main_loop
  end
  
  # Draw the book background with borders and decorative elements
  def draw_base
    bmp = @base_sprite.bitmap
    bmp.clear
    # Draw drop shadow effect
    bmp.fill_rect(6, 6, @ui_width, @ui_height, Color.new(0, 0, 0, 90))
    # Draw dark outer border (wood-like color)
    bmp.fill_rect(0, 0, @ui_width, @ui_height, Color.new(45, 30, 15))
    # Draw lighter border
    bmp.fill_rect(2, 2, @ui_width - 4, @ui_height - 4, Color.new(215, 185, 130))
    # Draw main book page background (cream color)
    bmp.fill_rect(4, 4, @ui_width - 8, @ui_height - 8, Color.new(252, 245, 235))
    # Draw title bar background
    bmp.fill_rect(4, 4, @ui_width - 8, 48, Color.new(150, 110, 70))
    # Draw separator line below title
    bmp.fill_rect(4, 52, @ui_width - 8, 3, Color.new(80, 50, 25))
    # Draw separator line above footer
    bmp.fill_rect(4, @ui_height - 48, @ui_width - 8, 2, Color.new(215, 185, 130))
  end
  
  # Draw all book content (title, page text, and footer)
  def draw_content
    bmp = @text_sprite.bitmap
    bmp.clear
    # Draw the book title with shadow effect
    draw_text_with_shadow(bmp, 0, 10, @ui_width, 36, @book.name, Color.new(255, 255, 255), Color.new(70, 45, 25), 1)
    # Get the current page text
    text = @book.pages[@current_page - 1]
    # Draw the page text with word wrapping
    draw_page_text(bmp, text)
    # Draw page navigation footer
    draw_footer(bmp)
  end
  
  # Draw page text with automatic word wrapping
  # Draw page text with automatic word wrapping
  def draw_page_text(bmp, text)
    # Set margins for text
    margin_x = 32
    text_w = @ui_width - (margin_x * 2)
    
    # Split text into words and wrap them
    words = text.split(" ")
    lines = []
    current_line = ""
    words.each do |word|
      test_line = current_line.empty? ? word : current_line + " " + word
      # If the line is too wide, start a new line
      if bmp.text_size(test_line).width > text_w
        lines << current_line
        current_line = word
      else
        current_line = test_line
      end
    end
    lines << current_line unless current_line.empty?
    
    # Calculate vertical centering for the text block
    line_height = 32
    total_height = lines.size * line_height
    available_height = @ui_height - 55 - 48
    start_y = 55 + ((available_height - total_height) / 2)
    
    # Set text colors (text and shadow)
    col_text = Color.new(45, 35, 25)    # Dark brown text
    col_shadow = Color.new(235, 225, 215)  # Light shadow
    
    # Draw each line of text
    lines.each_with_index do |line, index|
      y = start_y + (index * line_height)
      draw_text_with_shadow(bmp, margin_x, y, text_w, line_height, line, col_text, col_shadow, 1)
    end
  end
  
  # Draw the footer section with page number and navigation arrows
  def draw_footer(bmp)
    footer_y = @ui_height - 40
    page_str = "Page #{@current_page} / #{@book.page_count}"
    
    # Draw page counter in the center
    draw_text_with_shadow(bmp, 0, footer_y, @ui_width, 32, page_str, Color.new(130, 100, 70), Color.new(255, 255, 255), 1)
    
    # Draw left arrow (◀) if not on the first page
    if @current_page > 1
      draw_text_with_shadow(bmp, 30, footer_y, 100, 32, "◀", Color.new(200, 70, 50), Color.new(255, 255, 255), 0)
    end
    
    # Draw right arrow (▶) if not on the last page
    if @current_page < @book.page_count
      draw_text_with_shadow(bmp, @ui_width - 130, footer_y, 100, 32, "▶", Color.new(200, 70, 50), Color.new(255, 255, 255), 2)
    end
  end
  
  # Draw text with shadow effect for better readability
  # Parameters:
  #   bmp: Bitmap to draw on
  #   x, y, w, h: Position and dimensions
  #   text: The text to draw
  #   color: Main text color
  #   shadow_color: Shadow color
  #   align: Text alignment (0 = left, 1 = center, 2 = right)
  def draw_text_with_shadow(bmp, x, y, w, h, text, color, shadow_color, align)
    # Draw shadow (offset by 1-2 pixels)
    bmp.font.color = shadow_color
    bmp.draw_text(x + 1, y + 1, w, h, text, align)
    bmp.draw_text(x + 2, y + 2, w, h, text, align)
    # Draw main text on top
    bmp.font.color = color
    bmp.draw_text(x, y, w, h, text, align)
  end
  
  # Animate page transition with sliding effect
  # Direction: positive for sliding left, negative for sliding right
  def transition_page(direction)
    # Fade out current page while sliding it
    10.times do
      @text_sprite.opacity -= 26
      @text_sprite.x += direction * 3
      Graphics.update
    end
    # Draw the new page
    draw_content
    # Position new page off-screen and fade it in while sliding
    @text_sprite.x = @ui_x - (direction * 30)
    10.times do
      @text_sprite.opacity += 26
      @text_sprite.x += direction * 3
      Graphics.update
    end
    # Reset to final position
    @text_sprite.x = @ui_x
    @text_sprite.opacity = 255
  end
  
  # Animate book opening with fade-in effect
  def animate_in
    15.times do
      @bg_veil.opacity += 13
      @base_sprite.opacity += 17
      @text_sprite.opacity += 17
      @base_sprite.y -= 2.66
      @text_sprite.y -= 2.66
      Graphics.update
    end
    # Ensure final position is exact
    @base_sprite.y = @ui_y
    @text_sprite.y = @ui_y
  end
  
  # Animate book closing with fade-out effect
  def animate_out
    15.times do
      @bg_veil.opacity -= 13
      @base_sprite.opacity -= 17
      @text_sprite.opacity -= 17
      @base_sprite.y += 2.66
      @text_sprite.y += 2.66
      Graphics.update
    end
  end
  
  # Main input handling loop
  # Handles page navigation and closing the book
  def main_loop
    loop do
      Graphics.update
      Input.update
      
      # Handle left page button (A key or L button)
      if Input.trigger?(Input::LEFT) || Input.trigger?(Input::L)
        if @current_page > 1
          pbPlayCursorSE rescue nil
          @current_page -= 1
          transition_page(1)  # Slide page from right to left
        end
      
      # Handle right page button (D key or R button)
      elsif Input.trigger?(Input::RIGHT) || Input.trigger?(Input::R)
        if @current_page < @book.page_count
          pbPlayCursorSE rescue nil
          @current_page += 1
          transition_page(-1)  # Slide page from left to right
        end
      
      # Handle cancel button (B key) to close the book
      elsif Input.trigger?(Input::B)
        pbPlayCancelSE rescue nil
        break
      end
    end
    
    # Close the book with animation
    animate_out
    dispose
    
    # Jump to label if one was specified
    pbCallLabel(@label_name) if @label_name
  end
  
  # Clean up all sprites and viewports
  def dispose
    @bg_veil.bitmap.dispose
    @bg_veil.dispose
    @base_sprite.bitmap.dispose
    @base_sprite.dispose
    @text_sprite.bitmap.dispose
    @text_sprite.dispose
    @viewport.dispose
  end
end