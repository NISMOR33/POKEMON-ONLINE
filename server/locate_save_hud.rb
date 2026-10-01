# frozen_string_literal: true

out = []
out << "=== SEARCHING ALL .RB FILES IN WORKSPACE FOR SAVE STATUS HUD ==="

Dir.glob("**/*.rb").each do |file|
  next if file.start_with?("server/")
  content = File.read(file, encoding: "UTF-8") rescue ""

  if content.match?(/Save Status HUD|SaveStatusHUD|Save_Status|PokemonLoad|cmd_continue|Continuer/i)
    out << "\nFound in: #{file}"
    content.each_line.with_index(1) do |line, lnum|
      if line.match?(/Save Status|class |def pbStartLoadScreen|commands\[|cmd_continue|cmd_options|cmd_debug|cmd_quit|Continuer/i)
        out << "  Line #{lnum}: #{line.strip}"
      end
    end
  end
end

File.write("server/save_hud_location.txt", out.join("\n"))
puts "Written output to server/save_hud_location.txt"

