# frozen_string_literal: true

require "zlib"

out = []

out << "================================================="
out << "1. CHECKING PLUGINS FOLDER"
out << "================================================="

Dir.glob("Plugins/**/*.rb").each do |file|
  content = File.read(file, encoding: "UTF-8") rescue ""
  if content.include?("PokemonLoadScreen") || content.include?("pbStartLoadScreen") || content.include?("Save Status")
    out << "\n[PLUGIN FILE] #{file}"
    content.each_line.with_index(1) do |line, lnum|
      if line.match?(/def pbStartLoadScreen|class PokemonLoadScreen|commands\[|cmd_continue|cmd_options/i)
        out << "  L#{lnum}: #{line.strip}"
      end
    end
  end
end

out << "\n================================================="
out << "2. CHECKING SCRIPTS.RXDATA"
out << "================================================="

scripts = File.open("Data/Scripts.rxdata", "rb") { |f| Marshal.load(f) } rescue []

scripts.each_with_index do |script, idx|
  id, name, compress_code = script
  code = Zlib::Inflate.inflate(compress_code).force_encoding("UTF-8") rescue ""

  if code.include?("PokemonLoadScreen") || code.include?("pbStartLoadScreen") || name.include?("Load")
    out << "\n[SCRIPT ##{idx}] #{name}"
    code.each_line.with_index(1) do |line, lnum|
      if line.match?(/def pbStartLoadScreen|class PokemonLoadScreen|commands\[|cmd_continue|cmd_options/i)
        out << "  L#{lnum}: #{line.strip}"
      end
    end
  end
end

File.write("server/exact_load_file.txt", out.join("\n"))
puts "Extracted exact locations to server/exact_load_file.txt"

