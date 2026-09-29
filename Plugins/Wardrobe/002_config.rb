#==============================================================================#
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#
#==============================================================================#
#                         DarrylBD99's Wardrobe Script                         #
#                                     v1.0                                     #
#                            Resource by DarrylBD99                            #
#                           Backgrounds by StarWolff                           #
#==============================================================================#
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#
#==============================================================================#
#               Implements a wardrobe that can makes events that               #
#                      changes the player's outfit easier                      #
#==============================================================================#
#                 call the script pbUnlockOutfit(outfit_index)                 #
#               in the event to unlock outfits into the wardrobe               #
#------------------------------------------------------------------------------#
#          call the script pbWardrobe in the event to access wardrobe          #
#==============================================================================#
#                                   WARNING                                    #
#------------------------------------------------------------------------------#
#        please make sure you make a new save before using this script         #
#==============================================================================#


#==============================================================================#
#                                   SETTINGS                                   #
#==============================================================================#
module WardrobeConfig
	# Determine the type of wardrobe you want (DEFAULT: 0):
    # 0 - A scroll selection like Yes or No choices
    # 1 - Wardrobe with custom GUI
    TYPE = 1

    # Outfit Names in order of number index (must keep/consist of base outfit)
    OUTFITS = [
        "Starter Outfit", 
		"Emerald Outfit",
		"Magma Outfit",
		"Ruby Outfit",
		"Aqua Outfit",
		"Truck Outfit not using",
		"FrLg Red Outfit",
		"Gold Outfit",
		"Rse Red Outfit",
		"Rse Magma Outfit",
		"Ranger Outfit",
		"Platinum Outfit",
		"Rse Aqua Outfit",
		"Ninja Outfit Black",
		# female outfits start at 14
		"Female Outfit: Yellow",
		"Female Outfit: Blue",
		"Female Outfit: Black",
		"Female Outfit: RS",
		#Male Outfits start again at 18
		"Wes Outfit",
		"Alain Outfit",
		"Hilbert Outfit",
		"Calem Outfit",
		"Rocket Outfit M",
		"Elio Outfit",
		"Unused", #Takes number 24 which is used as Rayqyaza
		"Order Destroyed",
		"FrLg Brendan",
		# female outfits start at 27 Again
		"Leaf Outfit",
		"Lyra Outfit",
		"Crystal Outfit",
		"Emerald Outfit Upd",
		"RS Outfit Upd",
		"XY Serena Outfit",
		"Cynthia Outfit",
		"Platinum Dawn Outfit",
		"BW Hilda Outfit",
		"BW2 Rosa Outfit",
		"N Outfit",
		"Unused", #Takes 38 which is Souring Mega Latios
		"Space Suit"
	]

	# Change background style:
    # 0 - Basic Background
    # 1 - Basic Background (Pokeball Silhouette)
    # 2 - Basic Background (Pikachu Silhouette)
    # 3 - Elite Trainer Background
    # 4 - Sword and Shield Background
    BG_TYPE = 0

    # Change how outfits are sorted (DEFAULT: 0):
    # 0 - Sort by Index
    # 1 - Sort by Obtained History
    OUTFIT_SORT = 1
end
#==============================================================================#
