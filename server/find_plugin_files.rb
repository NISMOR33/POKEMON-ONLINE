# frozen_string_literal: true

out = []
out << "=== ALL FILES IN PLUGINS ==="

Dir.glob("Plugins/**/*").each do |file|
  next if File.directory?(file)
  out << file
end

File.write("server/all_plugins_list.txt", out.join("\n"))
puts "Written #{out.size} files to server/all_plugins_list.txt"

