# frozen_string_literal: true

out = []

if File.exist?("PBS/encounters.txt")
  lines = File.readlines("PBS/encounters.txt", encoding: "UTF-8")
  current_section = ""
  lines.each do |line|
    if line.start_with?("#") || line.match?(/^\d+/)
      current_section = line.strip
    end
    if line.include?("COSMOG")
      out << "ENCOUNTER MAP: #{current_section} -> #{line.strip}"
    end
  end
end

if File.exist?("docs/GUIDE_RENCONTRES_ROUTES_POKEMON.md")
  lines = File.readlines("docs/GUIDE_RENCONTRES_ROUTES_POKEMON.md", encoding: "UTF-8")
  lines.each_with_index do |line, idx|
    if line.match?(/Cosmog|COSMOG/i)
      out << "GUIDE L#{idx + 1}: #{line.strip}"
    end
  end
end

File.write("server/cosmog_result.txt", out.join("\n"))
puts "Found #{out.size} entries for Cosmog."

