module GameData
  class << self
    alias _secretbase_load_all load_all
    def load_all
      _secretbase_load_all
      SecretBase.load
      SecretBaseDecoration.load
    end
  end
end

module Compiler
  module_function
  
  #=============================================================================
  # Compile Secret Bases data
  #=============================================================================
    def compile_secret_bases(*paths)
    compile_PBS_file_generic(GameData::SecretBase, *paths) do |final_validate, hash|
      (final_validate) ? validate_all_compiled_secret_bases : validate_compiled_secret_base(hash)
    end
  end

  def validate_compiled_secret_base(hash)
    if hash[:map_template].nil?
      raise _INTL("The entry 'MapTemplate' is required in secret_bases.txt section {1}.\n{2}", data_hash[:id],FileLineData.linereport)
    end
    if hash[:location].nil?
      raise _INTL("The entry 'Location' is required in secret_bases.txt section {1}.\n{2}", data_hash[:id],FileLineData.linereport)
    end
  end

  # no specific validation required
  def validate_all_compiled_secret_bases
  end
  
  #=============================================================================
  # Compile Secret Base Decorations data
  #=============================================================================
  def compile_secret_base_decorations(*paths)
    compile_PBS_file_generic(GameData::SecretBaseDecoration, *paths) do |final_validate, hash|
      (final_validate) ? validate_all_compiled_secret_base_decorations : validate_compiled_secret_base_decoration(hash)
    end
  end
  
  # no specific validation required
  def validate_compiled_secret_base_decoration(hash)
  end

  def validate_all_compiled_secret_base_decorations
    # Get secret base decoration names/descriptions for translating
    decoration_names = []
    decoration_descriptions = []
    GameData::SecretBaseDecoration.each do |decoration|
      decoration_names.push(decoration.real_name)
      decoration_descriptions.push(decoration.real_description)
    end
    MessageTypes.setMessagesAsHash(MessageTypes::SECRET_BASE_DECORATIONS_NAMES, decoration_names)
    MessageTypes.setMessagesAsHash(MessageTypes::SECRET_BASE_DECORATION_DESCRIPTIONS, decoration_descriptions)
  end
  
  class << self
    alias _secretbase_compile_pbs_files compile_pbs_files
    def compile_pbs_files
      _secretbase_compile_pbs_files
      text_files = get_all_pbs_files_to_compile
      compile_secret_bases(*text_files[:SecretBase][1])
      compile_secret_base_decorations(*text_files[:SecretBaseDecoration][1])
    end
  end
end