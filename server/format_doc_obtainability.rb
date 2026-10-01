# frozen_string_literal: true

doc_path = "docs/POKEMON_OBTENABILITE_COMPLETE.md"

if File.exist?(doc_path)
  content = File.read(doc_path, encoding: "UTF-8")

  # Replace emojis with clean badges or formatted text
  content.gsub!("📜 ", "")
  content.gsub!("📊 ", "")
  content.gsub!("🚫 ", "")
  content.gsub!("❌ ", "[Indisponible] ")
  content.gsub!("🍃 ", "[Sauvage] ")
  content.gsub!("🔄 ", "[Évo/Quête] ")

  File.write(doc_path, content)
  puts "✅ docs/POKEMON_OBTENABILITE_COMPLETE.md nettoyé sans émoji !"
end

