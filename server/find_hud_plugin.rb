# frozen_string_literal: true

Dir.glob("Plugins/**/*.rb").each do |file|
  content = File.read(file, encoding: "UTF-8") rescue ""
  if content.match?(/Save Status HUD|PokemonLoadScreen|pbStartLoadScreen|cmd_continue|Options.*Debug/i)
    puts "Found match in plugin: #{file}"
    content.each_line.with_index(1) do |line, lnum|
      if line.match?(/class|def|commands|pbStartLoadScreen|cmd_/i)
        puts "  Line #{lnum}: #{line.strip}"
      end
    end
  end
end

