# frozen_string_literal: true

require "zlib"

scripts = File.open("Data/Scripts.rxdata", "rb") { |f| Marshal.load(f) } rescue []

scripts.each_with_index do |script, idx|
  id, name, compress_code = script
  code = Zlib::Inflate.inflate(compress_code).force_encoding("UTF-8") rescue ""
  
  if code.include?("class PokemonLoad_Scene") || code.include?("class PokemonLoadScreen") || name.include?("UI_Load")
    puts "Writing script ##{idx} (#{name}) to server/load_scene_#{idx}.rb"
    File.write("server/load_scene_#{idx}.rb", code)
  end
end

