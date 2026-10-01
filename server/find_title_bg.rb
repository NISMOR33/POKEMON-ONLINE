# frozen_string_literal: true

out = []

out << "=== GRAPHICS/TITLES ==="
Dir.glob("Graphics/Titles/**/*").each do |f|
  out << f if File.file?(f)
end

out << "\n=== MODULAR TITLE SCREEN IMAGES ==="
Dir.glob("Plugins/Modular Title Screen*/**/*").each do |f|
  out << f if File.file?(f) && f.match?(/\.(png|jpg|bmp)$/i)
end

out << "\n=== GRAPHICS/PICTURES TITLE ==="
Dir.glob("Graphics/Pictures/*{title,bg,start,load}*").each do |f|
  out << f if File.file?(f)
end

File.write("server/title_bg_info.txt", out.join("\n"))
puts "Written output to server/title_bg_info.txt"

