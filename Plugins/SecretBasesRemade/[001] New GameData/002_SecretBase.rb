module GameData
  class SecretBase
    attr_reader :id
    attr_reader :map_template
    attr_reader :location
    attr_reader :pbs_file_suffix

    DATA = {}
    DATA_FILENAME = "secret_bases.dat"
    PBS_BASE_FILENAME = "secret_bases"

    extend ClassMethodsSymbols
    include InstanceMethods

    SCHEMA = {
      "SectionName"  => [:id,           "m"],
      "MapTemplate"  => [:map_template, "e", :SecretBaseTemplate],
      "Location"     => [:location, "vuu"]
    }

    def initialize(hash)
      @id              = hash[:id]
      @map_template    = hash[:map_template]
      @location        = hash[:location]
      @pbs_file_suffix = hash[:pbs_file_suffix] || ""
    end
  end
end