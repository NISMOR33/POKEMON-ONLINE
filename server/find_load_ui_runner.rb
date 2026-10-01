# frozen_string_literal: true

require "zlib"

out = []

out << "--- SEARCHING PLUGINS ---"
Dir.glob("Plugins/**/*.rb").each do |file|
  content = File.read(file, encoding: "UTF-8") rescue ""
  if content.match?(/PokemonLoad|Scene_Load|cmd_continue|pbStartLoadScreen|pbStartScene/i)
    out << "Match in Plugin: #{file}"
    content.each_line.with_index(1) do |line, lnum|
      if line.match?(/class|def|commands|pbStart/i)
        out << "  Line #{lnum}: #{line.strip}"
      end
    end
  end
end

out << "\n--- SEARCHING SCRIPTS.RXDATA ---"
scripts = File.open("Data/Scripts.rxdata", "rb") { |f| Marshal.load(f) } rescue []

scripts.each_with_index do |script, idx|
  id, name, compress_code = script
  code = Zlib::Inflate.inflate(compress_code).force_encoding("UTF-8") rescue ""
  
  if code.match?(/class PokemonLoad|def pbStartLoadScreen|class Scene_Load|cmd_continue/i)
    out << "Match in Script ##{idx} (#{name}):"
    code.each_line.with_index(1) do |line, lnum|
      if line.match?(/class PokemonLoad|def pbStartLoadScreen|def pbStartScene|commands\s*=|commands\[|commands\.push/i)
        out << "  Line #{lnum}: #{line.strip}"
      end
    end
  end
end

File.write("server/load_ui_results.txt", out.join("\n"))
puts "Saved results to server/load_ui_results.txt"

