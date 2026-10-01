# frozen_string_literal: true

out = []

out << "=== INTRO PICTURES ==="
Dir.glob("Graphics/Pictures/*{intro,prof,Oak,Birch,boy,girl,bg}*i").each do |f|
  out << f
end

out << "\n=== TRAINER / PROFESSOR SPRITES ==="
Dir.glob("Graphics/Trainers/*{PROF,BIRCH,OAK,BOY,GIRL,HERO}*i").each do |f|
  out << f
end

out << "\n=== ALL PROFESSOR / INTRO IMAGES IN GRAPHICS ==="
Dir.glob("Graphics/**/*{intro,prof,Birch,Oak}*").each do |f|
  out << f if File.file?(f)
end

File.write("server/intro_graphics.txt", out.join("\n"))
puts "Written output to server/intro_graphics.txt"

