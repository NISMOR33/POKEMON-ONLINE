# frozen_string_literal: true

require "zlib"

scripts = File.open("Data/Scripts.rxdata", "rb") { |f| Marshal.load(f) } rescue []

out = []
scripts.each_with_index do |script, idx|
  id, name, compress_code = script
  code = Zlib::Inflate.inflate(compress_code).force_encoding("UTF-8") rescue ""
  
  if name.match?(/Load|Title|Intro|Start/i) || code.match?(/PokemonLoadScreen|PokemonLoad_Scene|cmd_continue/i)
    out << "#==============================================================================="
    out << "# Script ##{idx}: #{name}"
    out << "#==============================================================================="
    out << code
    out << "\n\n"
  end
end

File.write("server/load_scripts_dump.txt", out.join("\n"))
puts "Wrote #{scripts.size} scripts analysis to server/load_scripts_dump.txt"

