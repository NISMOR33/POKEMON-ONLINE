module PWTSettings
# Information pertining to the start position on the PWT stage
# Format is as following: [map_id, map_x, map_y]
PWT_MAP_DATA = [625,4,14]
# ID for the event used to move the player and opponents on the map
PWT_MOVE_EVENT = 24
# ID of the opponent event
PWT_OPP_EVENT = 6
# ID of the scoreboard event
PWT_SCORE_BOARD_EVENT = 22
# ID of the lobby trainer event
PWT_LOBBY_EVENT = 9
# ID of the event used to display an optional even if the player wins the PWT
PWT_FANFARE_EVENT = 23
# If marked as true, it will apply a multiplier based on the player's current win streak. Defeault to false.
PWT_STREAK_MULT = false
# If marked as true, it will use DeltaTime, otherwise, it will use the old frame system
PWT_USE_DELTA_TIME = false
# Target framerate. By default it's usually 60 fps with MKXP-Z.
PWT_DEFAULT_FRAMERATE = 60
end

module GameData
  class PWTTournament
    attr_reader :id
    attr_reader :real_name
    attr_reader :trainers
    attr_reader :condition_proc
	  attr_reader :points_won

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id             = hash[:id]
      @real_name      = hash[:name]          || "Unnamed"
      @trainers       = hash[:trainers]
      @condition_proc = hash[:condition_proc]
      @rules_proc     = hash[:rules_proc]
      @banned_proc    = hash[:banned_proc]
	  @points_won     = hash[:points_won]    || 3
    end

    # @return [String] the translated name of this nature
    def name
      return _INTL(@real_name)
    end
    
    def call_condition(*args)
      return (@condition_proc) ? @condition_proc.call(*args) : true
    end
    def call_rules(*args)
      return (@rules_proc) ? @rules_proc.call(*args) : PokemonChallengeRules.new
    end
    def call_ban_reason(*args)
      return (@banned_proc) ? @banned_proc.call(*args) : nil
    end
  end
end

##################################################################
# The format for defining individual Tournaments is as follows.
##################################################################
=begin
GameData::PWTTournament.register({
  :id => :Tutorial_Tournament,			# Internal name of the Tournament to be called
  :name => _INTL("Kanto Leaders"),		# Display name of the Tournament in the choice selection box
  :trainers => [						# Array that contains all of the posssible trainers in a Tournament. Must have at least 8.
                [:ID,"Trainer Name","Player Victory Dialogue.","Player Lose Dialogue.",Variant Number,"Lobby Dialogue.","Pre-Battle Dialogue.","Post-Battle Dialogue"], # Trainer 1
				[:ID,"Trainer Name","Player Victory Dialogue.","Player Lose Dialogue.",Variant Number,"Lobby Dialogue.","Pre-Battle Dialogue.","Post-Battle Dialogue"]  # Trainer 2, etc
			   ],
										# Trainers follow this exact format. 
										# ID and Trainer Name are mandatory.
										# Victory dialogue will default to "..." if not filled.
										# Lose dialogue will default to "..." is not filled in either here or trainers.txt. If Lose dialogue is filled here, it overrides the defined line from trainers.txt
										# Variant Number will default to 0 if not filled.
										# If there is no Lobby Dialogue they will not appear in the Lobby map
										# Pre- and Post-battle Dialogue is optional and will display nothing if not filled.
  :condition_proc => proc { 			# The conditions under which this Tournament shows up in the choice selection box. Optional.
	next $PokemonGlobal.hallOfFameLastNumber > 0 
  },					
  :rules_proc => proc {|length|			# This defines the rules for the rules for an individual tournament. More rules can be found in the Challenge Rules script sections
	rules = PokemonChallengeRules.new
    rules.addPokemonRule(BannedSpeciesRestriction.new(:MEWTWO,:MEW,:HOOH,:LUGIA,:CELEBI,:KYOGRE,:GROUDON,:RAYQUAZA,
                                                      :DEOXYS,:JIRACHI,:DIALGA,:PALKIA,:GIRATINA,:REGIGIGAS,:HEATRAN,:DARKRAI,
                                                      :SHAYMIN,:ARCEUS,:ZEKROM,:RESHIRAM,:KYUREM,:LANDORUS,:MELOETTA,
                                                      :KELDEO,:GENESECT))
    rules.addPokemonRule(NonEggRestriction.new)
    rules.addPokemonRule(AblePokemonRestriction.new)
    rules.setNumber(length)
    rules.setLevelAdjustment(FixedLevelAdjustment.new(50))
	next rules
  },
  :banned_proc => proc {				# Displays a message when a team is ineligable to be used in a tournament.
	pbMessage(_INTL("Certain exotic species, as well as eggs, are ineligible.\\1"))
  },
  :points_won => 2						# A configurable amount of Battle Points won after a tournament.
})
=end
##################################################################

GameData::PWTTournament.register({
  :id => :Kanto_Leaders,
  :name => _INTL("Kanto Leaders"),
  :trainers => [
  				[:LEADER_Brock,"Brock","our Pokémon's powerful attacks overcame my rock-hard resistance... You're stronger than I expected...","The best offense is a good defense! That's my way of doing things!",1,"MAwesome... That was a really great battle. I compliment you on your victory!","I'm Brock! I'm an expert of Rock-type Pokémon. My Pokémon are impervious to most physical attacks. You'll have a hard time inflicting any damage.","I really enjoyed the battle with you. Still, the world is huge! I can't believe you got past my rock-hard defense."],
  				[:LEADER_Misty,"Misty","You really are strong... I'll admit that you are skilled...","See! This is the Water-type toughness I was talking about!",1,"My pride and joy are my Water-type Pokémon. But they were no match for yours. Thank you for teaching me the world is a really big place.","I'm Misty! I'm a user of Water-type Pokémon, and my Water-type Pokémon are tough!","Know what? My dream was to go on a journey and battle powerful Trainers... I made my dream come true, and now... my next dream is to defeat you!"],
 				[:LEADER_Surge,"Surge","Arrrgh! You are strong!","Oh yeah! I'm strong!",1,"You are very strong! You're the victor! I'm not gonna lose! I'll train hard and be number one in Pokémon battling!","The name's Lt. Surge! When it comes to Electric-type Pokémon, I'm number one! You've got guts to challenge me! I'm gonna zap you!","Even my electric tricks lost. You're excellent! Keep goin' like lightning!"],
 				[:LEADER_Erika,"Erika","Oh my! Looks like I underestimated you...","I was afraid I would doze off...",1,"Oh! I admire your technique. It would make me very happy if I could battle with you again.","My name is Erika, and I love Grass-type Pokémon. I have been training myself on not only flower arrangement but also Pokémon battle. I shall not lose.","I feel inspired by your win. Fighting alongside your beloved Pokémon and winning. This is the joy of being a Pokémon Trainer."],
				[:LEADER_Sabrina,"Sabrina","Was the future I saw...wrong?","Just as I foresaw...",1,"Your victory... It's exactly as I foresaw actually. But I wanted to turn that future on its head with my conviction as a Trainer!","Three years ago I had a vision of battling you. Since you wish it, I will show you my psychic powers!","This victory... It's exactly as I foresaw three years ago!"],
 				[:LEADER_Janine,"Janine","You've got a great battle technique!","I'm Janine! Remember this name!",1,"While I admire your victory, I'm disappointed that I lost... I'm still not a full-fledged Trainer yet. I'll train with my father to be better than before and challenge you again!","I'm Janine! The essence of ninjas' moves obtained by training! Feel the horror from the Poison type Pokémon who've mastered it.","I'm going to really apply myself and improve my skills. I want to become much better than both my father and you!"],
 				[:LEADER_Blaine,"Blaine","How could this be?! My spirit has not been defeated!","Whoa hey! I'm a raging inferno!",1,"Whoa hey! This time I'm sure of the victor's strength! Next time, I'll be even more of a raging inferno!","Whoa hey! My fiery Pokémon will incinerate all challengers! Are you ready? Here we go! Whoa hey!","Awesome. I have burned out... But the fire inside me is only going to get stronger! Let's battle again sometime!"],
 				[:LEADER_Giovanni,"Giovanni","What? Me, lose?!","Haarg! I lose?! There is nothing I wish to say to you!",1,"I'll tell you this now... No matter how strong you are, someday you'll lose. That Red will feel it too someday...","For your insolence, you will feel a world of pain!","Haarg! I lose?! There is nothing I wish to say to you!"]
               ],
  :rules_proc => proc {|length|
    rules = PokemonChallengeRules.new
    rules.addPokemonRule(BannedSpeciesRestriction.new(:MEWTWO,:MEW,:HOOH,:LUGIA,:CELEBI,:KYOGRE,:GROUDON,:RAYQUAZA,
                                                      :DEOXYS,:JIRACHI,:DIALGA,:PALKIA,:GIRATINA,:REGIGIGAS,:HEATRAN,:DARKRAI,
                                                      :SHAYMIN,:ARCEUS,:ZEKROM,:RESHIRAM,:KYUREM,:LANDORUS,:MELOETTA,
                                                      :KELDEO,:GENESECT))
    rules.addPokemonRule(NonEggRestriction.new)
    rules.addPokemonRule(AblePokemonRestriction.new)
    rules.setNumber(length)
    rules.setLevelAdjustment(FixedLevelAdjustment.new(50))
    next rules
  },
  :banned_proc => proc {
    pbMessage(_INTL("Certain exotic species, as well as eggs, are ineligible.\\1"))
  },
  :points_won => 2
})

GameData::PWTTournament.register({
  :id => :Johto_Leaders,
  :name => _INTL("Johto Leaders"),
  :trainers => [
    			[:LEADER_Falkner,"Falkner","I understand... I'll bow out gracefully.","Now you know the real power of bird Pokémon!",1,"As long as I have lofty ambitions, I can fly as far as I want. I'll keep flying and aiming high! Just like you!","I'll show you the real power of the magnificent bird Pokémon! Dad! I hope you're watching me battle from above!","A defeat is a defeat. You are strong indeed. I'm going to train harder with my Pokémon to become the greatest Bird Keeper of all!"],
				[:LEADER_Bugsy,"Bugsy","Aw, that's the end of it...","I guess I'm done reporting my research findings!",1,"I never lose when it comes to Bug-type Pokémon. I'm so embarrassed to have said that. I'll start my studies of other Pokémon over from the beginning, too. I'm truly grateful that you made me realize I need to do that.","I never lose when it comes to Bug-type Pokémon. Let me demonstrate what I've learned from my studies.","Thanks! Thanks to our battle, I was also able to make progress in my research!"],
				[:LEADER_Whitney,"Whitney","Ugh...","See? Didn't I tell ya? My Pokémon are really strong!",1,"I was surprised by how strong you were! I can see why you won the tournament. When you have a chance, tell me all about why you're so strong!","I'm warning you I'm good! Also, my Pokémon aren't just cute they're really strong! Well let's get to it!","Waaaaah! Waaaaah! ...Snivel, hic. ...You meanie! ... ... Ah, that was a good cry! I'm going to get even stronger and challenge this again!"],
   				[:LEADER_Morty,"Morty","How is this possible...","I moved...one step ahead again.",1,"I'm desperate to know the secret of your strength. If I unlock the secret, my dream to see the legendary Pokémon may come true! Excuse me. I got ahead of myself. Congratulations on your victory.","My training is to meet a rainbow-hued Pokémon. You're going to help me reach the next level in my training!","I saw something again... If I fight with you next time, I will be able to see something new again... I look forward to it."],
   				[:LEADER_Chuck,"Chuck","No... Not...yet...","See? My Pokémon were as strong as I said!",1,"Hmmm! I enjoyed battling you. The Trainer who wins the tournament has got something special!","I have to warn you that I am a strong Trainer! I spend a lot of time training under a pounding waterfall every day. What? It has nothing to do with Pokémon? ... That's true! ... Come on. We shall do battle!","Wahahah! I enjoyed battling you! But a loss is a loss! From now on, I'm going to train 24 hours a day!"],
    			[:LEADER_Jasmine,"Jasmine","Well done...","I'm glad... I won...",1,"The blend of your kindness and your Pokémon's strength brought this victory to you. Um... Keep on doing your best... with your Pokémon.","I am Jasmine. I use the... Clang! Steel type! ...Do you know about the Steel type? They are very cold, hard, sharp, and really strong! Um... I'm not lying.","..You are a better Trainer than me, in both skill and kindness. Um... I don't know how to say this, but good luck..."],
   				[:LEADER_Pryce,"Pryce","Hmm. Seems as if my luck has run out.","This is winter's harshness.",1,"If it's someone like you, I'm sure you'll keep winning and will find something important. Keep it up.","I have been training Pokémon since before you were born. I do not lose easily. I, Pryce the Winter Trainer shall demonstrate my power!","I am impressed by your prowess. With your strong will, I know you will overcome all life's obstacles."],
   				[:LEADER_Clair,"Clair","It's over...","Come on! You've got to get tougher than this!",1,"Oh! I admire your technique. It would make me very happy if I could battle with you again.","I am Clair. The world's best Dragon-type master. I can hold my own even against the Pokémon League's Elite Four.","What?! Come to brag about your victory? Fine. I'll say it to you. Congratulations! You were really tough! There! Are you happy now?"]
               ],
  :rules_proc => proc {|length|
    rules = PokemonChallengeRules.new
    rules.addPokemonRule(BannedSpeciesRestriction.new(:MEWTWO,:MEW,:HOOH,:LUGIA,:CELEBI,:KYOGRE,:GROUDON,:RAYQUAZA,
                                                      :DEOXYS,:JIRACHI,:DIALGA,:PALKIA,:GIRATINA,:REGIGIGAS,:HEATRAN,:DARKRAI,
                                                      :SHAYMIN,:ARCEUS,:ZEKROM,:RESHIRAM,:KYUREM,:LANDORUS,:MELOETTA,
                                                      :KELDEO,:GENESECT))
    rules.addPokemonRule(NonEggRestriction.new)
    rules.addPokemonRule(AblePokemonRestriction.new)
    rules.setNumber(length)
    rules.setLevelAdjustment(FixedLevelAdjustment.new(50))
    next rules
  },
  :banned_proc => proc {
    pbMessage(_INTL("Certain exotic species, as well as eggs, are ineligible.\\1"))
  },
  :points_won => 2
})

GameData::PWTTournament.register({
  :id => :Hoeen_Leaders,
  :name => _INTL("Hoenn Leaders"),
  :trainers => [
                [:LEADER_Roxanne,"Roxanne","So… I lost…","My barrier was tough to break. Maybe next time.",1,"You were pretty tough! I can't wait to face off against you again!","I apply what I learned at the Pokémon Trainer's School in battle. Would you kindly demonstrate how you battle and with which Pokémon?","It seems that I still have much more to learn… I will participate in the tournament again. Will you be my opponent then as well?"],
                [:LEADER_Brawly,"Brawly","Whoa, wow! You made a much bigger splash than I expected!","My barrier was tough to break. Maybe next time.",1,"You were pretty tough! I can't wait to face off against you again!","I've been churned in the rough waves, and I've grown tough in a pitch-black cave! So you wanted to challenge me? Let me see what you're made of!","Someday your talent will become a big wave, creating a storm of surprise among Pokémon Trainers!"],
                [:LEADER_Wattson,"Wattson","Wahahahah! Fine, I lost! You ended up giving me a thrill!","My barrier was tough to break. Maybe next time.",1,"You were pretty tough! I can't wait to face off against you again!","Wahahahaha! Good things come to those who laugh! I'm going to have a fun Pokémon battle and laugh even more!","Well now. Think I'll go gab with that Trainer, Volkner, about remodeling Pokémon Gyms!"],
                [:LEADER_Flannery,"Flannery","Oh... I guess I was trying too hard...","My barrier was tough to break. Maybe next time.",1,"You were pretty tough! I can't wait to face off against you again!","The way to get the most out of the strength you and your Pokémon have acquired is to not push too hard and just be yourself! So, I'll show you how to do that right now, OK?","Your strength sure reminds me of someone... You must have battled with many different people and learned good things from them every time, huh?"],
                [:LEADER_Norman,"Norman","You did it! You truly have surpassed me!","My barrier was tough to break. Maybe next time.",1,"You were pretty tough! I can't wait to face off against you again!","Show me \PN on the world championship stage what your made of! I won't be holding back like before...","I'm proud to say that you have surpassed me! Go on and make sure you become the strongest in the world!"],
                [:LEADER_Winona,"Winona","A Trainer that commands Pokémon with more grace than I...","My barrier was tough to break. Maybe next time.",1,"You were pretty tough! I can't wait to face off against you again!","I have become one with bird Pokémon and have soared the skies... However grueling the battle, we have triumphed with grace... Witness the elegant choreography of my Pokémon and I!","Though I fell to you, I will remain devoted to bird Pokémon."],
                [:LEADER_Tate,"Tate","Oh! The combination of me and my Pokémon...","My barrier was tough to break. Maybe next time.",1,"You were pretty tough! I can't wait to face off against you again!","Thanks to my strict training, I can make myself one with Pokémon! Can you beat this combination and the bond between me and my Pokémon?","If I was with my sibling we would have been much tougher... but I guess you already did defeat us before."],
                [:LEADER_Juan,"Juan","Ahahaha, excellent! Very well, you are the winner.","My barrier was tough to break. Maybe next time.",1,"You were pretty tough! I can't wait to face off against you again!","Let's win while showing the elegance of Pokémon's moves. Please, you shall bear witness to our artistry. A grand illusion of water sculpted by Pokémon and myself!","From you, I sense the brilliant shine of skill that will overcome all! However, you are somewhat lacking in elegance. Perhaps I should make you a loan of my outfit? ... Hahaha, I merely jest!"],
               ],
  :rules_proc => proc {|length|
    rules = PokemonChallengeRules.new
    rules.addPokemonRule(BannedSpeciesRestriction.new(:MEWTWO,:MEW,:HOOH,:LUGIA,:CELEBI,:KYOGRE,:GROUDON,:RAYQUAZA,
                                                      :DEOXYS,:JIRACHI,:DIALGA,:PALKIA,:GIRATINA,:REGIGIGAS,:HEATRAN,:DARKRAI,
                                                      :SHAYMIN,:ARCEUS,:ZEKROM,:RESHIRAM,:KYUREM,:LANDORUS,:MELOETTA,
                                                      :KELDEO,:GENESECT))
    rules.addPokemonRule(NonEggRestriction.new)
    rules.addPokemonRule(AblePokemonRestriction.new)
    rules.setNumber(length)
    rules.setLevelAdjustment(FixedLevelAdjustment.new(50))
    next rules
  },
  :banned_proc => proc {
    pbMessage(_INTL("Certain exotic species, as well as eggs, are ineligible.\\1"))
  },
  :points_won => 2
})

GameData::PWTTournament.register({
  :id => :Sinnoh_Leaders,
  :name => _INTL("Sinnoh Leaders"),
  :trainers => [
     			[:LEADER_Roark,"Roark","Wh-what? That can't be! My buffed-up Pokémon!","See? I'm proud of my rocking battle style!",1,"With skill like yours, it's natural for you to win. Still, wasn't it hard to train Pokémon that much? By the way, I wonder if there are any Fossils in Nacrene City's museum?","Every day, I toughened myself up by digging up Fossils nonstop. Could I show you how tough I am in a battle?","We lost control there. Next time, I'd like to challenge you to Fossil-digging race underground in the Sinnoh region."],
	   			[:LEADER_Gardenia,"Gardenia","Aww, really? My Grass-type Pokémon are growing good and strong, too...","Yes! My Pokémon and I are perfectly good!",1,"Wow, you really are strong! Just how did you raise your Pokémon to be that tough? Amazing! Hey! How do you feel? I want to win and brag about my Pokémon, too!","I'm Gardenia. I love Grass-type Pokémon! I can't deny that Grass-type Pokémon have many weak points. But I'll show you that's not the only factor in deciding who wins!","Wherever I go, I still try to be as tough as I can."],			
     			[:LEADER_Fantina,"Fantina","You are so fantastically strong. I know why I have lost.","You are strong. But it's me who won.",1,"I'm so very happy! Because you're so very strong! There's so much I can learn from you. I can become even stronger. When I do, let's battle again!","I learned a lot of things in the Sinnoh region. Also, I study Pokémon very much. I have come to be Gym Leader. And, uh, so it shall be that you challenge me. But I shall win. That is what the Gym Leader of Hearthome does, non?","I am dumbfounded! So very, very strong! You, your Pokémon, so strong! Your power is admirable!"],			
     			[:LEADER_Maylene,"Maylene","I shall admit defeat... You are much too strong.","Thank you very much. I learned a lot from it.",1,"Looking at the way you battle, I learned something! You like your Pokémon! I think it's wonderful!","Please to meet you! I don't really know what it means to be strong. But I will do the best I can as a Trainer. I take battling very seriously. Whenever you're ready!","I can't explain what it means to be strong. I don't know how much effort goes into being strong... But being with Pokémon lets us keep making the effort, doesn't it?"],			
     			[:LEADER_Wake,"Wake","Hunwah! It's gone and ended! How will I say this... I want more! I wanted to battle a lot more!","I won, but I want more! I wanted to battle a lot more!",1,"I may have lost, but battling with you was fun! I hope your victory will put more smiles on people's faces!","My Pokémon were toughened up by stormy white waters! They'll take everything you can throw at them and then pull you under! Victory will be ours! Come on, let's get it done!","The styles of battling and winning are as widely varied as Trainers are. Do you want to know how I battle? I battle so I can say I had fun at the end, whether I win or lose!"],			
     			[:LEADER_Byron,"Byron","Hmm! My sturdy Pokémon defeated!","Gwahahaha! How were my sturdy Pokémon?!",1,"Guhahahaha! I lost, but I saw something great. Well, guess I'll go back to Sinnoh and start my son's training over! All right! Next time I take part in the tournament, I'll play to win!","Trainer! You're young, just like my son, Roark. With more young Trainers taking charge, the future of Pokémon is bright! So, as a wall for young people, I'll take your challenge!","Gwahahaha! You were strong enough to take down my prized team of Pokémon. I recognize your power. Please show your power to other Trainers, too!"],			
     			[:LEADER_Candice,"Candice","You're mighty! You're worthy of lots of respect.","I sensed your will to win, but I don't lose!",1,"You won because your focus was far greater than the others! Yes! I have to focus even more as well!","You're the opponent of Candice? Sure thing! I was waiting for someone tough! But I should tell you, I'm tough, because I know how to focus. Pokémon, fashion, romance... It's all about focus! I'll show you just what I mean. Get ready to lose!","Wow! You're great! You've earned my respect! I think your focus and will bowled us over totally. But next time I'll focus even more and won't lose!"],			
     			[:LEADER_Volkner,"Volkner","You've got me beat... Your desire and the noble way your Pokémon battled for you... I even felt thrilled during our match. That was a very good battle.","It was not shocking at all... That is not what I wanted!",1,"I like how your Pokémon respond to your earnest enthusiasm. I'm glad someone who knows how to enjoy Pokémon battles won the tournament.","Since you've come this far, you must be quite strong... I hope you're the Trainer who'll make me remember how fun it is to battle!","Hehehe. Hahahah! ...That was the most fun I've had in a battle since...I don't know when! It's also made me excited to know you and your team will keep battling to greater heights!"]
               ],
  :rules_proc => proc {|length|
    rules = PokemonChallengeRules.new
    rules.addPokemonRule(BannedSpeciesRestriction.new(:MEWTWO,:MEW,:HOOH,:LUGIA,:CELEBI,:KYOGRE,:GROUDON,:RAYQUAZA,
                                                      :DEOXYS,:JIRACHI,:DIALGA,:PALKIA,:GIRATINA,:REGIGIGAS,:HEATRAN,:DARKRAI,
                                                      :SHAYMIN,:ARCEUS,:ZEKROM,:RESHIRAM,:KYUREM,:LANDORUS,:MELOETTA,
                                                      :KELDEO,:GENESECT))
    rules.addPokemonRule(NonEggRestriction.new)
    rules.addPokemonRule(AblePokemonRestriction.new)
    rules.setNumber(length)
    rules.setLevelAdjustment(FixedLevelAdjustment.new(50))
    next rules
  },
  :banned_proc => proc {
    pbMessage(_INTL("Certain exotic species, as well as eggs, are ineligible.\\1"))
  },
  :points_won => 2
})

GameData::PWTTournament.register({
  :id => :Unova_Leaders,
  :name => _INTL("Unova Leaders"),
  :trainers => [
     			[:LEADER_Cheren,"Cheren","Thank you! I feel like I saw a little of the way toward my ideals.","Even when you lose, your Pokémon are still brimming with fighting spirit.",1,"I learned something from this battle... But only a little. What does it mean to be strong...? What are Pokémon...? There are so many things I don't know!","Even if hurt, my Pokémon will fight for me with just one command. I think I'll value and trust your Pokémon more if you keep that fact close to your heart. What can I do for these Pokémon? What should I do? That's right! I battle with everything to find the ideal relationship between Pokémon and people!","I'll keep battling many Trainers and Pokémon like this, and if I can learn what kind of person I am, it will open up my path. I'm sure this path will lead me to become the person I'm meant to be. Pokémon will always be with you and me as we go down our own paths. Our important friends, Pokémon..."],
     			[:LEADER_Lenora,"Lenora","You're impressive! And quite charming, aren't you?!","What's wrong? Could it be you misread what moves I was going to use?",1,"Battling is second nature to you, isn't it? It's always best to be natural, no matter when it is and what kind of situation you're in. Your victory is the result of that, right?","Welcome! I'm the director of the Nacrene Museum and former Leader of the Nacrene Gym, Lenora! Well then, challenger, I'm going to research how you battle with the Pokémon you've so lovingly raised!","Your fighting style is so enchanting. It is charming. I'm glad I met you!"],
     			[:LEADER_Burgh,"Burgh","Is it over? Has my muse abandoned me?","Wow... It's beautiful somehow, isn't it...",1,"Ummm... That's right. Bug-type Pokémon are cool, aren't they? Win or lose, they're always beautiful.","If the battle brings out the beauty in Bug-type Pokémon, it will be a scene that makes my heart flutter, win or lose. My bug Pokémon are abuzz with anticipation. Let's get straight to it!","Aww... I lost. Whatever! Losing to you doesn't bug me, because you are a-MAZ-ingly strong!"],			
     			[:LEADER_Elesa,"Elesa","I meant to make your head spin, but you shocked me instead.","That was unsatisfying somehow... Will you give it your all next time?",1,"My Pokémon work hard for me, so I want to do what I can for them. And I want them to bathe in the glamorous spotlight as well. In that sense, your Pokémon were gleaming very brightly!","I am me, and Pokémon are Pokémon! I feel that strongly when I battle with Pokémon moves, and that's why I do it. Now, my beloved Pokémon are going to make your head spin!","My, oh my... You have a sweet fighting style."],	
				[:LEADER_Clay,"Clay","Well, I've had enough... And just so you know, I didn't go easy on you.","It's simple, hear! I wanted to win more than ya did!",1,"Am I all right with a Trainer like ya winning the Tournament, ya say? Ya think there're stronger Trainers out there yet?","If ya want ta win, don't make excuses! Got it? If yer gonna bellyache, just forget 'bout fightin'! Well, I might be fussin' 'bout nothing when it comes to you.","Fer such a young 'un, ya have an imposin' battle style. I wonder what kind a journey ya had that made ya so strong. But, I still don't like losin'!"],
				[:LEADER_Skyla,"Skyla","Being your opponent in battle is a new source of strength to me. Thank you!","You're a pretty amazing Pokémon Trainer, aren't you? My Pokémon and I are happy, because for the first time in a while, we could fight with our full strength.",1,"I'm in top form, and I can see what my opponent is trying to do. And I still couldn't win! That's because Pokémon battling is really deep, and you're really great!","It's finally time for a showdown! That means the Pokémon battle that decides who's at the top, right? I love being on the summit! 'Cause you can see forever and ever from high places! So, how about you and I have some fun?","Being your opponent in battle is a new source of strength to me. Thank you!"],
				[:LEADER_Roxie,"Roxie","Wild! Your reason's already more toxic than mine!","Hey, c'mon! Get serious! You gotta put more out there!",1,"Congrats on taking first! Losing stinks, but still... You're a fun Pokémon Trainer to battle! I mean, c'mon!","You don't do anything! What do you know?! You don't do anything! How're you gonna change?! But, I've got you covered! I'm gonna give your reason a toxic shock and open up your mind!","You didn't win... I lost! I was weak and made my Pokémon feel how much losing stinks! Watch out! Next time we meet, I'm going to give you a toxic shock!"],				
				[:LEADER_Drayden,"Drayden","This intense feeling that floods me after a defeat... I don't know how to describe it.","Harrumph! I know your ability is greater than that!",1,"I may be old, but I desire victory! This desire is the energy for life! It's the power to surpass who I was the previous day! I complement you on your victory, but next time, victory will be mine!","What I want to find is a young Trainer who can show me a bright future. Let's battle with everything we have: your skill, my experience, and the love we've raised our Pokémon with!","Wonderful. I'm grateful we had a chance to meet and battle. Make a bright future not just for yourself, but for others as well."],		
				[:LEADER_Marlon,"Marlon","You're strong as a gnarly wave and as nice as a glassy sea.","You're tough, but it's not enough to sway the sea!",1,"Eh, right now, you're like a ragin' sea that washes everythin' away! Uihaa! What a great battle, yo!","Oh ho, so I'm facing you! That's off the wall. How 'bout you and I make some waves and sweep the audience away? Let's leave 'em with even bigger smiles!","You don't just look strong, you're strong for reals! Eh, I was swept away, too!"]
               ],
  :rules_proc => proc {|length|
    rules = PokemonChallengeRules.new
    rules.addPokemonRule(BannedSpeciesRestriction.new(:MEWTWO,:MEW,:HOOH,:LUGIA,:CELEBI,:KYOGRE,:GROUDON,:RAYQUAZA,
                                                      :DEOXYS,:JIRACHI,:DIALGA,:PALKIA,:GIRATINA,:REGIGIGAS,:HEATRAN,:DARKRAI,
                                                      :SHAYMIN,:ARCEUS,:ZEKROM,:RESHIRAM,:KYUREM,:LANDORUS,:MELOETTA,
                                                      :KELDEO,:GENESECT))
    rules.addPokemonRule(NonEggRestriction.new)
    rules.addPokemonRule(AblePokemonRestriction.new)
    rules.setNumber(length)
    rules.setLevelAdjustment(FixedLevelAdjustment.new(50))
    next rules
  },
  :banned_proc => proc {
    pbMessage(_INTL("Certain exotic species, as well as eggs, are ineligible.\\1"))
  },
  :points_won => 2
})

GameData::PWTTournament.register({
  :id => :Kalos_Leaders,
  :name => _INTL("Kalos Leaders"),
  :trainers => [
  				[:LEADER_Viola,"Viola","You were pretty tough! I can't wait to face off against you again!","You're tough, but it wasn't enough to sway the battle in your favor!",1,"That determined expression... That glint in your eye that says you're up to the challenge... It's fantastic! Just fantastic! No wonder you won the Tournament!","I'm Viola! We're going to snag some picturesque victories I promise!","You and your Pokémon have shown me a whole new depth of field! Fantastic! Just fantastic!"],
  				[:LEADER_Grant,"Grant","You have proven to be a wall that I am unable to surmount!","Yes, this is the way it should be. This way both humans and Pokémon will grow.",1,"There are some things you just can't reach, no matter how far you stretch out your hand. It's important that you never give up, no matter the opponent or the odds.","My name's Grant. I'm the Cyllage City Gym Leader back in Kalos. I climb any wall in front of me!","There is only one thing I wish for. That by surpassing one another, we find a way to even greater heights."],
  				[:LEADER_Korrina,"Korrina","It's your very being that allows your Pokémon to evolve!","My Mega Evolution skills were tougher than yours today!",1,"As long as we can be caring and courageous, the world will be full of smiles!","Time for Lady Korrina’s big appearance! Together, we can aim even higher!","What an explosive battle! I could tell that you didn't hold anything back! With strong bonds like that, you shouldn't have any trouble triggering your Pokémon's Mega Evolution!"],
  				[:LEADER_Ramos,"Ramos","A true friendship with Pokémon takes time. Yeh can't force it, yeh little whippersnapper!","Hohoho... Indeed. Frail little blades o' grass'll break through even concrete.",1,"As long as we can be caring and courageous, the world will be full of smiles!","Ho ho! The name's Ramos. I may not look it, but I'm a Grass-type Gym Leader. If yeh want to know about plants, I'm yer man!","Yeh believe in yer Pokémon... And they believe in yeh, too... It was a fine battle, sprout."],
  				[:LEADER_Clement,"Clement","Your passion for battle inspires me!","Looks like my Trainer-Grow-Stronger Machine, Mach 2 is really working!",1,"How did the world look after defeating the Champion? I really want to understand it. The way the world looks to a real Pokémon Champion... I'm trying to invent a machine that will let me see it for myself.","The name's Clemont! I like my Pokémon battles how I like my inventions. High Voltage!","I'm glad whenever I get to learn from other strong challengers. Thank you for the battle!"],				
  				[:LEADER_Valerie,"Valerie","That was truly a captivating battle. I might just be captivated by you.","Oh goodness, what a pity...",1,"Oh, if it isn't my young Trainer... It is lovely to get to meet you again like this. What do you think it is exactly that separates humans from Pokémon? Is there even need for such a thing? Why should they be separate from one another?","I'm Valerie. A fairy type Gym Leader. The elusive fairy may appear delicate as a bloom, but it is strong.","I hope that you will find things worth smiling about tomorrow..."],	 
  				[:LEADER_Olympia,"Olympia","Create your own path. Let nothing get in your way. Your fate, your future.","Winner and loser. A winged Pokémon leads on, to the goal of both.",1,"The glint of sunrise. As the world brightens, so too does the future.","A battle to decide your fate and future. The battle begins!","Create your own path. Let nothing get in your way. Your fate, your future."],
  				[:LEADER_Wulfric,"Wulfric","Outstanding! I'm tough as an iceberg, but you smashed me through and through!","I am as tough as an iceberg!",1,"Ice-type Pokémon are cold to the touch. Give one a hug and you're in for a chill. But you know what? They're only cold on the outside. On the inside, they have hearts as warm as anyone!","You know what? We all talk big about what you learn from battling and bonds and all that, but really, I just do it 'cause it's fun. Who cares about the grandstanding? Let's get to battling!","You know what? Your Pokémon really threw everything they had into that battle just now. You truly are something, you know?"]      
               ],
  :rules_proc => proc {|length|
    rules = PokemonChallengeRules.new
    rules.addPokemonRule(BannedSpeciesRestriction.new(:MEWTWO,:MEW,:HOOH,:LUGIA,:CELEBI,:KYOGRE,:GROUDON,:RAYQUAZA,
                                                      :DEOXYS,:JIRACHI,:DIALGA,:PALKIA,:GIRATINA,:REGIGIGAS,:HEATRAN,:DARKRAI,
                                                      :SHAYMIN,:ARCEUS,:ZEKROM,:RESHIRAM,:KYUREM,:LANDORUS,:MELOETTA,
                                                      :KELDEO,:GENESECT))
    rules.addPokemonRule(NonEggRestriction.new)
    rules.addPokemonRule(AblePokemonRestriction.new)
    rules.setNumber(length)
    rules.setLevelAdjustment(FixedLevelAdjustment.new(50))
    next rules
  },
  :banned_proc => proc {
    pbMessage(_INTL("Certain exotic species, as well as eggs, are ineligible.\\1"))
  },
  :points_won => 2
})

GameData::PWTTournament.register({
  :id => :Aloha_Leaders,
  :name => _INTL("Aloha Leaders"),
	:trainers => [
		[:LEADER_Acerola,"Acerola","Being in the Elite Four is fun, but so is being a captain... Hmm, I'm not sure which to do...","My barrier was tough to break. Maybe next time.",1,"You were pretty tough! I can't wait to face off against you again!","Hey, even if you are the Champion, you can't go into the Champion's chamber without proving you can still get past the Elite Four! And besides...battling is just plain fun! Come on, I can take you!","No matter how strong I am, I know that there are things I can't do... Places I can't reach and people I can't protect. That's why I want to make all the kids at Aether House into superstrong Trainers themselves!"],
		[:LEADER_Hala,"Hala","I sensed the strength that you possess as Champion.","My barrier was tough to break. Maybe next time.",1,"You were pretty tough! I can't wait to face off against you again!","Oh ho ho! So it's me who faced you. Let our island challenge begin!","A heart-pounding battle like that always sends a shiver through my whole body! I'm sure my Pokémon felt it, too!"],
		[:LEADER_Kahili,"Kahili","Being in the Elite Four is fun, but so is being a captain... Hmm, I'm not sure which to do...","My barrier was tough to break. Maybe next time.",1,"It's frustrating to me as a member of the Elite Four, but it seems your strength is the real deal.","Alola! And alola once again! My name is Kahili. A few years ago, I was a champion of the island challenge, too. Just like you. I've been traveling the world to improve my skill as both a Trainer and as a golfer. Have a look at my fantastic Flying-type team!","Now we're all going to be aiming for your seat. I hope you're ready for some rivals."],
		[:LEADER_Kiawe,"Kiawe","You were on fire during that battle...","The name's Kiawe, the Fire captain. Let's get this done!",1,"That battle burned with passion! You truly understand Fire-type Pokémon!","Alola! I am Kiawe, a Fire-type captain who trains on Wela Volcano. My Marowak and I carry on the dances passed down through the generations!","When flames burn together, they burn brighter. I look forward to our next battle!"],
		[:LEADER_Molayne,"Molayne","I found an interesting trainer to face!","Let's get this done!",1,"That battle burned with passion! You truly understand Fire-type Pokémon!","The Pokémon League is fantastic! It's a place that conveys the awesomeness of Alola to the world. And in that case, I guess that what's important is what kind of Trainer the Champion is.","Just as I'd expect from the Champion! In every situation, you pick the best moves and items. So I too have to rack my brain in the battle..."],
		[:LEADER_Nanu,"Nanu","I'm an island kahuna, you know? From Alola. Oh, and the name's Nanu.","Well, then. Guess I can take it easy now.",1,"You’re strong... stronger than I expected, even.","Name’s Nanu. I’m one of Alola’s kahunas, though I don’t really like doing the whole formal thing. Let’s get this over with.","Hmm, already midday. You can train as hard as you like, but don’t overdo it."],
		[:LEADER_Olivia,"Olivia","That was great!","My partner's an adorable, rugged little Rock type. We'll grind you to dust.",1,"You’ve got some real sparkle to you as a Trainer.","I’m Olivia, the kahuna of Akala Island. I admire the strength and beauty that come from battling with Rock-type Pokémon.","I'm starting to feel like a polished diamond. Let's both keep shining brighter!"],
		[:LEADER_Lana,"Lana","I simply can't suppress the curiosity welling up within me...","Hello there, I'm Lana, captain of Brooklet Hill. My specialty is Water-type Pokémon, and I love to see how Trainers handle the flow of battle.",1,"That was quite the splashy performance!","Hello there, I'm Lana, captain of Brooklet Hill. My specialty is Water-type Pokémon, and I love to see how Trainers handle the flow of battle.","I...I must say that I find myself at an impasse here. You are strong congrats!"],
		[:LEADER_Mallow,"Mallow","Let me serve you up a plate of my Super Mallow Special sometime!","Hey! Thanks for stopping by! I'm Mallow, one of Alola's captains! I am the Trial for the Lush Jungle. Anyways lets do this!",1,"That was quite the grassy performance!","Hey! Thanks for stopping by! I'm Mallow, one of Alola's captains! I am the Trial for the Lush Jungle. Anyways lets do this!","Wanna try my signature special dish? You haven't lived until you've tasted it!"],
		[:LEADER_Sophocles,"Sophocles"," couldn't get it done... Don't worry about it, my precious Pokémon..","My barrier was tough to break. Maybe next time.",1,"You were pretty tough! I can't wait to face off against you again!","Playing games with Big Mo... Maintaining Festival Plaza... Checking the anime I've recorded... They're all fun but not the same as a battle with you,","You're way too strong... Ping Totem Pokémon 2.0 is running smoothly, so next I'm thinking that I should put together Sophocles's enhanced program."],
		[:LEADER_Mina,"Mina","I'm shocked at your strength!","My barrier was tough to break. Maybe next time.",1,"You were pretty tough! I can't wait to face off against you again!","How about it, Hoeen Trainer? Want to try battling my Fairy-type Pokémon?","Oh! Wonderful! You and your Pokémon, battling side by side... Now that's a great composition! I'd love to draw a picture of you two."]
	],

  :rules_proc => proc {|length|
    rules = PokemonChallengeRules.new
    rules.addPokemonRule(BannedSpeciesRestriction.new(:MEWTWO,:MEW,:HOOH,:LUGIA,:CELEBI,:KYOGRE,:GROUDON,:RAYQUAZA,
                                                      :DEOXYS,:JIRACHI,:DIALGA,:PALKIA,:GIRATINA,:REGIGIGAS,:HEATRAN,:DARKRAI,
                                                      :SHAYMIN,:ARCEUS,:ZEKROM,:RESHIRAM,:KYUREM,:LANDORUS,:MELOETTA,
                                                      :KELDEO,:GENESECT))
    rules.addPokemonRule(NonEggRestriction.new)
    rules.addPokemonRule(AblePokemonRestriction.new)
    rules.setNumber(length)
    rules.setLevelAdjustment(FixedLevelAdjustment.new(50))
    next rules
  },
  :banned_proc => proc {
    pbMessage(_INTL("Certain exotic species, as well as eggs, are ineligible.\\1"))
  },
  :points_won => 2
})

GameData::PWTTournament.register({
  :id => :Galar_Leaders,
  :name => _INTL("Galar Leaders"),
  :trainers => [
  				[:LEADER_Milo,"Milo","The power of Grass has been wilted... You're quite the Champion!","The power of Grass has succeeded...",1,"That determined expression... That glint in your eye that says you're up to the challenge... It's fantastic! Just fantastic! No wonder you won the Tournament!","Don't think I'm the same Milo as in the Gym Challenge! You're the great Champion, after all. It'd be rude not to go all out!","Soon you'll be the one to face down Gym Challengers aiming for your title. I can't wait to see what talent grows!"],
  				[:LEADER_Nessa,"Nessa","You've cut off our flow before it even got going. No wonder you're the Champion...","That was the best final match I could have hoped for.",1,"The waves have receded, and only you and I are left standing... Congratulations on this victory","I think you already realize, but I'm Nessa. Sorry to have made you look for me. Your mind as a Pokémon Trainer must be quite refined.","Your teamwork was just flawless! It's enough to make me a bit jealous."],
  				[:LEADER_Kabu,"Kabu","Good Pokémon and a great Trainer! It's no surprise that you won!","My Mega Evolution skills were tougher than yours today!",1,"As long as we can be caring and courageous, the world will be full of smiles!","I'll always press on and challenge myself so that I can go on as a Pokémon Trainer for as long as possible. As long as you continue to push yourself, your brilliance will never fade","A tournament that ends when you lose! Whoever can keep up the heat will win!"],
  				[:LEADER_Allister,"Allister","How frightening...","How lucky...",1,"My mask... It feels like it's going to fall off...","H-here...I go...","G...good luck! With...um...everything..."],
  				[:LEADER_Klara,"Klara","What's going on? Am I being mocked...by a kid?!","How lucky...",1,"Sorry, not sorry, but I haven't accepted you as the hotshot everyone else seems to think you are. You'd better think again if you think I'm gonna let you finish this trial before me, mate...","Ahem! Hey, that wasn't bad! I mean, It's not like I was going all out not... at all... but still!"],
  				[:LEADER_Avery,"Avery","Ah, um... Could...could you give me a moment?","Prepare to experience psychic powers that defy human comprehension!",1,"Now, listen... If you dare breathe a word of what happened in our battle to Ms. Honey... Well, let's just say my psychic powers are very potent. Do I make myself clear?","Improbable... No, impossible! What kind of Trick did this kid use? If a Trainer of this talent wins, then the people there very well may suffer Amnesia about my very existence!"],
  				[:LEADER_Bea,"Bea","Thank you for a wonderful match.","I promise you, my attacks will shake your very soul this time. ",1,"Thank you for a wonderful match. I really enjoyed battling you and your team. I'm upset that I lost, but I also feel so satisfied and so refreshed. In a way, I guess you could say it was the best sort of match anyone could ever hope for. I hope that you'll meet many more trainers and have many more matches in the future. And I hope that every one of those encounters will nourish your spirit.","My heart is racing a bit, but I still can't wait for the match to begin!","I hope that you'll meet many more Trainers and have many more matches in the future. And I hope that every one of those encounters will nourish your spirit."],
  				[:LEADER_Opal,"Opal","Well, good try. Not bad, not bad at all. Still, not what I'm looking for...","Still not what I am looking for...",1,"Of course it's not good to neglect your elders, but old folk like me should also know when it's time to step out of the spotlight.","Ah, there you are, my dear Gym Challenger. Though you are really lacking in the color pink.","I suppose it's a bit late to introduce myself, but... I'm Opal, the Gym Leader. I've gotten a good look at how you handled those quizzes. The last part of the mission is me... Let me have a look at how you and your partner Pokémon behave!"],				
  				[:LEADER_Gordie,"Gordie","That was...impressive. Rules are rules. ","Of course, you'd stand no chance against me if you let a few holes get in your way.",1,"The air's so damp in here! Makes it quite hot and humid, doesn't it? If my mum were here, she'd never stop complaining about it. That's for sure..","Hey there. The name's Gordie. I admit I feel a little bad for doing this to a Challenger, but... I'm going to use this match to show the crowd that my Pokémon are unbeatable! So, let's get this over with, Challenger!","We're trying out some tricky movements geared to bring out Coalossal's full power. So don't get too comfortable being Champion!"],	 
  				[:LEADER_Melony,"Melony","Ohoho! Of course you had no problem","Ohoho! Of course I had no problem",1,"I am Melony. As you can clearly see, I've assembled a team of all Ice-type Pokémon. You! You aren't sore all over from falling in a hole or two, are you? Even if you are, I'm not going to hold back! All righty, I suppose we should get started. You won't be able to escape when I freeze you solid. And after that... Well, you'll see. I think you'll find my battle style is quite severe.","You... You're pretty good, huh? Of course seeing my Pokémon lose is sad, but to meet someone so young with such ability is quite grand."],
  				[:LEADER_Piers,"Piers","I'm glad we were able to battle. Seems like my Pokémon feel the same way.","My little sis Marnie's gonna challenge me next, I bet.",1,"Kid's sure got a mouth on him, huh? If you were that noisy durin' battle, you'd unleash a whole new level of power, you know.","I'm the Gym Leader of Spikemuth, Piers, the Dark-type user! You wanna challenge me, even though you know you'll lose? Then this song's for you, foolish Trainer!","Get ready for a mosh pit with me and my party! Spikemuth, it's time to rock!"],
  				[:LEADER_Raihan,"Raihan","Good on you, kid. Now, prove your strength to the whole region","I am as tough as a dragon!",1,"Your strength is genuine, as proven by you defeating me. You came at me with all the force of a raging storm, and even I was blown away!","Finally, a challenger made it! I've been waiting for someone to battle... Though I've got to admit I didn't think it'd be you!","In the aftermath of the furious battle... I feel as pure and refreshed as when the sky clears after a storm. What can I possibly say? Calling myself Leon's rival? Seems I'd grown quite conceited for someone who can't even claim the title of Champion! Overconfident in both myself and my team!"]      
               ],
  :rules_proc => proc {|length|
    rules = PokemonChallengeRules.new
    rules.addPokemonRule(BannedSpeciesRestriction.new(:MEWTWO,:MEW,:HOOH,:LUGIA,:CELEBI,:KYOGRE,:GROUDON,:RAYQUAZA,
                                                      :DEOXYS,:JIRACHI,:DIALGA,:PALKIA,:GIRATINA,:REGIGIGAS,:HEATRAN,:DARKRAI,
                                                      :SHAYMIN,:ARCEUS,:ZEKROM,:RESHIRAM,:KYUREM,:LANDORUS,:MELOETTA,
                                                      :KELDEO,:GENESECT))
    rules.addPokemonRule(NonEggRestriction.new)
    rules.addPokemonRule(AblePokemonRestriction.new)
    rules.setNumber(length)
    rules.setLevelAdjustment(FixedLevelAdjustment.new(50))
    next rules
  },
  :banned_proc => proc {
    pbMessage(_INTL("Certain exotic species, as well as eggs, are ineligible.\\1"))
  },
  :points_won => 2
})



GameData::PWTTournament.register({
  :id => :Rival_Leaders,
  :name => _INTL("Rivals"),
  :trainers => [
     			[:LEADER_Barry,"Barry","What just went down?! You're telling me I lost?","What just went down? You're telling me I won?",1,"How are you doing? Me? You even need to ask? Piling up the wins at the Battle Tower! Huh? My longest winning streak? What, you're going to grill me now?","What took you so long? I'm fining you $100 million! Listen up. I'm going to become the greatest Trainer ever. That's why I'm here to toughen up myself and my Pokémon!","The tougher you get, the tougher we can get, too. There's no end to Pokémon. That's what I'm saying!"],
     			[:LEADER_Marnie,"Marnie","Aw, I wanted to keep battlin'... I guess you win this round","Guess I win this round...",1,"I'm Marnie from Spikemuth. Guess you an' me are gonna be seein' a lot more of each other from now on, huh?","This is it... The last big match. Hey, d'you need me to cheer you on a bit?","Well, you better make sure you win the tournament now for us!"],
     			[:LEADER_Bede,"Bede","Well, that was unexpected. I suppose you're more able than I thought.","As expected...",1,"What are you doing here? Did that old gran make you come stand guard here, too? March you all the way to the Isle of Armor so you could reach new heights of pink... or whatever?","I was endorsed by the chairman himself. In other words, among all those elite enough to get an endorsement, I'm the most elite of all. I suppose I should prove beyond doubt just how pathetic you are and how strong I am.","I'm sure to easily defeat you if and when we face each other in an official match."],
     			[:LEADER_Bianca,"Bianca","Phew! You're really a strong Trainer, that's for sure!","The Pokémon on both sides tried sooo hard, didn't they?",1,"Even if it's just little by little, I'm learning about Pokémon. I'm thinking about how to bring out the best from everyone, but I still have a ways to go. Oh, I almost forgot! Congratulations on your victory!","Know what? When I traveled the Unova region, so many things happened to me, but I'm so glad I went on that journey! I met a lot of Pokémon and found what I really wanted to do... It's hard to put into words, but I want to express this feeling through my Pokémon.","Thank you for being my opponent! Yep! I learned a lot! Know what? Recently, I've been thinking Pokémon stay by our sides to bring people together... I'm thinking of researching that!"],				
     			[:LEADER_Gladion,"Gladion","All I have to do is avoid making any more mistakes... After all, I have Silvally with me.","Silvally... Our training paid off!",1,"Call me Gladion. I like Pokémon battling because it doesn't matter if you're a kid or an adult. Everyone's equal here!","What does a Pokémon Trainer really need to be successful? I trained for a long time trying to figure that out. I guess everyone might have their own answer. But at least for me... I want the strongest rival for myself.","I didn't beat you, but it was still worth it... Going to train in Kanto, I mean. At the very least, I can appreciate your strength a lot more now than I could've before. Thanks, Champ. You've helped make us stronger."],	
     			[:LEADER_Hau,"Hau","It's hard to be strong enough to admit that you're weak... you know?","A-lo-la! The salty breeze sang to me and brought me here to you! That's why I won!",1,"Hey, I'm Hau. Nice to meet you! I'm from Melemele Island, and my old gramps is the kahuna there! Have you faced him yet?","I'm back! And I'll keep coming back, too! No matter how many times it takes. I'm not giving up until I overcome the obstacle that's staring me right in the face!","Man, I really want to be stronger than a kahuna! But I still just don't get how I can do that... But if I keep trying and using my full power, I think I'll find the way. That's how I feel whenever I battle."],
     			[:LEADER_Wally,"Wally","I've lost…","Ugh. So this was your limit.",1,"Let's battle again sometime okay?","I trained all over Hoenn winning and losing to take on the world. We both have been through a lot. Please have a look at my results!","Hah…hah… Maybe I need to start again from scratch. But you performed as well as I'd expect! You even beat the best team I could put together! And, well, Pokémon battling really is great, isn't it? When I get to spend every day training and battling like this, I really can't help thinking, so… I enjoy every day so much that I really think I finally found where I belong. I…I'm going to keep getting stronger! So please battle with me again!"],				
     			[:LEADER_Blue,"Blue","How the heck did I lose to you?","This is what I, Kanto's top-level Trainer, can really do!",1,"Three wins and you've done it! Luck can also be a factor, and I'm still not satisfied at all! Oh, I didn't think you won because of luck, though!","I'll know if you are good or not by battling you right now. Will you be as strong as him?","You're the real deal. You are a good Trainer. But I'm going to beat you someday. Don't you forget it! Smell yah later!"],				
     			[:LEADER_Hugh,"Hugh","Phew! You're really something!","Wait up! Is that it?",1,"I can see how your the strongest in Hoenn. You remind me of a close friend.","I'm Hugh. Pokémon should be protected...and I'm willing to fight for all of them!","Thank you. Battling you reminds me of my friend. You two are very similiar. I hope we can battle again someday!"],
     			[:LEADER_Silver,"Silver","Humph! You were too strong…","Humph! I knew it. Strength is everything. Nothing else matters.",1,"I haven't given up on becoming the greatest Trainer… I'm going to find out why I can't win and become stronger… When I do, I will challenge you. I'll beat you down with all my power. …Humph! You keep at it until then.","I wonder if that OLD MAN is watching right now. I remember when he told me he was number one in the world. Instead he quit and left me. I promised I wouldn't become like him. Never will I be a coward. I am here today to prove my power to the world!","I couldn't win… I gave it everything I had… What you possess and what I lack, I'm beginning to understand what that Dragon Tamer said to me so long ago alongside gold..."]
               ],
  :rules_proc => proc {|length|
    rules = PokemonChallengeRules.new
    rules.addPokemonRule(BannedSpeciesRestriction.new(:MEWTWO,:MEW,:HOOH,:LUGIA,:CELEBI,:KYOGRE,:GROUDON,:RAYQUAZA,
                                                      :DEOXYS,:JIRACHI,:DIALGA,:PALKIA,:GIRATINA,:REGIGIGAS,:HEATRAN,:DARKRAI,
                                                      :SHAYMIN,:ARCEUS,:ZEKROM,:RESHIRAM,:KYUREM,:LANDORUS,:MELOETTA,
                                                      :KELDEO,:GENESECT))
    rules.addPokemonRule(NonEggRestriction.new)
    rules.addPokemonRule(AblePokemonRestriction.new)
    rules.setNumber(length)
    rules.setLevelAdjustment(FixedLevelAdjustment.new(50))
    next rules
  },
  :banned_proc => proc {
    pbMessage(_INTL("Certain exotic species, as well as eggs, are ineligible.\\1"))
  },
  :points_won => 2
})

GameData::PWTTournament.register({
  :id => :Evil_Leaders,
  :name => _INTL("Evil Leaders"),
  :trainers => [
     			[:LEADER_Archie,"Archie","I hope we can have a battle like this again in the future!","Wait up! After all this time I finally won?",1,"You always were the strongest. Thanks to you Team Aqua has new goals.","I have given a lot of thought after what happened... I decided to join in the Pokemon World Championships to test myself. I hope your ready!","Ohhh! No one enjoys losing, I saw this loss coming. You've gotten even stronger!"],
     			[:LEADER_Maxie,"Maxie","You are as strong as ever!","So I finally did it...",1,"I wonder after all the events that occurred. What ever happened to Team Sky's Admin Tempest?","I knew If I joined in this tournament we would get to battle again. Allow me to show you how much more I've learned!","You have proven to be a wall that has gotten in the way of all of my plans, but thanks to you I was able to find a new purpose in life!"],
     			[:LEADER_Evice,"Evice","Waahahah! Let us meet again! Our bid to take over the world using Shadow Pokémon hasn't ended yet!","Your pitiful.",1,"The Shadow Pokemon experiments have just begun!","Ah, it's good to see you. Indeed it is. I've been worried about you. I was worried that you'd run off out of fear of me! Hohoho! Now, are you prepared to be devastated once again?","Waahahah! Let us meet again! Our bid to take over the world using Shadow Pokémon hasn't ended yet!"],               
     			[:LEADER_Cyrus,"Cyrus","This... this cannot be! It's not possible that I lose!","I will not let anyone get in my way...",1,"So you have a spirit, as well. But it's too late... All too late. I cannot stop now. I must remove the weak, incomplete human spirit from this world and bring it perfection!","Why should I run and hide from the world and have to wait quietly? My aim is to rid our world of the vague and incomplete thing we call spirit. By freeing ourselves of that, our world can be made complete. That is my justice! No one can interfere!","I won't accept this! This can't be! Not after all the sacrifices we've made to get this far! What of my new world?! Of my new galaxy?! Was this all a dream to be swept away by your reality?"],				
     			[:LEADER_Ghetsis,"Ghetsis","Team Plasma shall live on forever!","Myah-ha-ha! No, no, no, no, no! You don't get it, do you? I can't be defeated! I won't be! IT. CANNOT. BE. ALLOWED!",1," I have been thinking long and hard about the reason I have been sent to this world. And now...I believe I finally have the answer! My purpose... It is to travel between the worlds, freeing all Pokémon from foolish people... And at the same time, consolidate all the power in all the worlds to myself!","You being here doesn't mean you're a threat. Come on! Now you'll face ME in battle! I can't wait to see the look on your face when you've lost all hope!","What?! I created Team Plasma with my own hands. I'm absolutely perfect! I AM PERFECTION! I am the perfect ruler of a perfect new world!"],				
     			[:LEADER_Guzma,"Guzma","I guess that's how it is, Champion! But I'm not beat down yet!","Not yet! I could still keep wrecking! Come at me as many times as you want!",1,"I'm the big bad boss who beats you down and beats you down and never lets up! Now's the time for this vaunted team to let loose and destroy everything!","Wanna see what destruction looks like? Here it is in human form it's your boy Guzma!","I'll remember you...as someone I'll be happy to beat down anytime!"],				
     			[:LEADER_Lusamine,"Lusamine","All that I want is my precious beast! I don't care about any of the rest of you!","Now it's just me and my ultra beasts!",1,"The world of my Ultra Beasts... A world where the only thing that exists is the love between Nihilego and myself. So beautiful... So delicious... This is the real paradise!","What a disappointment... To think that you are all so small-minded... I may need to silence you first!","The world of my Ultra Beasts... A world where the only thing that exists is the love between Nihilego and myself. So beautiful... So delicious... This is the real paradise!"],
     			[:LEADER_Lysandre,"Lysandre","I can feel the fire of your convictions burning deep within your heart!","I could have never lost to a kid like you!",1,"I can see how your the strongest in Hoenn. You remind me of a close friend.","This world will eventually reach the point of no return... Saving the lives of all is impossible. Only the chosen ones will obtain a ticket to tomorrow. Do you want to have a ticket? Or, do you want to stop me? Show me in battle.","Maybe...if my world had a Trainer like you, the path I chose could have been different... No! Nothing can change me now! If there is a path to creating a beautiful world, then that is the path I must take! Even if it means I can only save a handful of the old world!"],
				[:LEADER_Giovanni,"Giovanni","What? Me, lose?!","Haarg! I lose?! There is nothing I wish to say to you!",1,"I'll tell you this now... No matter how strong you are, someday you'll lose. That Red will feel it too someday...","For your insolence, you will feel a world of pain!","Haarg! I lose?! There is nothing I wish to say to you!"]						
               ],
  :rules_proc => proc {|length|
    rules = PokemonChallengeRules.new
    rules.addPokemonRule(BannedSpeciesRestriction.new(:MEWTWO,:MEW,:HOOH,:LUGIA,:CELEBI,:KYOGRE,:GROUDON,:RAYQUAZA,
                                                      :DEOXYS,:JIRACHI,:DIALGA,:PALKIA,:GIRATINA,:REGIGIGAS,:HEATRAN,:DARKRAI,
                                                      :SHAYMIN,:ARCEUS,:ZEKROM,:RESHIRAM,:KYUREM,:LANDORUS,:MELOETTA,
                                                      :KELDEO,:GENESECT))
    rules.addPokemonRule(NonEggRestriction.new)
    rules.addPokemonRule(AblePokemonRestriction.new)
    rules.setNumber(length)
    rules.setLevelAdjustment(FixedLevelAdjustment.new(50))
    next rules
  },
  :banned_proc => proc {
    pbMessage(_INTL("Certain exotic species, as well as eggs, are ineligible.\\1"))
  },
  :points_won => 2
})

GameData::PWTTournament.register({
  :id => :Legacy_League,
  :name => _INTL("Legacy League"),
  :trainers => [
  				[:LEADER_Mira,"Mira","Oh, no! You're too much for me!","Mira wonders if she can get very far in this Tournament!",1,"Please teach Mira about Pokémon again sometime! Mira wants to get a lot, lot stronger.","I'm Mira. I like helpful Pokémon moves like Growl and Minimize. Those kinds of moves are my favorites. Anyways let's not get lost in conversation. Let's do this!","You are always with your Pokémon. That's how you got to be so strong. Mira is beginning to understand!"],
  				[:LEADER_N,"N"," Please share your courage with me!","...",1," I can't allow selfish humans to make Pokémon suffer! And I like Unova. It's the place that taught me how to live as a human... It's the place that made me notice the harmony between Pokémon and humans living together... I will protect the Pokémon and humans who live here!","My name is N. I will show you that my love for my friends permeates every cell of my body. Behold!","Pokémon are not tools. Pokémon and humans take each other to greater heights. They are our wonderful partners. Some humans understand this. Some others cannot."],
  				[:LEADER_Cheryl,"Cheryl","Striking the right balance of offense and defense... It's not easy to do.","I am strong after all!",1,"Battling with you makes me feel elated. If I could predict what you're about to do, we would make a fierce combo!","Hello, my name's Cheryl. I'm a Pokémon Trainer. It's nice to meet you! I learned how to battle better from someone I met within Eterna Forest! Let's see how I can do!","Being a Trainer isn't easy. The more you battle, the more you discover. But, you know? I love Pokémon for that, too!"],
  				[:LEADER_Emma,"Emma","Hmm... I lost...","Hmm... I Won...",1,"How're you doing? We've got no new cases in the Looker Bureau for a while, so I decided to take a little trip here.","Oh, me? I'm Emma. Nice to meet you! I hope Looker is watching to see how much I've grown!","Hehehe... I lost... Hehehe... That was great! I knew you must be good at battling"],
  				[:LEADER_Marley,"Marley","Awww...","Awww Yes!",1,"You're so strong. It makes me feel happy. ...I don't know why. This is a strange feeling...","I... I don't like to talk... I choose my words carefully, but they may still hurt someone accidentally... When I think of that, I clam up... That's why I think this certain Pokémon is so wonderful. It's a Pokémon that conveys the feelings of gratitude in a nice way..","You're so strong. It makes me feel happy. ...I don't know why. This is a strange feeling..."],
  				[:LEADER_Riley,"Riley","At times we battle, and sometime we team up. It's great how Trainers can interact.","Your team! I sense your strong aura!",1,"How did the world look after defeating the Champion? I really want to understand it. The way the world looks to a real Pokémon Champion... I'm trying to invent a machine that will let me see it for myself.","You and I, we're both Trainers. Let's forego the small talk and proceed right to battle. That's my style!","Know your enemy. If you know your opponent's Pokémon and what moves they use... If you have intelligence like that, your chances of winning are much improved."],				
   				[:LEADER_Eusine,"Eusine","I hate to admit it, but you win.","That was a good battle Suicune is proud!",1,"My grandpa was...quite into myths. I've heard so many stories about Suicune from him.","Suicune is beautiful and grand. And it races through towns and roads at simply awesome speeds. It's wonderful...","My grandpa was...quite into myths. I've heard so many stories about Suicune from him."], 				
  				[:LEADER_Ryuki,"Ryuki","I'm gonna belt out everything inside of me! I've gotta encourage my Pokémon to keep rocking!","My Pokemon will keep rocking!",1,"Oooh, that Champion's strength! I feel the flames of jealousy burning in my heart! But passing through the fire makes me stronger, and that's why I'm a star! I'll roll into town again sometime, Champ. I'm always looking for a good gig.","My babies here are dying to play a set. I figure what better stage than the Champion's! Allow me to introduce my bandmates! Come on, babies!","The name's Ryuki. I'm what you might call a star. I came all the way across the sea to spread my fame out here, too! That was a great battle!"],				
  				[:LEADER_Colress,"Colress","Well done! I learned much from this battle!","I have learned much from this battle!",1,"By having battles with many Trainers, I can bring out Pokémon Abilities! Eventually, as I continue to battle, the truth of my theory will be evident to all!","As a researcher, it is the truth and the ideal way things should be that I seek. The latent power of Pokémon… What is the best way to bring it out? If possible, I want it to be the trust between Trainers and their Pokémon, just as it has always been. I look forward to you teaching me that this is indeed true!","Just as I expected! Your Pokémon must be happy to be by your side! You bring out the best in their power!"],
  				[:LEADER_Arven,"Arven","Hehehe... Caught your interest, have I?","Yeah, you're in serious trouble if you can't even beat someone like me. I'd be worried about my future, if I were you.",1,"Area Zero... That place is bad news. It was down in Area Zero that Mabosstiff got wounded in the first place... Down in the Great Crater of Paldea.","I normally wouldn't even bother showing up here, but I came all the way here today just to talk with you, our new celebrity. You've gotta help me out so I can finally make my dream a reality!","Seems like you know a thing or two about battle."],				
  				[:LEADER_Benga,"Benga","You and me we had the best match!","You and me we had the best match!",1,"So exciting! You and your Pokémon's combination! Amazing teamwork! Places where humans can't go alone. Places where Pokémon don't think to go. You can go anywhere with teamwork. Between Trainers and Pokémon! Like you and me! I'm glad you understand that now!","My name is Benga. I am Alder's grandson and the final Boss Trainer of the Black Tower from the Unova Region! Our Pokémon! The strength we have! We'll give it our all! No holding back!","So exciting! My grampa was the Champion! But Trainers like you are even stronger! We just need to keep competing! Then we can keep aiming higher! As Pokémon Trainers! And as people! And it's all thanks to our Pokémon! Come again! I want to keep aiming higher!"],     
               ],
  :rules_proc => proc {|length|
    rules = PokemonChallengeRules.new
    rules.addPokemonRule(BannedSpeciesRestriction.new(:MEWTWO,:MEW,:HOOH,:LUGIA,:CELEBI,:KYOGRE,:GROUDON,:RAYQUAZA,
                                                      :DEOXYS,:JIRACHI,:DIALGA,:PALKIA,:GIRATINA,:REGIGIGAS,:HEATRAN,:DARKRAI,
                                                      :SHAYMIN,:ARCEUS,:ZEKROM,:RESHIRAM,:KYUREM,:LANDORUS,:MELOETTA,
                                                      :KELDEO,:GENESECT))
    rules.addPokemonRule(NonEggRestriction.new)
    rules.addPokemonRule(AblePokemonRestriction.new)
    rules.setNumber(length)
    rules.setLevelAdjustment(FixedLevelAdjustment.new(50))
    next rules
  },
  :banned_proc => proc {
    pbMessage(_INTL("Certain exotic species, as well as eggs, are ineligible.\\1"))
  },
  :points_won => 2
})

GameData::PWTTournament.register({
  :id => :e4_leaders,
  :name => _INTL("Elite 4"),
  :trainers => [
     			[:LEADER_Aaron,"Aaron","I lost with the most beautiful and toughest of the bug Pokémon...","I never give up, no matter what. You must be the same?",1,"I'm a huge fan of bug Pokémon. Bug Pokémon are nasty-mean, and yet they're beautiful, too... Would you like to know why I take on challengers here, in this room? It's because I want to become perfect, just like my bug Pokémon!"," I'm Aaron of the Sinnoh Elite Four. It's good to meet you. Oh, I should explain, I'm a huge fan of bug Pokémon. Bug Pokémon are nasty-mean, and yet they're beautiful, too...","I will now concede defeat. But I think you came to see how great Bug-type Pokémon can be. I hope you also realized why you're up against here. Battling is a deep and complex affair..."],
     			[:LEADER_Agatha,"Agatha","Oh my! You're something special, child!","Oh my! I am still special.",1,"How's your training going? Don't forget to take a break every now and then.","I'm Agatha, of the Indigo Elite Four! Let's see what you can do, child!","Oak and I used to be rivals. It reminds me of the boy he sent on a journey alongside his grandson."],
     			[:LEADER_Bertha,"Bertha","Well! Dear child, I must say, that was most impressive.","Well! Dear child, I must say, that was most impressive",1,"You really must have your wits about you. However, I think you can go as far as you desire. Ahahaha!","Well, well. You're quite the adorable Trainer, but you've also got a spine. Ahaha! I'm Bertha. I have a preference for Ground-type Pokémon. Well, would you show this old lady how much you've learned?","You're quite something, youngster. I like how you and your Pokémon earned the win by working as one. That's what makes you so strong. Ahahaha! I think that you can go as far as you want."],
     			[:LEADER_Bruno,"Bruno","Why?! …How could we lose?","Fight as hard as you can 'til you faint!",1,"Ugh! No! So my training is still lacking, is that it? ...Go. Do not trouble yourself on my behalf. Continue to move forward!","I am Bruno of the Elite Four. I always train to the extreme because I believe in our potential. That is how we became strong. Can you withstand our power? Hm? I see no fear in you. You look determined. Perfect for battle! Ready?","Having lost, I have no right to say anything… Go face your next challenge!"],
     			[:LEADER_Flint,"Flint","...","I am heating up now!",1,"This situation just cooks! The drama and tension sizzles! Flint, the fiery master of fire Pokémon, is going to put you to the test! Let Flint see how hot your spirit burns!","I was waiting for you, challenger! Flint, the master of the Fire-type, is up next! Battles are clashes of the burning spirit of Pokémon. Battles aren't about appearances or what's weak or strong. It all comes down to whether the combatants can burn hot or not.","I wasn't expecting this! I wasn't looking down on you... But I didn't think for one second that I'd lose! This is fantastic! You and your Pokémon are inspiring!"],	
     			[:LEADER_Grimsley,"Grimsley","Nice...","Good, good... But I will never retreat from any battle.",1,"If somebody wins a battle, then, without doubt, someone else has lost the battle. That's the way of battle. A real warrior doesn't dash off in pursuit of the next victory, nor throw a fit when experiencing a loss. A real warrior ponders the next battle.","Man oh man... What is going on today? Challengers coming one right after another. Well, no matter. I am Grimsley of the Elite Four, and I will fulfill my duty to be your opponent.","Whether or not you get to fight at full strength, whether or not luck smiles on you--none of that matters. Only results matter. And a loss is a loss. See, victory shines like a bright light. And right now, you and your Pokémon are shining brilliantly."],	
     			[:LEADER_Karen,"Karen","Well, aren't you good. I like that in a Trainer.","You're no ordinary Trainer to have gotten this far.",1,"Strong Pokémon. Weak Pokémon. That is only the selfish perception of people. Truly skilled Trainers should try to win with the Pokémon they love best. I like your style. You understand what's important.","I am Karen of the Elite Four. How amusing. I love Dark-type Pokémon. I'm known for my overpowering tactics. Think you can take them? Just try to entertain me. Let's go.","Strong Pokémon. Weak Pokémon. That is only the selfish perception of people. Truly skilled Trainers should try to win with the Pokémon they love best. I like your style. You understand what's important."],
     			[:LEADER_Lorelei,"Lorelei","Things shouldn't be this way!","My team did great!",1,"Looks like you've gotten stronger since we last met! Go on ahead. You only got a taste of the Pokémon League's power.","I am Lorelei of the Elite Four. No one can best me when it comes to icy Pokémon. Freezing moves are powerful. Your Pokémon will be at my mercy when they are frozen solid. That's because frozen Pokémon can't do a thing in battle! Hahaha! Are you ready?","I may have lost to you, but I'll never give up on my Ice-type Pokémon! You should aim to win using Pokémon you like best, too!"],
     			[:LEADER_Lucian,"Lucian","I see... It appears you've put me in checkmate.","Hmm... How might I turn this situation to my advantage?",1,"Now then, I can return to the last remaining chapter of my book. Reading allows me to learn from my mistakes. Knowledge keeps me from making more.","Just a moment, please. The book I'm reading has nearly reached its thrilling climax... The hero has obtained a mystic sword and is about to face their final trial... Ah, never mind. Since you've made it this far, I'll put that aside and battle you. Let me see if you'll achieve as much glory as the hero of my book!","Truly outstanding. You took full control of the narrative without a moment's hesitation. Now then, the final page has yet to be written. Go and show us who shall emerge victorious."],
     			[:LEADER_Marshal,"Marshal","Whew! Well done! As your battles continue, aim for even greater heights!","Oh, so strong. That makes my heart dance!",1,"Representing the Pokémon League in the absence of the Champion has been my duty as Alder's student. However, there is nothing as empty as words not backed up by strength. A word in your ear, strong challenger... The other members of the Elite Four are far more powerful than I am. Do not underestimate them!","Greetings, challenger. My name is Marshal. In order to master the art of fighting, I'm training under my mentor, Alder. My mentor sees your potential as a Trainer and is taking an interest in you. It is my intention to test you--to take you to the limits of your strength. Kiai!","There is no single strongest Pokémon or sole best combination... That's why it is difficult to keep winning. However, I think a heart that desires strength and strives to grow stronger is a precious ideal. That is why I respect you because you have these things."],
     			[:LEADER_Shauntal,"Shauntal","Wow. I'm dumbstruck! I know a lot of words, but right now I can't figure out how to say this. Perhaps, if the feeling I'm having now is put into words, it will be trapped there. So let me say this... My feeling is you're a great Trainer!","Beginnings are important, whether in a good novel or a good battle!",1,"Every person who works with Pokémon has a Pokémon story to tell. I've found that stories where people and Pokémon help each other out are far more interesting than stories about only people, or only Pokémon!","Eyes brimming with dark flame, this man rejected everything other than himself in order to bring about one singular justice...' That's part of a novel I'm writing. I was inspired by the challenger who was just here, and somehow I got a little sad... Excuse me. You're a challenger, right? I'm the Elite Four's Ghost-type Pokémon user, Shauntal, and I shall be your opponent.","S-sorry! First, I must apologize to my Pokémon... I'm really sorry you had a bad experience because of me! Oh! It's not your fault! This is how battles always are. Even in light of that, I'm still one of the Elite Four!"],
				[:LEADER_Caitlin,"Caitlin","As a Trainer, you are both excellent and elegant. Your Pokémon have class. I am very pleased to have battled you.","Yawn... Was that it?",1,"I am also the Elite 4 Member of the Unova Region, but I still try to make time at the Frontier.","Who are you? How impudent you are to disturb my sleep. Hmf... You appear to possess a combination of strength and kindness. Very well. Make your best effort not to bore me with a yawn-inducing battle. Clear? I Caitlin of the Sinnoh Battle Castle now will challenges you to battle!","In the past, when I battled, the force of my emotions shook me greatly. When my power awoke, I came close to destroying everything around me. That weak person no longer exists... Still, sometimes, my determination fails. Always, I aspire to wrap up a victory with elegance and grace. I invite you to be my opponent again in the future, if you wish"]			
               ],
  :rules_proc => proc {|length|
    rules = PokemonChallengeRules.new
    rules.addPokemonRule(BannedSpeciesRestriction.new(:MEWTWO,:MEW,:HOOH,:LUGIA,:CELEBI,:KYOGRE,:GROUDON,:RAYQUAZA,
                                                      :DEOXYS,:JIRACHI,:DIALGA,:PALKIA,:GIRATINA,:REGIGIGAS,:HEATRAN,:DARKRAI,
                                                      :SHAYMIN,:ARCEUS,:ZEKROM,:RESHIRAM,:KYUREM,:LANDORUS,:MELOETTA,
                                                      :KELDEO,:GENESECT))
    rules.addPokemonRule(NonEggRestriction.new)
    rules.addPokemonRule(AblePokemonRestriction.new)
    rules.setNumber(length)
    rules.setLevelAdjustment(FixedLevelAdjustment.new(50))
    next rules
  },
  :banned_proc => proc {
    pbMessage(_INTL("Certain exotic species, as well as eggs, are ineligible.\\1"))
  },
  :points_won => 2
})

GameData::PWTTournament.register({
  :id => :Champion_leaders,
  :name => _INTL("Champions"),
  :trainers => [
     			[:LEADER_Lance,"Lance","But it's an odd feeling. I'm not angry that I lost. In fact, I feel happy. Happy that I witnessed the rise of a great new Champion!","I never give up, no matter what. You must be the same?",1,"I'm sure you already know this, but dragons are sacred and legendary creatures! That's why I won't lose next time!","There's no need for words now. We will battle to determine who is the stronger of the two of us. I, Lance the Dragon-type master, accept your challenge!","But it's an odd feeling. I'm not angry that I lost. In fact, I feel happy. Happy that I witnessed the rise of a great new Champion!"],
     			[:LEADER_Wallace,"Wallace","That was wonderful work. You were elegant--infuriatingly so. And you know, it was utterly glorious!","I've shown you plenty of the water illusions performed by me and my Pokémon!",1,"The reason for my defeat… It's… The grand illusion of water! It wasn't enough!","At times your Pokémon should dance like a spring breeze, and at times they should strike like lightning. I want to feel bedazzled by your masterful performance!","Bravo! Everyone has now seen your authenticity and magnificence as a Pokémon Trainer. I find much joy in having met you and your Pokémon."],
     			[:LEADER_Cynthia,"Cynthia","Aww! No matter how fun the battle is, it will always end sometime...","What's necessary to become stronger? I think it's important to never lose your love of Pokémon.",1,"I sincerely applaud your victory in the tournament. However, there must be many other strong opponents in the world... I want to keep meeting many different people and Pokémon in other places.","When you are facing a Trainer in battle, you can learn everything about them. What Pokémon they have. What moves they've taught. What items they make their Pokémon hold. There's no need for words then.","That was excellent. Truly, an outstanding battle. Aiden was right about you! You gave the support your Pokémon needed to maximize their power. And you guided them with certainty to secure victory."],
     			[:LEADER_Leon,"Leon","Aww! No matter how fun the battle is, it will always end sometime...","What's necessary to become stronger? I think it's important to never lose your love of Pokémon.",1,"The strong desire to win! That's the trigger that makes you accumulate new skills and transform experience into strength! And you and your team you've got a real great desire to win, don't you! Love it! But you still haven't seen the real challenge the Battle Frontier here is waiting to throw at you!","I've been waiting for you. Always knew you'd be able to win your way here. Now, how about you take on Challenger Leon with everything that you've got?","Battling against a Champion like you... It really is the best... And since you managed to defeat me, you'll be moving up the ranks here soon!"],
     			[:LEADER_Blue,"Blue","How the heck did I lose to you?","This is what I, Kanto's top-level Trainer, can really do!",1,"Three wins and you've done it! Luck can also be a factor, and I'm still not satisfied at all! Oh, I didn't think you won because of luck, though!","I'll know if you are good or not by battling you right now. Will you be as strong as him?","You're the real deal. You are a good Trainer. But I'm going to beat you someday. Don't you forget it! Smell yah later!"],	
     			[:LEADER_Mustard,"Mustard","That was everything I hoped for and more!","We've finally reached the tippy-top!",1,"Fuhaha! I held absolutely nothing back, and yet you still defeated me! The apprentice surpasses his master... A true moment of pride. You should call me master?","Why, hello there! My name is Mustard! I'm rather good at Pokémon battles, you know! I'm pleased as cheese that you could join us!","The way you battle really shows me how much you care about your Pokémon! Even if you've come because of a misunderstanding, as long as you have a will to learn... then you're welcome at the Master Dojo! I think we can all help each other become stronger! I'm happy you've come to join us!"],	
     			[:LEADER_Geeta,"Geeta","Such overwhelming power… Such amazing skill…","Such overwhelming power… Such amazing skill…",1,"Magnificent as always. I see you've continued to hone your skills. That settles it for me. I no longer have any doubts about my decision.","I am utterly incapable of holding back when it comes to Pokémon battles. Maybe that’s why nobody’s passed this test recently. It’s a bit of a problem, to be honest. I want to see the true measure of your talent!","Congratulations. It’s my honor to call you Champion. May this light shine forever..."],	
     			[:LEADER_Alder,"Alder","Well done! You certainly are an unmatched talent!","That was an extraordinary effort from both you and your Pokémon!",1,"Well done! That was an impressive battle. The spirit of my first partner, Larvesta - no, Volcarona - lives on in my current partners, too! I want to add your strength to their experience as well!","I feel fired up when I see another Trainer, and I imagine which one of us is stronger. When I actually face that Trainer, the excitement builds to fever pitch!","Well done! The ones who change the world are always the ones who pursued their dreams. That's right! They're just like you."],
     			[:LEADER_Iris,"Iris","The pain of my Pokémon... I feel it, too!","My team did great!",1,"Know what? I really look forward to having serious battles with strong Trainers! I mean, come on! The Trainers who make it here are Trainers who desire victory with every fiber of their being! And they are battling alongside Pokémon that have been through countless difficult battles! If I battle with people like that, not only will I get stronger, my Pokémon will, too! And we'll get to know each other even better!","OK! Brace yourself! I'm Iris, the Pokémon League Champion of Unova, and I'm going to defeat you!","I'm upset I couldn't win! But you know what? More than that, I'm happy! I mean, come on. By having a serious battle, you and your Pokémon, and me and my Pokémon, we all got to know one another better than before! Yep, we sure did! OK, let's go!"],
     			[:LEADER_Diantha,"Diantha","Witnessing the noble spirits of you and your Pokémon in battle has really touched my heart...","Excellent! I can feel the fire of your convictions burning deep within your heart even if you lost!",1,"Oh, fantastic! What did you think? My team was pretty cool, right? It's a bit embarrassing to show off, but I love to show their best sides!","Oh my! I never thought I would meet you here! Honestly, I didn't! Oh, but--silly me--I should at least do these things right… As Champion and as Grand Duchess of the Battle Chateau, I, Diantha, challenge you.","I just...I just don't know what to say... I can hardly express this feeling... But I'm so glad I got to be Champion and Grand Duchess... Battling you and your Pokémon makes everything seem worth it!"],
     			[:LEADER_Kukui,"Kukui","Discovery! New experiences! Adventure! It's all yours if you want it!","The masked royale strikes again!",1,"That was great fun, oh yeah! Let's do it again sometime!","Hey there, cousin! I'm Kukui a Pokémon Professor researching moves. So of course I love Pokémon battles! Oh yeah!","The mask royale commends you on a splendid victory!"]			
               ],
  :rules_proc => proc {|length|
    rules = PokemonChallengeRules.new
    rules.addPokemonRule(BannedSpeciesRestriction.new(:MEWTWO,:MEW,:HOOH,:LUGIA,:CELEBI,:KYOGRE,:GROUDON,:RAYQUAZA,
                                                      :DEOXYS,:JIRACHI,:DIALGA,:PALKIA,:GIRATINA,:REGIGIGAS,:HEATRAN,:DARKRAI,
                                                      :SHAYMIN,:ARCEUS,:ZEKROM,:RESHIRAM,:KYUREM,:LANDORUS,:MELOETTA,
                                                      :KELDEO,:GENESECT))
    rules.addPokemonRule(NonEggRestriction.new)
    rules.addPokemonRule(AblePokemonRestriction.new)
    rules.setNumber(length)
    rules.setLevelAdjustment(FixedLevelAdjustment.new(50))
    next rules
  },
  :banned_proc => proc {
    pbMessage(_INTL("Certain exotic species, as well as eggs, are ineligible.\\1"))
  },
  :points_won => 2
})


GameData::PWTTournament.register({
  :id => :Frontier_leaders,
  :name => _INTL("Frontier Brains"),
  :trainers => [
                [:LEADER_Greta,"Greta","No way! Good job!","I never give up, no matter what. You must be the same?",1,"Oh, come on! You have to try harder than that!","I am Greta the Frontier Brain the Battle Arena. I don't know how to say it, but... To put it bluntly, you look pretty weak. Are you sure you're up for me? Hmm... Well, all right! We'll take things easy to start with! Okay! Let's see you ignite my passion for battle!","Arrrgh! This is so infuriating! If we ever battle again, I won't lose! Don't you forget it! Bye bye!"],
				[:LEADER_Lucy,"Lucy","Urk...","Humph...",1,"Oh, come on! You have to try harder than that!","I am Lucy... I am the law here... For I am the Pike Queen... You already know it, but to advance, you must defeat me... ...I'm not one for idle chatter. Hurry. Come on... Your luck... I hope you didn't use it all up here...","You, I won't forget... ...Ever..."],
				[:LEADER_Noland,"Noland","What happened here?","Hey, hey, hey! You're finished already?",1,"I am surprised at how strong you were. Why not test your skills at the Battle Factory?!","I am the Frontier Brain of the Battle Factory. Name is Noland. How's it going? You keeping up with your studies? ...Oh? You've taken on a harder look than the last time I saw you. Now, this should be fun! I'm getting excited, hey! All right! Bring it on!","Pfft, man! That's absolutely the last time I lose to you! We have to do this again, hey!"],
                [:LEADER_Spencer,"Spencer","Ah... Now this is something else...","Your Pokémon are wimpy because you're wimpy as a Trainer!",1,"If its just me dont tell the others the Battle Palace is the most fabulous facility here. Why don't you go check it out?","My name is Spencer the Frontier Brain of the Battle Palace. My physical being is with Pokémon always! My heart beats as one with Pokémon always! Young one of a Trainer! Do you believe in your Pokémon? Can you believe them through and through? If your bonds of trust are frail, you will never beat my brethren! The bond you share with your Pokémon! Prove it to me here!","Gwahahah! Hah, you never fell for my bluster! Sorry for trying that stunt! Your Pokémon's eyes are truly clear and unclouded. I will eagerly await the next opportunity to see you."],
				[:LEADER_Tucker,"Tucker","Ahahaha! You're inspiring!","My Dome Ace title isn't just for show!",1,"This is what I, Kanto's top-level Trainer, can really do!","Ahahah! Do you hear it? This crowd! They're all itching to see our match! Ahahah! I bet you're twitching all over from the tension of getting to battle me! But don't worry about a thing! I'm the no. 1 star here!","You're strong, but above all, you have a unique charm! In you, I see a definite potential for a superstar like me. I will very much look forward to our next encounter!"],
				[:LEADER_Anabel,"Anabel","Okay, I understand...","My Dome Ace title isn't just for show!",1,"My name is Anabel. I am the Salon Maiden, and I am in charge of running the Battle Tower... Have you checked it out yet?","Greetings... My name is Anabel. I am the Salon Maiden, and I am in charge of running the Battle Tower... I have heard several rumors about you... In all honesty, what I have heard does not seem attractive in any way... The reason I've come to see you... Well, there is but one reason... Let me see your talent in its entirety...","That was fun... I have never had a Pokémon battle so enjoyable before... I wish I could battle with you again.."],
				[:LEADER_Argenta,"Argenta","It's so sad how the truly fun times seem to last only a moment.","I'm prepared to go on stage anytime!",1,"Well! My goodness, your Pokémon... It's got star power beyond belief. Even from inside its Poké Ball, I can feel its charismatic brilliance.","Well! My goodness, your Pokémon... It's got star power beyond belief. Even from inside its Poké Ball, I can feel its charismatic brilliance. But I'm the Hall Matron of the Sinnoh Battle Frontier. I'll be the judge of that. I must battle it for myself and see if that brilliance is genuine. That is why we must battle now.","You must never forget there is a place where everyone can shine. That goes for any kind of Pokémon, too. Spread that message in your own words. It's one everyone should hear. And now, having lost, this lady has nothing left to say at all, but... Bye-bye!"],
				[:LEADER_Thorton,"Thorton","Whoa! You sure showed me!","Whoa! I sure showed me!",1,"Whoa! You sure showed me!","Greetings... My name is Thorton Factory Head of the Sinnoh Battle Frontier. Bzweeeeep! Let's see what I can see about you through my data-analyzing machine. Hmm Interesting. I guess we should battle to truly find out!","Hmm... I got handed another loss. It's not making me happy at all, this. In fact, I'm stewing here. I thought I learned a lot about Pokémon since I lost to you. But that's all right. Some things you learn from winning. But some things you learn by losing. I hope you'll keep renting our Pokémon and give me a chance to redeem myself!"],
				[:LEADER_Caitlin,"Caitlin","As a Trainer, you are both excellent and elegant. Your Pokémon have class. I am very pleased to have battled you.","Yawn... Was that it?",1,"I am also the Elite 4 Member of the Unova Region, but I still try to make time at the Frontier.","Who are you? How impudent you are to disturb my sleep. Hmf... You appear to possess a combination of strength and kindness. Very well. Make your best effort not to bore me with a yawn-inducing battle. Clear? I Caitlin of the Sinnoh Battle Castle now will challenges you to battle!","In the past, when I battled, the force of my emotions shook me greatly. When my power awoke, I came close to destroying everything around me. That weak person no longer exists... Still, sometimes, my determination fails. Always, I aspire to wrap up a victory with elegance and grace. I invite you to be my opponent again in the future, if you wish"],
				[:LEADER_Dahlia,"Dahlia","Battling a wonderful Trainer is always a happy occasion!","Today I win. Maybe next time it will be your turn.",1,"Battling a wonderful Trainer is always a happy occasion!","I am the Arcade Star Dahlia! No need to worry. ♪ Let chance do what it does. Like surprises from the game board, life goes through twists and turns. No need to worry. ♪ Things will go as they will. But, enough of that. You are proving yourself incredible. Are you incredible because you are so lucky you shrug off bad luck entirely? Or, are you so incredibly talented to not be swayed by luck, good or bad? I wish to see for myself what brought you to me today!","Truly, it was so very fabulous of all of you! Bad luck, you cast aside, and good luck, you netted. That you did so is evidence of your abilities. By defeating me, Dahlia, you have proven your mastery brilliantly! I am sincerely happy for having this battle against you!"],
				[:LEADER_Palmer,"Palmer","Losing to an outstanding Trainer like you... I can live with that.","There is a reason I am the strongest Frontier Brain!",1,"You will become even more skilled. Keep battling Trainers from around the world and keep growing greater in stature!","So, you've come this so far! As the Tower Tycoon, I'll have to give you my best effort. That's how the best Trainers show respect to each other. By Battling all out as dedicated students of Pokémon!","Bravo! I imagine many great Trainers will come to challenge me as you have just done. That's something I look forward to a great deal. You will become even more skilled. Keep battling Trainers from around the world and keep growing greater in stature!"],				
				[:LEADER_Brandon,"Brandon","That's it! You've done it! You kept working for this!","Hey! Don't give up now! Get up! Don't lose faith in yourself!",1,"Hey! Don't give up now! Get up! Don't lose faith in yourself!","Young adventurer... Wouldn't you agree that explorations are the grandest of adventures? Your own wits! Your own strength! Your own Pokémon! And, above all, only your courage to lead you through unknown worlds... Aah, yes, indeed this life is grand! Grand, it is! Eh? I'm Brandon. I'm the Pyramid King, which means I'm in charge here. Most people call me the chief! You coming here means you have that much confidence in yourself, am I right? Hahahah! This should be exciting! Now, then! Bring your courage to our battle!","Hahahah! Remarkable! Yes, it's grand, indeed! Young explorer! You've bested me through and through! Here! I want you to have this!"] 				
               ],
  :rules_proc => proc {|length|
    rules = PokemonChallengeRules.new
    rules.addPokemonRule(BannedSpeciesRestriction.new(:MEWTWO,:MEW,:HOOH,:LUGIA,:CELEBI,:KYOGRE,:GROUDON,:RAYQUAZA,
                                                      :DEOXYS,:JIRACHI,:DIALGA,:PALKIA,:GIRATINA,:REGIGIGAS,:HEATRAN,:DARKRAI,
                                                      :SHAYMIN,:ARCEUS,:ZEKROM,:RESHIRAM,:KYUREM,:LANDORUS,:MELOETTA,
                                                      :KELDEO,:GENESECT))
    rules.addPokemonRule(NonEggRestriction.new)
    rules.addPokemonRule(AblePokemonRestriction.new)
    rules.setNumber(length)
    rules.setLevelAdjustment(FixedLevelAdjustment.new(50))
    next rules
  },
  :banned_proc => proc {
    pbMessage(_INTL("Certain exotic species, as well as eggs, are ineligible.\\1"))
  },
  :points_won => 2
})

GameData::PWTTournament.register({
  :id => :Male_protags,
  :name => _INTL("Male Protags"),
  :trainers => [
				[:LEADER_Red,"Red","...","...",1,"...","...","..."],
				[:LEADER_Wes,"Wes","...","...",1,"...","...","..."],
     			[:LEADER_Gold,"Gold","That was wonderful work.","My prior journey helped aid in my win!",1,"I am more reckless and stubborn than Red.","I grew up in New Bark Town... Allow me to show you what I'm capable of!","You remind me of the battle I had with Red ontop Mt. Silver..."],
     			[:LEADER_Lucas,"Lucas","I lost!","What's necessary to become stronger? I think it's important to never lose your love of Pokémon.",1,"I sincerely applaud your victory in the tournament. However, there must be many other strong opponents in the world... I want to keep meeting many different people and Pokémon in other places.","My friends also call me Diamond. I will show you what I've learned!","That was a great battle!"],
     			[:LEADER_Hilbert,"Hilbert","Aww! No matter how fun the battle is, it will always end sometime...","What's necessary to become stronger? I think it's important to never lose your love of Pokémon.",1,"The strong desire to win! That's the trigger that makes you accumulate new skills and transform experience into strength! And you and your team you've got a real great desire to win, don't you! Love it! But you still haven't seen the real challenge the Battle Frontier here is waiting to throw at you!","I've been waiting for you. Me and my Pokemon are ready for battle!","Battling against a Champion like you... It really is the best... And since you managed to defeat me, you'll be moving up the ranks here soon!"],
     			[:LEADER_Nate,"Nate","How the heck did I lose to you?","This is what I, a top tier Detective, can really do!",1,"Three wins and you've done it! Luck can also be a factor, and I'm still not satisfied at all! Oh, I didn't think you won because of luck, though!","I am a member of the international Police. Ever since they found me as an infant all those years ago...","Hugh told me to stop flirting with girls. It seems I need to get stronger..."],	
     			[:LEADER_Calem,"Calem","That was everything I hoped for and more!","We've finally reached the tippy-top!",1,"Back in the day I took part in the junior Kalos cup and won. That's why I became a shut in...","I have been strong ever since I was a child. I shall wield Mega Evolution to my victory!","I became a shut in due to the people who wouldn't stop bothering me. The years of me secluding myself gave me the title of Loner."],	
     			[:LEADER_Elio,"Elio","Such overwhelming power... Such amazing skill...","Such overwhelming power… Such amazing skill…",1,"Magnificent as always. I see you've continued to hone your skills. That settles it for me. I no longer have any doubts about my decision.","I am originally from Cinabar Island, however I moved to Aloha later. My goal was to pay back 100 Million Yen to buy back the island from Faba!","Congratulations. It’s my honor to call you Champion. May this light shine forever..."],	
     			[:LEADER_Victor,"Victor","Well done! You certainly are an unmatched talent!","That was an extraordinary effort from both you and your Pokémon!",1,"Well done! That was an impressive battle. Maybe you should help Magnolia too!","I helped Prof. Magnolia with Dynamax energy. Let's see how much I've learned!","Well done! The ones who change the world are always the ones who pursued their dreams. That's right! They're just like you."],
     			[:LEADER_Florian,"Florian","Discovery! New experiences! Adventure! It's all yours if you want it!","The PRINCE OF SPEED strikes again!",1,"That was great fun, oh yeah! Let's do it again sometime!","I call myself Paldea's PRINCE OF SPEED because I aspire to be the fasted in the region. I am also heir to the prestigous lang family!","I only enrolled at the academy because of my parents. I would rather spend my extra time becoming faster! However you did win. Congratulations!"]			
               ],
  :rules_proc => proc {|length|
    rules = PokemonChallengeRules.new
    rules.addPokemonRule(BannedSpeciesRestriction.new(:MEWTWO,:MEW,:HOOH,:LUGIA,:CELEBI,:KYOGRE,:GROUDON,:RAYQUAZA,
                                                      :DEOXYS,:JIRACHI,:DIALGA,:PALKIA,:GIRATINA,:REGIGIGAS,:HEATRAN,:DARKRAI,
                                                      :SHAYMIN,:ARCEUS,:ZEKROM,:RESHIRAM,:KYUREM,:LANDORUS,:MELOETTA,
                                                      :KELDEO,:GENESECT))
    rules.addPokemonRule(NonEggRestriction.new)
    rules.addPokemonRule(AblePokemonRestriction.new)
    rules.setNumber(length)
    rules.setLevelAdjustment(FixedLevelAdjustment.new(50))
    next rules
  },
  :banned_proc => proc {
    pbMessage(_INTL("Certain exotic species, as well as eggs, are ineligible.\\1"))
  },
  :points_won => 2
})

GameData::PWTTournament.register({
  :id => :Female_protags,
  :name => _INTL("Female Protags"),
  :trainers => [
     			[:LEADER_Leaf,"Leaf","No way? I lost to someone other than Red?","My prior journey helped aid in my win!",1,"I am more reckless and stubborn than Red.","One time I sold Red a bunch of useless junk. He was so naive back than... I loved that...","I still admire Red. Once he left for Mt. Silver life has been so boring."],
     			[:LEADER_Lyra,"Lyra","That was wonderful work.","My prior journey helped aid in my win!",1,"I am more reckless and stubborn than Red.","I grew up in New Bark Town... Allow me to show you what I'm capable of!","You remind me of the battles I had with Gold growing up!"],
     			[:LEADER_Kris,"Kris","I lost!","What's necessary to become stronger? I think it's important to never lose your love of Pokémon.",1,"I sincerely applaud your victory in the tournament. However, there must be many other strong opponents in the world... I want to keep meeting many different people and Pokémon in other places.","My dream is to find Suicune. Maybe someday.","That was a great battle!"],
     			[:LEADER_Dawn,"Dawn","Aww!","What's necessary to become stronger? I think it's important to never lose your love of Pokémon.",1,"The Sinnoh Region also has a Battle Frontier. Which one is better?","I work as an assitant of Prof. Rowan. I have learned many valuables things including how to battle!","I wonder who is stronger... You or Lucas?"],
     			[:LEADER_Hilda,"Hilda","Your pretty powerful!","This is what I can do.",1,"Three wins and you've done it! Luck can also be a factor, and I'm still not satisfied at all! Oh, I didn't think you won because of luck, though!","Everyone here talks about Red... What about us? At least speak of Hilbert!","Maybe people should start talking more about you."],	
     			[:LEADER_Rosa,"Rosa","That was everything I hoped for and more!","We've finally reached the tippy-top!",1,"I am going to use what I learn here and make my career at Pokestar Studios work.","I want to work at Pokestar Studios. I will play... Foongus Girl!","This was a great experience. Thanks a bunch!"],	
     			[:LEADER_Serena,"Serena","So, I lost, then...","So, I won, then...",1,"It was so strong! I could feel how powerful the bond between you and your partner is. Losing is frustrating, but... You will definitely be able to Mega Evolve your Pokémon! I'm sure of it!","I feel that being different from others makes me special. Mastering Mega Evolution will definitely set me apart from other trainers!","It sure is interesting to see how different each Trainer's style is."],
     			[:LEADER_Selene,"Selene","I'm fired up to the max!","I'm fired up to the max!",1,"You can become friends with anyone, really. It just takes time!","Alola! I'm Selene! I'll show you a bond that shines bright even through the night!","Alola, alola! Isn't that a fun word to say? C'mon, say it with me!"],
     			[:LEADER_Gloria,"Gloria","So, I lost, then...","We've never shone so brightly!",1,"It was so strong! I could feel how powerful the bond between you and your partner is. Losing is frustrating, but... You will definitely be able to Mega Evolve your Pokémon! I'm sure of it!","Hullo! I'm Gloria! I'm from a small town in Galar called Postwick! Pleased to meetcha! Whether it's Pokémon battles or setting up camp, I've got you covered! Now then, onward to adventure!","To shine brighter is what I want..."],				
     			[:LEADER_Juliana,"Juliana","Discovery! New experiences! Adventure! It's all yours if you want it!","The PRINCESS OF SPEED strikes again!",1,"That was great fun, oh yeah! Let's do it again sometime!","I attend and learn at Naranja Academy. Let me show you what I've learned!","Congratulations!"]			
               ],
  :rules_proc => proc {|length|
    rules = PokemonChallengeRules.new
    rules.addPokemonRule(BannedSpeciesRestriction.new(:MEWTWO,:MEW,:HOOH,:LUGIA,:CELEBI,:KYOGRE,:GROUDON,:RAYQUAZA,
                                                      :DEOXYS,:JIRACHI,:DIALGA,:PALKIA,:GIRATINA,:REGIGIGAS,:HEATRAN,:DARKRAI,
                                                      :SHAYMIN,:ARCEUS,:ZEKROM,:RESHIRAM,:KYUREM,:LANDORUS,:MELOETTA,
                                                      :KELDEO,:GENESECT))
    rules.addPokemonRule(NonEggRestriction.new)
    rules.addPokemonRule(AblePokemonRestriction.new)
    rules.setNumber(length)
    rules.setLevelAdjustment(FixedLevelAdjustment.new(50))
    next rules
  },
  :banned_proc => proc {
    pbMessage(_INTL("Certain exotic species, as well as eggs, are ineligible.\\1"))
  },
  :points_won => 2
})


