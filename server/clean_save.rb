# frozen_string_literal: true

require "fileutils"

puts "================================================="
puts "🧹 Nettoyage de la SAUVEGARDE DU JOUEUR (Save.rxdata)..."
puts "================================================="

search_dirs = [
  File.join(ENV["APPDATA"] || "", "POKEMON-ONLINE"),
  File.join(ENV["APPDATA"] || "", "Pokemon Eternal Emerald"),
  File.join(ENV["APPDATA"] || "", "Pokemon Eternal Emerald Online"),
  File.join(ENV["APPDATA"] || "", "Pokemon Essentials"),
  File.join(ENV["USERPROFILE"] || "", "Saved Games", "POKEMON-ONLINE"),
  File.join(ENV["USERPROFILE"] || "", "Saved Games", "Pokemon Eternal Emerald"),
]

deleted_count = 0

search_dirs.each do |dir|
  next unless File.directory?(dir)
  
  Dir.glob("#{dir}/**/Save*.{rxdata,dat}").each do |file|
    begin
      File.delete(file)
      puts "✅ Sauvegarde joueur supprimée : #{file}"
      deleted_count += 1
    rescue => e
    end
  end
end

# Suppression de la sauvegarde joueur dans le dossier courant si présente
root_save = File.join(Dir.pwd, "Save.rxdata")
if File.exist?(root_save)
  File.delete(root_save) rescue nil
  puts "✅ Sauvegarde joueur supprimée : #{root_save}"
  deleted_count += 1
end

# Suppression de la session invitée MMO si présente
guest_acc = File.join(Dir.pwd, "mmo_account_guest.dat")
if File.exist?(guest_acc)
  File.delete(guest_acc) rescue nil
  puts "✅ Session invitée supprimée : #{guest_acc}"
  deleted_count += 1
end

puts "================================================="
puts "✨ Terminé ! Total sauvegardes supprimées : #{deleted_count}"
puts "================================================="

