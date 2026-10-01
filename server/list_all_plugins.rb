# frozen_string_literal: true

out = []
Dir.glob("Plugins/**/*").each do |path|
  out << path if File.file?(path)
end

File.write("server/plugins_list.txt", out.join("\n"))
puts "Found #{out.size} files in Plugins/"

