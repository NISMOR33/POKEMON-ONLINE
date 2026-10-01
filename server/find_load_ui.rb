# frozen_string_literal: true

require "zlib"

puts "--- SEARCHING PLUGINS ---"
Dir.glob("Plugins/**/*.rb").each do |file|
  content = File.read(file, encoding: "UTF-8") rescue ""
  if content.match?(/PokemonLoad|Scene_Load|cmd_continue|pbStartLoadScreen|pbStartScene/i)
    puts "Match in Plugin: #{file}"
    content.each_line.with_index(1) do |line, lnum|
      if line.match?(/class|def|commands|pbStart/i)
        puts "  Line #{lnum}: #{line.strip}"
      end
    end
  end
end

puts "\n--- SEARCHING SCRIPTS.RXDATA ---"
scripts = File.open("Data/Scripts.rxdata", "rb") { |f| Marshal.load(f) } rescue []

scripts.each_with_index do |script, idx|
  id, name, compress_code = script
  code = Zlib::Inflate.inflate(compress_code).force_encoding("UTF-8") rescue ""
  
  if code.match?(/class PokemonLoad|def pbStartLoadScreen|class Scene_Load|cmd_continue/i)
    puts "Match in Script ##{idx} (#{name}):"
    code.each_line.with_index(1) do |line, lnum|
      if line.match?(/class PokemonLoad|def pbStartLoadScreen|def pbStartScene|commands\s*=|commands\[|commands\.push/i)
        puts "  Line #{lnum}: #{line.strip}"
      end
    end
  end
end

