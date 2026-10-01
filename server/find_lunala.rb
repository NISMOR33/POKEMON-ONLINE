# frozen_string_literal: true

out = []

out << "=== SEARCHING FOR LUNALA IN PBS FILES ==="
Dir.glob("PBS/*.txt").each do |file|
  content = File.read(file, encoding: "UTF-8") rescue ""
  if content.match?(/LUNALA/i)
    out << "Match in PBS file: #{file}"
    content.each_line.with_index(1) do |line, lnum|
      if line.match?(/LUNALA|Cosmog|Cosmoem|Moon|Nuit|Form|Level/i)
        out << "  L#{lnum}: #{line.strip}"
      end
    end
  end
end

out << "\n=== SEARCHING FOR LUNALA IN PLUGINS & SCRIPTS ==="
Dir.glob("{Plugins,Data}/**/*").each do |file|
  next if File.directory?(file) || !file.match?(/\.(rb|txt|json)$/i)
  content = File.read(file, encoding: "UTF-8") rescue ""
  if content.match?(/LUNALA/i)
    out << "Match in: #{file}"
    content.each_line.with_index(1) do |line, lnum|
      if line.match?(/LUNALA|Cosmoem|FormTrader|MQS|Quest|Gift/i)
        out << "  L#{lnum}: #{line.strip}"
      end
    end
  end
end

File.write("server/lunala_info.txt", out.join("\n"))
puts "Written Lunala info to server/lunala_info.txt"

