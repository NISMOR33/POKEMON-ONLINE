# frozen_string_literal: true

require "zlib"

scripts = File.open("Data/Scripts.rxdata", "rb") { |f| Marshal.load(f) }

out = []
scripts.each_with_index do |script, idx|
  id, name, compress_code = script
  code = Zlib::Inflate.inflate(compress_code).force_encoding("UTF-8") rescue ""
  
  if name.match?(/Load|Save/i) || code.include?("class PokemonLoad") || code.include?("def pbStartLoadScreen")
    out << "================================================="
    out << "Script ##{idx}: #{name}"
    out << "================================================="
    out << code
  end
end

File.write("server/extracted_load.txt", out.join("\n"))
puts "Extracted #{out.size} scripts to server/extracted_load.txt"

