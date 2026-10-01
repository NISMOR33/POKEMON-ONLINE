# frozen_string_literal: true

require "zlib"

scripts = File.open("Data/Scripts.rxdata", "rb") { |f| Marshal.load(f) }

scripts.each_with_index do |script, idx|
  id, name, compress_code = script
  code = Zlib::Inflate.inflate(compress_code).force_encoding("UTF-8") rescue ""
  
  if code.include?("PokemonLoad") || code.include?("cmd_continue") || name.include?("Load")
    puts "================================================="
    puts "Script ##{idx}: #{name}"
    puts "================================================="
    puts code
  end
end

