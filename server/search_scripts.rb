# frozen_string_literal: true

require "zlib"

scripts = File.open("Data/Scripts.rxdata", "rb") { |f| Marshal.load(f) }

scripts.each_with_index do |script, idx|
  id, name, compress_code = script
  code = Zlib::Inflate.inflate(compress_code).force_encoding("UTF-8") rescue ""
  
  if name.match?(/Load|Save|Title|Main/i) || code.match?(/cmd_continue|PokemonLoad|SaveData/i)
    puts "Script ##{idx}: #{name}"
    code.each_line.with_index(1) do |line, line_num|
      if line.match?(/cmd_continue|cmd_newgame|cmd_delete|SaveData\.delete|pbStartLoadScreen|commands\.push|commands\[/i)
        puts "  Line #{line_num}: #{line.strip}"
      end
    end
  end
end

