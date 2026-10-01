# frozen_string_literal: true

out = []

out << "=== 1. MOVIES / VIDEO CUTSCENES ==="
Dir.glob("{Audio/Movies,Movies,Audio/Videos,Videos}/**/*").each do |f|
  out << f if File.file?(f)
end

out << "\n=== 2. TITLE SCREEN / INTRO ANIMATION PLUGINS ==="
Dir.glob("Plugins/**/*Intro*/**/*").each do |f|
  out << f if File.file?(f)
end

out << "\n=== 3. AUDIO / BGM / INTRO SOUNDS ==="
Dir.glob("Audio/{BGM,ME,SE,BGS}/*{intro|title|emerald}*").each do |f|
  out << f if File.file?(f)
end

File.write("server/cutscenes_info.txt", out.join("\n"))
puts "Found info in cutscenes_info.txt"

