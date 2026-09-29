module QuestModule
  
  # You don't actually need to add any information, but the respective fields in the UI will be blank or "???"
  # I included this here mostly as an example of what not to do, but also to show it's a thing that exists
  Quest0 = {
  
  }
  
  # Here's the simplest example of a single-stage quest with everything specified
  Quest1 = {
    :ID => "1",
    :Name => "Introductions",
    :QuestGiver => "Little Boy",
    :Stage1 => "Look for clues.",
    :Location1 => "Lappet Town",
    :QuestDescription => "Some wild Pokémon stole a little boy's favourite toy. Find those troublemakers and help him get it back.",
    :RewardString => "Something shiny!"
  }
  
  # Here's an extension of the above that includes multiple stages
  Quest2 = {
    :ID => "2",
    :Name => "Introductions",
    :QuestGiver => "Little Boy",
    :Stage1 => "Look for clues.",
    :Stage2 => "Follow the trail.",
    :Stage3 => "Catch the troublemakers!",
    :Location1 => "Lappet Town",
    :Location2 => "Viridian Forest",
    :Location3 => "Route 3",
	:StageLabel1 => "1",
	:StageLabel2 => "2",
    :QuestDescription => "Some wild Pokémon stole a little boy's favourite toy. Find those troublemakers and help him get it back.",
    :RewardString => "Something shiny!"
  }
  
  # Here's an example of a quest with lots of stages that also doesn't have a stage location defined for every stage
  Quest3 = {
    :ID => "3",
    :Name => "Last-minute chores",
    :QuestGiver => "Grandma",
    :Stage1 => "A",
    :Stage2 => "B",
    :Stage3 => "C",
    :Stage4 => "D",
    :Stage5 => "E",
    :Stage6 => "F",
    :Stage7 => "G",
    :Stage8 => "H",
    :Stage9 => "I",
    :Stage10 => "J",
    :Stage11 => "K",
    :Stage12 => "L",
    :Location1 => "nil",
    :Location2 => "nil",
    :Location3 => "Dewford Town",
    :QuestDescription => "Isn't the alphabet longer than this?",
    :RewardString => "Chicken soup!"
  }
  
  # Here's an example of not defining the quest giver and reward text
  Quest4 = {
    :ID => "4",
    :Name => "A new beginning",
    :QuestGiver => "nil",
    :Stage1 => "Turning over a new leaf... literally!",
    :Stage2 => "Help your neighbours.",
    :Location1 => "Milky Way",
    :Location2 => "nil",
    :QuestDescription => "You crash landed on an alien planet. There are other humans here and they look hungry...",
    :RewardString => "nil"
  }
  
  # Other random examples you can look at if you want to fill out the UI and check out the page scrolling
  Quest5 = {
    :ID => "5",
    :Name => "All of my friends",
    :QuestGiver => "Barry",
    :Stage1 => "Meet your friends near Acuity Lake.",
    :QuestDescription => "Barry told me that he saw something cool at Acuity Lake and that I should go see. I hope it's not another trick.",
    :RewardString => "You win nothing for giving in to peer pressure."
  }
  
  Quest6 = {
    :ID => "6",
    :Name => "The journey begins",
    :QuestGiver => "Professor Oak",
    :Stage1 => "Deliver the parcel to the Pokémon Mart in Viridian City.",
    :Stage2 => "Return to the Professor.",
    :Location1 => "Viridian City",
    :Location2 => "nil",
    :QuestDescription => "The Professor has entrusted me with an important delivery for the Viridian City Pokémon Mart. This is my first task, best not mess it up!",
    :RewardString => "nil"
  }
  
  Quest7 = {
    :ID => "7",
    :Name => "Close encounters of the... first kind?",
    :QuestGiver => "nil",
    :Stage1 => "Make contact with the strange creatures.",
    :Location1 => "Rock Tunnel",
    :QuestDescription => "A sudden burst of light, and then...! What are you?",
    :RewardString => "A possible probing."
  }
  
  Quest8 = {
    :ID => "8",
    :Name => "These boots were made for walking",
    :QuestGiver => "Musician #1",
    :Stage1 => "Listen to the musician's, uhh, music.",
    :Stage2 => "Find the source of the power outage.",
    :Location1 => "nil",
    :Location2 => "Celadon City Sewers",
    :QuestDescription => "A musician was feeling down because he thinks no one likes his music. I should help him drum up some business."
  }
  
  Quest9 = {
    :ID => "9",
    :Name => "Got any grapes?",
    :QuestGiver => "Duck",
    :Stage1 => "Listen to The Duck Song.",
    :Stage2 => "Try not to sing it all day.",
    :Location1 => "YouTube",
    :QuestDescription => "Let's try to revive old memes by listening to this funny song about a duck wanting grapes.",
    :RewardString => "A loss of braincells. Hurray!"
  }
  
  Quest10 = {
    :ID => "10",
    :Name => "Singing in the rain",
    :QuestGiver => "Some old dude",
    :Stage1 => "I've run out of things to write.",
    :Stage2 => "If you're reading this, I hope you have a great day!",
    :Location1 => "Somewhere prone to rain?",
    :QuestDescription => "Whatever you want it to be.",
    :RewardString => "Wet clothes."
  }
  
  Quest11 = {
    :ID => "11",
    :Name => "When is this list going to end?",
    :QuestGiver => "Me",
    :Stage1 => "When IS this list going to end?",
    :Stage2 => "123",
    :Stage3 => "456",
    :Stage4 => "789",
    :QuestDescription => "I'm losing my sanity.",
    :RewardString => "nil"
  }
  
  Quest12 = {
    :ID => "12",
    :Name => "The laaast melon",
    :QuestGiver => "Some stupid dodo",
    :Stage1 => "Fight for the last of the food.",
    :Stage2 => "Don't die.",
    :Location1 => "A volcano/cliff thing?",
    :Location2 => "Good advice for life.",
    :QuestDescription => "Tea and biscuits, anyone?",
    :RewardString => "Food, glorious food!"
  }
  
	Quest13 = {
	  :ID => "13",
	  :Name => "Where Is My Lotad?",
	  :QuestGiver => "Jimmy",
	  :Stage1 => "Please find Lotad.",
	  :Location1 => "Dewford Town",
	  :QuestDescription => "I lost my Lotad earlier today. Can you please find it for me?",
	  :RewardString => "5 Fresh Waters"
	}
  
	Quest14 = {
	  :ID => "14",
	  :Name => "Catch Me a Joltik!",
	  :QuestGiver => "Arnold",
	  :Stage1 => "Please find me a Joltik in Granite Cave.",
	  :Location1 => "Granite Cave",
	  :QuestDescription => "I've been looking everywhere for a Joltik in Granite Cave, but it won't appear for me. Could you catch one and trade it to me?",
	  :RewardString => "???"
	}
  
	Quest15 = {
	  :ID => "15",
	  :Name => "Save the Professor!",
	  :QuestGiver => "Birch",
	  :Stage1 => "Save the professor.",
	  :Location1 => "Route 101",
	  :QuestDescription => "Save the professor from the Zigzagoon.",
	  :RewardString => "Starter Pokémon"
	}
  
	Quest16 = {
	  :ID => "16",
	  :Name => "Meet Up with the Assistant",
	  :QuestGiver => "Birch",
	  :Stage1 => "Meet up with Birch's assistant.",
	  :Location1 => "Route 103",
	  :QuestDescription => "Meet up with Professor Birch's assistant on Route 103.",
	  :RewardString => "Pokédex"
	}
  
	Quest17 = {
	  :ID => "17",
	  :Name => "Poochyena, Where Are You?",
	  :QuestGiver => "Thomas",
	  :Stage1 => "Find Poochyena.",
	  :Location1 => "Route 103",
	  :QuestDescription => "My Poochyena and I went for a walk and got separated. Please find him for me.",
	  :RewardString => "TM103 - Howl"
	}
  
  
	Quest18 = {
	  :ID => "18",
	  :Name => "Challenge Roxanne",
	  :QuestGiver => "Norman",
	  :Stage1 => "Battle the first Gym Leader.",
	  :Location1 => "Rustboro City",
	  :QuestDescription => "Head to Rustboro City and defeat Roxanne.",
	  :RewardString => "First Gym Badge"
	}
  
   
	Quest19 = {
	  :ID => "19",
	  :Name => "Confess My Feelings to Him",
	  :QuestGiver => "Samantha",
	  :Stage1 => "Help Samantha confess her feelings.",
	  :Location1 => "Trainer School",
	  :QuestDescription => "I am in love with my childhood friend Timothy, and I want to confess my feelings to him, but I don't know how. Would you do it for me?",
	  :RewardString => "Munna"
	} 

	Quest20 = {
	  :ID => "20",
	  :Name => "Get the Devon Goods Back!",
	  :QuestGiver => "Devon Employee",
	  :Stage1 => "Get the Devon Goods back.",
	  :Location1 => "Rusturf Tunnel",
	  :QuestDescription => "A Team Aqua Grunt stole the Devon Goods. Please get them back.",
	  :RewardString => "Great Ball"
	}
  
	Quest21 = {
	  :ID => "21",
	  :Name => "Deliver the Devon Goods",
	  :QuestGiver => "Devon Employee",
	  :Stage1 => "Deliver the Devon Goods.",
	  :Location1 => "Slateport City",
	  :QuestDescription => "Could you please deliver the Devon Goods to the shipyard in Slateport City for me?",
	  :RewardString => "Nothing"
	}
  
	Quest22 = {
	  :ID => "22",
	  :Name => "Deliver a Letter to Steven in Dewford",
	  :QuestGiver => "Mr. Stone",
	  :Stage1 => "Deliver the letter to Steven.",
	  :Location1 => "Dewford Town",
	  :QuestDescription => "Would you please deliver this important letter to my son, Steven, who is currently in Dewford Town?",
	  :RewardString => "Pokégear"
	}
  
	Quest23 = {
	  :ID => "23",
	  :Name => "Help! I Lost My Abra!",
	  :QuestGiver => "Orlando",
	  :Stage1 => "Find Abra.",
	  :Location1 => "Verdanturf Town",
	  :QuestDescription => "I lost my Abra while we were taking a stroll through Rusturf Tunnel. Would you be willing to find it for me?",
	  :RewardString => "Sun Stone"
	}
  
	Quest24 = {
	  :ID => "24",
	  :Name => "Head to Meteor Falls",
	  :QuestGiver => "Aiden",
	  :Stage1 => "Head to Meteor Falls.",
	  :Location1 => "Route 113",
	  :QuestDescription => "Head to Meteor Falls and stop Team Magma.",
	  :RewardString => "Nothing"
	}

	Quest25 = {
	  :ID => "25",
	  :Name => "Stop Team Sky",
	  :QuestGiver => "Aiden",
	  :Stage1 => "Head to Mt. Battle.",
	  :Location1 => "Route 111",
	  :QuestDescription => "Head to Mt. Battle on Route 111 and help Aiden.",
	  :RewardString => "Nothing"
	}
  
	Quest26 = {
	  :ID => "26",
	  :Name => "New Mauville",
	  :QuestGiver => "Wattson",
	  :Stage1 => "Head to New Mauville.",
	  :Location1 => "Route 111",
	  :QuestDescription => "Go to New Mauville and shut off the electricity for me. It's just a short surf from Route 110.",
	  :RewardString => "TM24 - Thunderbolt"
	}

	Quest27 = {
	  :ID => "27",
	  :Name => "Defeat All the Sandygast",
	  :QuestGiver => "Chairman",
	  :Stage1 => "Defeat all the Sandygast!",
	  :Location1 => "Ranger Guild - Route 106",
	  :QuestDescription => "We need help taking down all the Sandygast on Route 106. There are four of them, and we just need proof that they are gone so they will leave our beach alone!",
	  :RewardString => "2 Dive Balls, 2 Super Potions"
	}
  
	Quest28 = {
	  :ID => "28",
	  :Name => "Find My Lost Skitty!",
	  :QuestGiver => "Alice",
	  :Stage1 => "Find my Skitty.",
	  :Location1 => "Ranger Guild - Route 106",
	  :QuestDescription => "I got separated from my Skitty somewhere in Petalburg Woods. I hate bugs with a passion, so could you find her for me? I beg of you.",
	  :RewardString => "$6,000"
	}

	Quest29 = {
	  :ID => "29",
	  :Name => "Will Somebody Catch an Abra for Me?",
	  :QuestGiver => "Angelica",
	  :Stage1 => "Find an Abra and trade it to Angelica.",
	  :Location1 => "Ranger Guild - Route 106",
	  :QuestDescription => "I have always wanted an Abra for myself, but I don't know where to find or catch one. Could somebody please trade me an Abra?",
	  :RewardString => "Pichu"
	}
  
	Quest30 = {
	  :ID => "30",
	  :Name => "The Seashore Robbery",
	  :QuestGiver => "Seashore House Owner",
	  :Stage1 => "Travel to Route 109",
	  :Location1 => "Ranger Guild - Route 106",
	  :QuestDescription => "Someone broke into my Seashore House last night and stole all of my Soda Pops! I can't open until I find them. Will a Ranger come and help me?",
	  :RewardString => "12 Soda Pops"
	}

	Quest31 = {
	  :ID => "31",
	  :Name => "Check Out the Planet",
	  :QuestGiver => "Rayquaza",
	  :Stage1 => "Check the planet.",
	  :Location1 => "Space",
	  :QuestDescription => "Rayquaza seems to have sensed something on this planet. Go take a look at what it might be...",
	  :RewardString => "Nothing"
	}
	Quest32 = {
	  :ID => "32",
	  :Name => "Catch Me an Applin",
	  :QuestGiver => "Drayden",
	  :Stage1 => "Find an Applin and trade it to Drayden.",
	  :Location1 => "Ranger Guild",
	  :QuestDescription => "I am Drayden, a Gym Leader from the Unova region. I am looking for an Applin, but I don't have time to find one myself. I heard you can find one in Mirage Tower in the Route 111 desert. Please find one for me, and I will trade you something special!",
	  :RewardString => "Axew"
	}

	Quest33 = {
	  :ID => "33",
	  :Name => "The Hot Spring's Added Heat",
	  :QuestGiver => "Louis",
	  :Stage1 => "Please investigate the heating issues.",
	  :Location1 => "Lavaridge Hot Springs",
	  :QuestDescription => "The hot springs are even hotter than usual. We are looking for someone to go down and take a look. They shouldn't be this hot, and the customers are complaining a lot...",
	  :RewardString => "???"
	}
  
	Quest34 = {
	  :ID => "34",
	  :Name => "Wingull Show and Tell",
	  :QuestGiver => "Garl",
	  :Stage1 => "Show Garl a Wingull.",
	  :Location1 => "Route 104",
	  :QuestDescription => "I want to see a Wingull one more time before my time is up. I know it's not that rare, but it will remind me of something very important to me...",
	  :RewardString => "Pretty Wing, $1,000"
	}

	Quest35 = {
	  :ID => "35",
	  :Name => "Relicanth Show and Tell",
	  :QuestGiver => "Gideon",
	  :Stage1 => "Show Gideon a Relicanth.",
	  :Location1 => "Pacifidlog Town",
	  :QuestDescription => "I have been enamored by the way Relicanth looks in books and on TV. Can I see one face-to-face? Maybe then it will be solidified as my favorite Pokémon... Otherwise, I can't be quite sure.",
	  :RewardString => "Deep Sea Tooth"
	}
  
	Quest36 = {
	  :ID => "36",
	  :Name => "Hard as Stone",
	  :QuestGiver => "Samuel",
	  :Stage1 => "Give Samuel a Hard Stone.",
	  :Location1 => "Route 116",
	  :QuestDescription => "I'm making some new pickaxes because we've run out. I need a Hard Stone to finish forging them. Please find one for me. I know they can be found in Granite Cave...",
	  :RewardString => "Oval Stone"
	}

	Quest37 = {
	  :ID => "37",
	  :Name => "Strange Rock Sample",
	  :QuestGiver => "Devon Employee",
	  :Stage1 => "Go to Granite Cave and retrieve the rock.",
	  :Location1 => "Devon Corporation",
	  :QuestDescription => "One of our workers found a strange rock sample in Granite Cave earlier today, but he is busy and can't bring it to us. He claims he has never seen anything like it before. Could you find him in the cave and get it from him? Bring it back here so I can research it. What do you say?",
	  :RewardString => "Smooth Rock"
	}
  
	Quest38 = {
	  :ID => "38",
	  :Name => "Poké Doll Escapade",
	  :QuestGiver => "Joey",
	  :Stage1 => "Give Joey a Poké Doll.",
	  :Location1 => "Dewford Town",
	  :QuestDescription => "I collect all kinds of dolls, but I'm missing an important one because my Poochyena tore it to pieces. I need a new Poké Doll! If you have one, could you give it to me?",
	  :RewardString => "$650"
	}

	Quest39 = {
	  :ID => "39",
	  :Name => "Confess My Feelings: Part 2",
	  :QuestGiver => "Timothy",
	  :Stage1 => "Help Timothy get his belongings back.",
	  :Location1 => "Lilycove City",
	  :QuestDescription => "My ex, Erika, whom you briefly saw before, broke things off with me out of the blue. Now I'm stuck here without my wallet. She has the key to my motel room, but I can't face her again after how things went down.",
	  :RewardString => "Nothing"
	}
  
	Quest40 = {
	  :ID => "40",
	  :Name => "Dead Weight",
	  :QuestGiver => "Paul",
	  :Stage1 => "Throw the Magikarp back into the sea.",
	  :Location1 => "Route 108",
	  :QuestDescription => "I caught a bunch of Magikarp all over Route 108. They are too heavy for me to throw back into the sea. Could you please do it for me?",
	  :RewardString => "Pearl"
	}

	Quest41 = {
	  :ID => "41",
	  :Name => "Dead Weight 2",
	  :QuestGiver => "Paul",
	  :Stage1 => "Throw the Magikarp back into the sea!",
	  :Location1 => "Route 125",
	  :QuestDescription => "I caught a bunch of Magikarp once again, this time all over Route 125! They are too heavy for me to throw back into the sea. Could you please do it for me again?",
	  :RewardString => "Big Pearl"
	}
  
	Quest42 = {
	  :ID => "42",
	  :Name => "Cerulean Exchange",
	  :QuestGiver => "Rocket Scientist",
	  :Stage1 => "Find the lost Rocket data.",
	  :Location1 => "Altering Cave",
	  :QuestDescription => "Go inside Cerulean Cave and find the lost data that Team Rocket stored there years ago. I don't know where it is, but it should be somewhere in that dreaded cave!",
	  :RewardString => "Master Ball"
	}

	Quest43 = {
	  :ID => "43",
	  :Name => "Scaled Encounter",
	  :QuestGiver => "Jameson",
	  :Stage1 => "Catch a Feebas.",
	  :Location1 => "Sootopolis City",
	  :QuestDescription => "I've heard of a Secret Shore located somewhere between Route 128 and Route 129. Can you catch a Feebas there for me?",
	  :RewardString => "Prism Scale"
	}
  
	Quest44 = {
	  :ID => "44",
	  :Name => "Battle Theory",
	  :QuestGiver => "DylanCd",
	  :Stage1 => "Complete the Frontier Quiz.",
	  :Location1 => "Mt. Chimney",
	  :QuestDescription => "I love the Battle Frontier. I have a few questions to ask you. If you can answer them, I will give you something in return.",
	  :RewardString => "Scorbunny"
	}

	Quest45 = {
	  :ID => "45",
	  :Name => "Box Collector",
	  :QuestGiver => "Edman",
	  :Stage1 => "Collect all the boxes.",
	  :Location1 => "Difford Cave",
	  :QuestDescription => "Could you please collect all the boxes in Difford Cave for me? I am planning to leave soon.",
	  :RewardString => "$3,500"
	}
  
	Quest46 = {
	  :ID => "46",
	  :Name => "Legend Show and Tell",
	  :QuestGiver => "Gray",
	  :Stage1 => "Show Gray a Mewtwo.",
	  :Location1 => "Battle Frontier",
	  :QuestDescription => "Show me a Mewtwo so my Ditto can transform! I also want to see a Lugia and a Regigigas.",
	  :RewardString => "4 Exp. Candy L"
	}

	Quest47 = {
	  :ID => "47",
	  :Name => "Wailord Needs Help!",
	  :QuestGiver => "Marlon",
	  :Stage1 => "Find people around Lilycove.",
	  :Location1 => "Lilycove City",
	  :QuestDescription => "Those scoundrels from Team Aqua blocked Route 124 with a bunch of Wailmer! I managed to clear the way, but while I was doing so, one of the Wailmer evolved and was pushed onto the shore. I need someone to find people around town to help me push it back into the water.",
	  :RewardString => "Fossilized Drake"
	}
  
	Quest48 = {
	  :ID => "48",
	  :Name => "Zygarde Cell Hunting",
	  :QuestGiver => "Dexio",
	  :Stage1 => "Collect 100 Zygarde Cells.",
	  :Location1 => "Mauville City",
	  :QuestDescription => "Travel around the region and collect 100 Zygarde Cells. Meet us at the Fallarbor Ranger Guild.",
	  :RewardString => "Zygarde"
	}

	Quest49 = {
	  :ID => "49",
	  :Name => "Go to the Frontier Guild",
	  :QuestGiver => "Guild Member",
	  :Stage1 => "Go to the Ranger Guild.",
	  :Location1 => "Battle Frontier",
	  :QuestDescription => "The headmaster of the Ranger Guilds has something to tell you. Why not go to the Battle Frontier Ranger Guild and see what he wants?",
	  :RewardString => "None"
	}
  
	Quest50 = {
	  :ID => "50",
	  :Name => "Explore Auralis Port",
	  :QuestGiver => "Silas",
	  :Stage1 => "Explore the area.",
	  :Location1 => "Auralis Port",
	  :QuestDescription => "While I am fixing the machine that handles all the duties of this guild, why don't you explore Auralis Port and Littoral Peak? Maybe you could meet Madam Zenith while you're at it.",
	  :RewardString => "None"
	}

	Quest51 = {
	  :ID => "51",
	  :Name => "Explore the Second Mirage Isle",
	  :QuestGiver => "Silas",
	  :Stage1 => "Explore the area.",
	  :Location1 => "Auralis Port",
	  :QuestDescription => "While Silas is busy contacting other strong Trainers, go to the second Mirage Isle.",
	  :RewardString => "None"
	}
  
  Quest52 = {
    :ID => "52",
    :Name => "Mainland Bout",
    :QuestGiver => "Emily",
    :Stage1 => "Find Emily",
    :Location1 => "Littoral Peak",
    :QuestDescription => "I am a native of the Mirage Isles. I want to fight someone from the mainland of Hoenn. Meet me on Littoral Peak if your interested in losing!",
    :RewardString => "Ability Shield"
  }
  
  Quest53 = {
    :ID => "53",
    :Name => "Head back Auralis Port",
    :QuestGiver => "Scion",
    :Stage1 => "Ranger Guild",
    :Location1 => "Goran Cave",
    :QuestDescription => "I will continue searching for Team Neo Cipher. You go back to Auralis Port and do what you must in the meantime.",
    :RewardString => "None"
  }
  
  Quest54 = {
    :ID => "54",
    :Name => "Check Madam Zennith",
    :QuestGiver => "Silas",
    :Stage1 => "Ranger Guild",
    :Location1 => "Ranger Guild",
    :QuestDescription => "Madam Zennith asked specifically for you. Could you go see what she needs?",
    :RewardString => "None"
  }
  
  Quest55 = {
    :ID => "55",
    :Name => "Go to Isle 3",
    :QuestGiver => "Zennith",
    :Stage1 => "Go to Isle 3",
    :Location1 => "Zennith Home",
    :QuestDescription => "Isle 3 is known for a rare, mineral-rich clay found deep within its swamp. Go to Isle 3 and pick some up for me. It should be at a market or shop.",
    :RewardString => "None"
  }
  
  Quest56 = {
    :ID => "56",
    :Name => "Bridge Trouble",
    :QuestGiver => "Wally",
    :Stage1 => "Find Help",
    :Location1 => "Bond Bridge",
    :QuestDescription => "Find some help so we can fix this bridge, so others can come across it.",
    :RewardString => "Dawn Stone & Dusk Stone"
  }
  
	Quest57 = {
	  :ID => "57",
	  :Name => "Steven's Trouble",
	  :QuestGiver => "Mr. Stone",
	  :Stage1 => "Go to Devon Corp.",
	  :Location1 => "Devon Corp.",
	  :QuestDescription => "Go to Devon Corp. President Stone urgently needs your assistance with something...",
	  :RewardString => "Mirage Ticket"
	}

	Quest58 = {
	  :ID => "58",
	  :Name => "Head to Auralis Port",
	  :QuestGiver => "Mr. Stone",
	  :Stage1 => "Go to Auralis Port.",
	  :Location1 => "Battle Frontier",
	  :QuestDescription => "Meet Steven at the Information Center in Auralis Port, located in the Mirage Isles. Go to the ferry at the Battle Frontier to set sail there.",
	  :RewardString => "Nothing"
	}
  
	Quest59 = {
	  :ID => "59",
	  :Name => "Fortree Meeting",
	  :QuestGiver => "Winona",
	  :Stage1 => "Attend the meeting in Fortree City.",
	  :Location1 => "Fortree City",
	  :QuestDescription => "The Gym Leaders and I are gathering at a house in Fortree City to discuss the problems affecting our region. You now have six Gym Badges, so I think it would be a good idea for you to join us. I will be waiting outside the house...",
	  :RewardString => "Nothing"
	}

	Quest60 = {
	  :ID => "60",
	  :Name => "Steven's Home",
	  :QuestGiver => "Steven",
	  :Stage1 => "Meet Steven at his home.",
	  :Location1 => "Mossdeep City",
	  :QuestDescription => "Steven has something to tell you. Go meet him at his home. It may be urgent!",
	  :RewardString => "Nothing"
	}
  
	Quest61 = {
	  :ID => "61",
	  :Name => "Devon Corp. Raided",
	  :QuestGiver => "Steven",
	  :Stage1 => "Meet Steven at Devon Corp.",
	  :Location1 => "Rustboro City",
	  :QuestDescription => "Team Sky has broken into Devon Corporation and is causing chaos. I'm heading there now to stop them. Meet me in Rustboro City!",
	  :RewardString => "Nothing"
	}

	Quest62 = {
	  :ID => "62",
	  :Name => "Meteorite Shard",
	  :QuestGiver => "Mr. Stone",
	  :Stage1 => "Head to Granite Cave.",
	  :Location1 => "Rustboro City",
	  :QuestDescription => "Head to Granite Cave and find a Meteorite Shard. Steven will return to the Mossdeep Space Center. Hurry, we don't have much time!",
	  :RewardString => "Nothing"
	}
  
	Quest63 = {
	  :ID => "63",
	  :Name => "Head Back to the Space Center",
	  :QuestGiver => "???",
	  :Stage1 => "Head to the Space Center.",
	  :Location1 => "Mossdeep City",
	  :QuestDescription => "Go back to the Space Center and tell Steven about your findings.",
	  :RewardString => "Nothing"
	}

	Quest64 = {
	  :ID => "64",
	  :Name => "Battle the Seventh Gym",
	  :QuestGiver => "Steven",
	  :Stage1 => "Head to the Gym.",
	  :Location1 => "Mossdeep City",
	  :QuestDescription => "You need the ability to Dive. Go battle Tate and Liza, the Gym Leaders of Mossdeep City, before stopping Team Aqua!",
	  :RewardString => "Nothing"
	}
  
	Quest65 = {
	  :ID => "65",
	  :Name => "Lost Parcel",
	  :QuestGiver => "Tim",
	  :Stage1 => "Find the lost parcel.",
	  :Location1 => "Route 110",
	  :QuestDescription => "I dropped a parcel in the grass below while cycling around. A bike isn't great for riding through grass, so could you look for it for me?",
	  :RewardString => "4 Soda Pops"
	}

end
