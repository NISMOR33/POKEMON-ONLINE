# frozen_string_literal: true

out = []

out << "=== 1. SEARCHING COSMOG IN ENCOUNTERS ==="
File.open("PBS/encounters.txt", "r:utf-8") do |f|
  current_map = ""
  f.each_line do |line|
    if line.start_with?("#") || line.match?(/^\d+/)
      current_map = line.strip
    end
    if line.match?(/COSMOG/i)
      out << "Map: #{current_map} -> #{line.strip}"
    end
  end
end rescue nil

out << "\n=== 2. SEARCHING COSMOG IN ROUTE GUIDE ==="
File.open("docs/GUIDE_RENCONTRES_ROUTES_POKEMON.md", "r:utf-8") do |f|
  f.each_line.with_index(1) do |line, lnum|
    if line.match?(/COSMOG/i)
      out << "L#{lnum}: #{line.strip}"
    end
  end
end rescue nil

out << "\n=== 3. SEARCHING COSMOG IN SCRIPTS / QUESTS ==="
Dir.glob("Plugins/**/*.rb").each do |file|
  content = File.read(file, encoding: "UTF-8") rescue ""
  if content.match?(/COSMOG/i)
    out << "File: #{file}"
    content.each_line.with_index(1) do |line, lnum|
      if line.match?(/COSMOG|Cosmog/i)
        out << "  L#{lnum}: #{line.strip}"
      end
    end
  end
end

File.write("server/cosmog_location.txt", out.join("\n"))
puts "Saved to server/cosmog_location.txt"

