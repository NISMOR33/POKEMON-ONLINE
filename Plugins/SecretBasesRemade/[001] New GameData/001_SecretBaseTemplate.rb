module GameData
  class SecretBaseTemplate
    attr_reader :id
    attr_reader :map_id
    attr_reader :type
    attr_reader :door_location
    attr_reader :pc_location
    attr_reader :owner_location
    attr_reader :preview_steps
    attr_reader :map_borders

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id              = hash[:id]
      @map_id          = hash[:map_id]
      @type            = hash[:type]
      @door_location   = hash[:door_location]
      @pc_location     = hash[:pc_location]
      @owner_location  = hash[:owner_location]
      @preview_steps   = hash[:preview_steps] || 2
      @map_borders     = hash[:map_borders]
    end
  end
end
#Fin
GameData::SecretBaseTemplate.register({
  :id             => :CaveRed1,
  :map_id         => 290,
  :type           => :cave,
  :door_location  => [13,14],
  :pc_location    => [9,8],
  :owner_location => [15,10],
  :map_borders    => [8,6,18,14]
})
#Fin
GameData::SecretBaseTemplate.register({
  :id             => :CaveRed2,
  :map_id         => 291,
  :type           => :cave,
  :door_location  => [11,21],
  :pc_location    => [13,14],
  :owner_location => [11,7],
  :map_borders    => [8,6,14,21]
})
#Fin
GameData::SecretBaseTemplate.register({
  :id             => :CaveRed3,
  :map_id         => 292,
  :type           => :cave,
  :door_location  => [11,13],
  :pc_location    => [9,8],
  :owner_location => [20,7],
  :map_borders    => [8,6,22,13]
})
#Fin
GameData::SecretBaseTemplate.register({
  :id             => :CaveRed4,
  :map_id         => 293,
  :type           => :cave,
  :door_location  => [10,19],
  :pc_location    => [10,8],
  :owner_location => [13,14],
  :map_borders    => [8,6,16,20]
})
#Fin
GameData::SecretBaseTemplate.register({
  :id             => :CaveRed5,
  :map_id         => 876,
  :type           => :cave,
  :door_location  => [11,13],
  :pc_location    => [9,8],
  :owner_location => [20,7],
  :map_borders    => [8,6,22,13]
})
#Fin
GameData::SecretBaseTemplate.register({
  :id             => :CaveBrown1,
  :map_id         => 299,
  :type           => :cave,
  :door_location  => [13,14],
  :pc_location    => [10,8],
  :owner_location => [13,8],
  :map_borders    => [8,6,18,14]
})
#Fin
GameData::SecretBaseTemplate.register({
  :id             => :CaveBrown2,
  :map_id         => 300,
  :type           => :cave,
  :door_location  => [9,14],
  :pc_location    => [17,7],
  :owner_location => [19,8],
  :map_borders    => [8,6,21,14]
})
#Fin
GameData::SecretBaseTemplate.register({
  :id             => :CaveBrown3,
  :map_id         => 301,
  :type           => :cave,
  :door_location  => [19,16],
  :pc_location    => [21,9],
  :owner_location => [9,13],
  :map_borders    => [8,6,22,16]
})
#Fin
GameData::SecretBaseTemplate.register({
  :id             => :CaveBrown4,
  :map_id         => 302,
  :type           => :cave,
  :door_location  => [10,15],
  :pc_location    => [9,7],
  :owner_location => [10,7],
  :map_borders    => [8,6,21,17]
})
#Fin
GameData::SecretBaseTemplate.register({
  :id             => :CaveBlue1,
  :map_id         => 294,
  :type           => :cave,
  :door_location  => [13,14],
  :pc_location    => [9,8],
  :owner_location => [12,8],
  :map_borders    => [8,6,18,14]
})

GameData::SecretBaseTemplate.register({
  :id             => :CaveBlue2,
  :map_id         => 296,
  :type           => :cave,
  :door_location  => [15,12],
  :pc_location    => [9,7],
  :owner_location => [10,7],
  :map_borders    => [8,6,22,12]
})
#Fin
GameData::SecretBaseTemplate.register({
  :id             => :CaveBlue3,
  :map_id         => 297,
  :type           => :cave,
  :door_location  => [12,22],
  :pc_location    => [11,20],
  :owner_location => [13,7],
  :map_borders    => [8,6,17,22]
})
#Fin
GameData::SecretBaseTemplate.register({
  :id             => :CaveBlue4,
  :map_id         => 298,
  :type           => :cave,
  :door_location  => [12,22],
  :pc_location    => [11,19],
  :owner_location => [13,19],
  :map_borders    => [8,6,16,22]
})
#Fin
GameData::SecretBaseTemplate.register({
  :id             => :CaveYellow1,
  :map_id         => 303,
  :type           => :cave,
  :door_location  => [13,14],
  :pc_location    => [17,8],
  :owner_location => [11,7],
  :map_borders    => [8,6,18,14]
})
#Fin
GameData::SecretBaseTemplate.register({
  :id             => :CaveYellow2,
  :map_id         => 304,
  :type           => :cave,
  :door_location  => [20,14],
  :pc_location    => [16,12],
  :owner_location => [9,7],
  :map_borders    => [8,6,21,14]
})
#Fin
GameData::SecretBaseTemplate.register({
  :id             => :CaveYellow3,
  :map_id         => 305,
  :type           => :cave,
  :door_location  => [13,16],
  :pc_location    => [11,11],
  :owner_location => [15,11],
  :map_borders    => [8,6,19,16]
})
#Fin
GameData::SecretBaseTemplate.register({
  :id             => :CaveYellow4,
  :map_id         => 306,
  :type           => :cave,
  :door_location  => [14,19],
  :pc_location    => [13,14],
  :owner_location => [17,14],
  :map_borders    => [8,6,20,19]
})
#Fin
GameData::SecretBaseTemplate.register({
  :id             => :Tree1,
  :map_id         => 312,
  :type           => :vines,
  :door_location  => [5,8],
  :pc_location    => [2,2],
  :owner_location => [5,1],
  :map_borders    => [0,0,10,8]
})

GameData::SecretBaseTemplate.register({
  :id             => :Tree2,
  :map_id         => 338,
  :type           => :vines,
  :door_location  => [3,15],
  :pc_location    => [5,5],
  :owner_location => [3,1],
  :map_borders    => [0,0,6,15]
})
#Fin
GameData::SecretBaseTemplate.register({
  :id             => :Tree3,
  :map_id         => 339,
  :type           => :vines,
  :door_location  => [8,7],
  :pc_location    => [15,2],
  :owner_location => [1,2],
  :map_borders    => [0,0,16,7]
})

#Fin
GameData::SecretBaseTemplate.register({
  :id             => :Tree4,
  :map_id         => 340,
  :type           => :vines,
  :door_location  => [7,13],
  :pc_location    => [4,9],
  :owner_location => [10,9],
  :map_borders    => [0,0,13,13]
})

GameData::SecretBaseTemplate.register({
  :id             => :Shrub1,
  :map_id         => 307,
  :type           => :shrub,
  :door_location  => [5,8],
  :pc_location    => [3,2],
  :owner_location => [5,2],
  :map_borders    => [0,0,10,8]
})

GameData::SecretBaseTemplate.register({
  :id             => :Shrub2,
  :map_id         => 308,
  :type           => :shrub,
  :door_location  => [7,6],
  :pc_location    => [1,1],
  :owner_location => [13,2],
  :map_borders    => [0,0,14,6]
})

GameData::SecretBaseTemplate.register({
  :id             => :Shrub3,
  :map_id         => 310,
  :type           => :shrub,
  :door_location  => [6,10],
  :pc_location    => [7,7],
  :owner_location => [5,7],
  :map_borders    => [0,0,12,10]
})

GameData::SecretBaseTemplate.register({
  :id             => :Shrub4,
  :map_id         => 311,
  :type           => :shrub,
  :door_location  => [11,9],
  :pc_location    => [9,5],
  :owner_location => [9,7],
  :map_borders    => [0,0,13,10]
})